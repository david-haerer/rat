const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/extensions/XTest.h");
    @cInclude("X11/extensions/XInput.h");
    @cInclude("X11/extensions/XInput2.h");
    @cInclude("string.h");
});
const io = @import("io.zig");

const Display = *c.Display;
const Window = c.Window;
const Error = error{ OpenDisplayFailed, XTestNotAvailable, GrabKeyboardFailed };

fn isXTestAvailable(display: Display) bool {
    var major_opcode: c_int = 0;
    var first_event: c_int = 0;
    var first_error: c_int = 0;
    return c.XQueryExtension(display, "XTEST", &major_opcode, &first_event, &first_error) != 0;
}

var nr_grabbed_device_ids: c_int = 0;
var grabbed_device_ids: [64]c_int = undefined;

fn reset_keyboard(display: Display) void {
    // send a key up event for any depressed keys to avoid infinite repeat.
    var keymap: [32]u8 = undefined;
    _ = c.XQueryKeymap(display, &keymap);
    for (0..256) |i| {
        if ((keymap[i / 8] >> @intCast(i % 8)) & 0x01 != 0) {
            _ = c.XTestFakeKeyEvent(display, @intCast(i), 0, c.CurrentTime);
        }
    }
    _ = c.XSync(display, c.False);
}

fn grab(display: Display, window: Window, device_id: c_int) Error!void {
    var mask: u8 = c.XI_KeyPressMask | c.XI_KeyReleaseMask;
    var event_mask: c.XIEventMask = c.XIEventMask{
        .deviceid = c.XIAllDevices,
        .mask_len = c.XIMaskLen(c.XI_LASTEVENT),
        .mask = @ptrCast(&mask),
    };
    const rc = c.XIGrabDevice(display, device_id, window, c.CurrentTime, c.None, c.GrabModeAsync, c.GrabModeAsync, c.False, &event_mask);
    if (rc != 0) {
        var n: c_int = undefined;
        const info: *c.XIDeviceInfo = c.XIQueryDevice(display, device_id, &n);
        std.log.err("Failed to grab keyboard {s}: {}", .{ info.name, rc });
        return Error.GrabKeyboardFailed;
    }
    _ = c.XSync(display, c.False);
}

fn grabKeyboard(display: Display, window: Window) Error!void {
    std.log.debug("grabKeyboard", .{});
    var n: c_int = undefined;
    if (nr_grabbed_device_ids != 0) return;

    const devices = c.XIQueryDevice(display, c.XIAllDevices, &n);

    for (0..@intCast(n)) |i| {
        if ((devices[i].use == c.XISlaveKeyboard) or (devices[i].use == c.XIFloatingSlave)) {
            if (c.strstr(devices[i].name, "XTEST") == null and devices[i].enabled != 0) {
                const id: c_int = devices[i].deviceid;
                try grab(display, window, id);
                grabbed_device_ids[@intCast(nr_grabbed_device_ids)] = id;
                nr_grabbed_device_ids += 1;
            }
        }
    }

    reset_keyboard(display);
    c.XIFreeDeviceInfo(devices);
    _ = c.XSync(display, c.False);
}

fn ungrabKeyboard(display: Display) void {
    if (nr_grabbed_device_ids == 0) return;

    for (0..@intCast(nr_grabbed_device_ids)) |i| {
        var n: c_int = undefined;
        const info: *c.XIDeviceInfo = c.XIQueryDevice(display, grabbed_device_ids[i], &n);
        if (n != 1) return;

        // NOTE: Attempting to ungrab a disabled xinput device
        // causes X to crash.
        //
        // (see https://gitlab.freedesktop.org/xorg/lib/libxi/-/issues/11).
        //
        // This generally shouldn't happen unless the user
        // switches virtual terminals while warpd is running. We
        // used to explicitly check for this and perform weird
        // hacks to mitigate against it, but now we only grab
        // the keyboard when the program is in one if its
        // active modes which reduces the likelihood
        // sufficiently to not to warrant the additional
        // complexity.

        if (info.enabled == 0) return;
        _ = c.XIUngrabDevice(display, grabbed_device_ids[i], c.CurrentTime);
    }

    nr_grabbed_device_ids = 0;
    _ = c.XSync(display, c.False);
}

pub const Server = struct {
    display: Display,
    root: Window,
    event: ?io.Event = null,

    pub fn connect() Error!Server {
        const display: Display = c.XOpenDisplay(null) orelse {
            std.log.err("Failed to open display!", .{});
            return Error.OpenDisplayFailed;
        };
        if (!isXTestAvailable(display)) {
            _ = c.XCloseDisplay(display);
            std.log.err("XTEST extension not available!", .{});
            return Error.XTestNotAvailable;
        }
        const root: Window = c.DefaultRootWindow(display);
        _ = c.XSelectInput(display, root, c.KeyPressMask | c.KeyReleaseMask);
        try grabKeyboard(display, root);
        return Server{ .display = display, .root = root };
    }

    pub fn disconnect(self: Server) void {
        ungrabKeyboard(self.display);
        _ = c.XCloseDisplay(self.display);
    }

    pub fn scroll(self: Server, button: io.Scroll) void {
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.True, c.CurrentTime);
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.False, c.CurrentTime);
    }

    pub fn move(self: Server, x: i32, y: i32) void {
        const delay = 0;
        _ = c.XTestFakeRelativeMotionEvent(self.display, x, y, delay);
    }

    pub fn nextEvent(self: *Server) bool {
        if (c.XPending(self.display) == 0) return false;
        var event: c.XEvent = undefined;
        _ = c.XNextEvent(self.display, &event);
        const index = 0;
        const key = c.XKeycodeToKeysym(self.display, @intCast(event.xkey.keycode), index);
        self.event = switch (event.type) {
            c.KeyPress => io.Event{ .key = key, .type = io.EventType.Press },
            c.KeyRelease => io.Event{ .key = key, .type = io.EventType.Release },
            else => null,
        };
        return true;
    }

    pub fn getPosition(self: *Server) void {
        var child: Window = undefined;
        var root_x: c_int = undefined;
        var root_y: c_int = undefined;
        var win_x: c_int = undefined;
        var win_y: c_int = undefined;
        var mask: c_uint = undefined;
        if (c.XQueryPointer(self.display, self.root, &self.root, &child, &root_x, &root_y, &win_x, &win_y, &mask) == 0) {
            std.log.warn("The pointer is on a different screen!", .{});
            return;
        }
        std.log.debug("x={}, y={}", .{ root_x, root_y });
    }

    pub fn pressButton(self: *Server, button: io.Button) void {
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.True, c.CurrentTime);
    }

    pub fn releaseButton(self: Server, button: io.Button) void {
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.False, c.CurrentTime);
    }
};
