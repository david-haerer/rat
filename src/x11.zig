const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cDefine("XK_LATIN1", "1");
    @cDefine("XK_MISCELLANY", "1");
    @cInclude("X11/keysymdef.h");
    @cInclude("X11/extensions/XTest.h");
});

pub const Error = error{ OpenDisplayFailed, XTestNotAvailable, GrabKeyboardFailed };
pub const Display = *c.Display;
const Window = c.Window;

fn openDisplay() Error!Display {
    return c.XOpenDisplay(null) orelse {
        std.log.err("Failed to open display!", .{});
        return Error.OpenDisplayFailed;
    };
}

fn checkXTestAvailable(display: Display) Error!void {
    var major_opcode: c_int = 0;
    var first_event: c_int = 0;
    var first_error: c_int = 0;
    if (c.XQueryExtension(display, "XTEST", &major_opcode, &first_event, &first_error) == 0) {
        std.log.err("XTEST extension not available!", .{});
        return Error.XTestNotAvailable;
    }
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

fn closeDisplay(display: Display) void {
    _ = c.XCloseDisplay(display);
}

fn ungrabKeyboard(display: Display) void {
    _ = c.XUngrabKeyboard(display, c.CurrentTime);
}

pub fn connect() Error!Display {
    const display: Display = try openDisplay();
    checkXTestAvailable(display) catch |err| {
        closeDisplay(display);
        return err;
    };
    const root_window: Window = c.DefaultRootWindow(display);
    _ = c.XSelectInput(display, root_window, c.KeyPressMask | c.KeyReleaseMask);
    var count: usize = 0;
    while (true) {
        grabKeyboard(display, root_window) catch {
            count += 1;
            std.time.sleep(10 * std.time.ns_per_ms);
            if (count == 100) {
                closeDisplay(display);
                return Error.GrabKeyboardFailed;
            }
            continue;
        };
        break;
    }
    return display;
}

pub fn disconnect(display: Display) void {
    ungrabKeyboard(display);
    closeDisplay(display);
}
