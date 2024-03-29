const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/extensions/XTest.h");
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

fn grabKeyboard(display: Display, window: Window) Error!void {
    const status = c.XGrabKeyboard(display, window, c.False, c.GrabModeAsync, c.GrabModeAsync, c.CurrentTime);
    switch (status) {
        c.AlreadyGrabbed => {
            std.log.warn("Keyboard already grabbed!", .{});
        },
        c.GrabNotViewable => {
            std.log.warn("Grab window is not viewable!", .{});
        },
        c.GrabFrozen => {
            std.log.warn("Keyboard is frozen by an active grab of another client!", .{});
        },
        c.GrabInvalidTime => {
            std.log.warn("Specified time is earlier than the last keyboard-grab time or later than the current X server time.", .{});
        },
        else => {
            return;
        },
    }
    return Error.GrabKeyboardFailed;
}

pub const Server = struct {
    display: Display,
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
        const root_window: Window = c.DefaultRootWindow(display);
        _ = c.XSelectInput(display, root_window, c.KeyPressMask | c.KeyReleaseMask);
        var count: usize = 0;
        while (true) {
            grabKeyboard(display, root_window) catch {
                count += 1;
                std.time.sleep(10 * std.time.ns_per_ms);
                if (count == 100) {
                    _ = c.XCloseDisplay(display);
                    return Error.GrabKeyboardFailed;
                }
                continue;
            };
            break;
        }
        return Server{ .display = display };
    }

    pub fn disconnect(self: Server) void {
        _ = c.XUngrabKeyboard(self.display, c.CurrentTime);
        _ = c.XCloseDisplay(self.display);
    }

    pub fn scrollVertical(self: Server, clicks: i32) void {
        const button_code: u8 = switch (clicks > 0) {
            true => 5,
            false => 4,
        };
        for (0..@abs(clicks)) |_| {
            _ = c.XTestFakeButtonEvent(self.display, button_code, c.True, c.CurrentTime);
            _ = c.XTestFakeButtonEvent(self.display, button_code, c.False, c.CurrentTime);
        }
    }

    pub fn scrollHorizontal(self: Server, clicks: i32) void {
        const shift = c.XKeysymToKeycode(self.display, io.KEY_SHIFT_LEFT);
        _ = c.XTestFakeKeyEvent(self.display, shift, c.True, c.CurrentTime);
        self.scrollVertical(clicks);
        _ = c.XTestFakeKeyEvent(self.display, shift, c.False, c.CurrentTime);
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

    pub fn pressButton(self: Server, button: io.Button) void {
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.True, c.CurrentTime);
    }

    pub fn releaseButton(self: Server, button: io.Button) void {
        _ = c.XTestFakeButtonEvent(self.display, @intFromEnum(button), c.False, c.CurrentTime);
    }
};
