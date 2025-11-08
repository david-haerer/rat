const std = @import("std");
const Time = @import("time.zig").Time;
const logging = @import("logging.zig");
// const Rat = @import("rat.zig").Rat;
const c = @cImport({
    @cInclude("libevdev/libevdev-uinput.h");
    @cInclude("libevdev/libevdev.h");
    @cInclude("stdlib.h");
});

pub const std_options = .{ .logFn = logging.logFn };

pub fn hello() void {
    std.log.info("", .{});
    std.log.info("  +----------------------------------+", .{});
    std.log.info("  | Rat 🐀: keyboard. driven. mouse. |", .{});
    std.log.info("  +----------------------------------+", .{});
    std.log.info("", .{});
}

const NAME = "Rat";

const Code = enum(u8) {
    MOD = 125,
    TAB = 15,
    H = 35,
    J = 36,
    K = 37,
    L = 38,
    SPACE = 57,
};

const Value = enum(c_int) { Free = 0, Down = 1, Hold = 2 };

const Mode = enum { Keyboard, Cursor };

const Event = c.input_event;

const Error = error{ExpectedArgument};

const DeviceError = error{ InitFailed, GrabFailed };

const Device = struct {
    file: std.fs.File,
    dev: *c.libevdev,

    pub fn init(path: [*c]const u8) DeviceError!Device {
        var rc: c_int = undefined;

        const file = std.fs.openFileAbsoluteZ(path, .{ .mode = .read_only }) catch {
            std.log.err("Error opening the device file!", .{});
            return DeviceError.InitFailed;
        };

        var maybe_dev: ?*c.libevdev = null;
        rc = c.libevdev_new_from_fd(file.handle, &maybe_dev);
        if (rc != 0) {
            std.log.err("Error fetching the device info!", .{});
            return DeviceError.InitFailed;
        }

        if (maybe_dev) |dev| return Device{ .file = file, .dev = dev };
        std.log.err("Device device not available!", .{});
        return DeviceError.InitFailed;
    }

    pub fn cleanup(self: Device) void {
        c.libevdev_free(self.dev);
        self.file.close();
    }

    pub fn grab(self: Device) DeviceError!void {
        const rc = c.libevdev_grab(self.dev, c.LIBEVDEV_GRAB);
        if (rc != 0) return DeviceError.GrabFailed;
    }

    pub fn ungrab(self: Device) void {
        _ = c.libevdev_grab(self.dev, c.LIBEVDEV_UNGRAB);
    }
};

const KeyboardError = error{ InitFailed, GrabFailed };

const Keyboard = struct {
    device: Device,
    uidev: *c.libevdev_uinput,

    pub fn init(path: [*c]const u8) KeyboardError!Keyboard {
        const device = Device.init(path) catch {
            std.log.err("Error creating the device!", .{});
            return KeyboardError.InitFailed;
        };

        var maybe_uidev: ?*c.libevdev_uinput = null;
        const rc = c.libevdev_uinput_create_from_device(device.dev, c.LIBEVDEV_UINPUT_OPEN_MANAGED, @as([*c]?*c.libevdev_uinput, &maybe_uidev));
        if (rc != 0) {
            std.log.err("Error creating the UInput device!", .{});
            return KeyboardError.InitFailed;
        }

        if (maybe_uidev) |uidev| return Keyboard{ .device = device, .uidev = uidev };
        std.log.err("Device or UInput device not available!", .{});
        return KeyboardError.InitFailed;
    }

    pub fn cleanup(self: Keyboard) void {
        c.libevdev_uinput_destroy(self.uidev);
        self.device.cleanup();
    }

    pub fn next_event(self: Keyboard) ?Event {
        var event: c.input_event = undefined;
        const rc = c.libevdev_next_event(self.device.dev, c.LIBEVDEV_READ_FLAG_NORMAL, @ptrCast(&event));
        if (rc != c.LIBEVDEV_READ_STATUS_SUCCESS) return null;
        return event;
    }

    pub fn write_event(self: Keyboard, event: Event) void {
        _ = c.libevdev_uinput_write_event(self.uidev, event.type, event.code, event.value);
    }
};

const CursorError = error{InitFailed};

const Cursor = struct {
    dev: *c.libevdev,
    uidev: *c.libevdev_uinput,

    pub fn init() CursorError!Cursor {
        const maybe_dev: ?*c.libevdev = c.libevdev_new();
        c.libevdev_set_name(maybe_dev, NAME);
        if (c.libevdev_enable_event_type(maybe_dev, c.EV_REL) != 0) return CursorError.InitFailed;
        if (c.libevdev_enable_event_type(maybe_dev, c.EV_KEY) != 0) return CursorError.InitFailed;
        if (c.libevdev_enable_event_code(maybe_dev, c.EV_REL, c.REL_X, c.NULL) != 0) return CursorError.InitFailed;
        if (c.libevdev_enable_event_code(maybe_dev, c.EV_REL, c.REL_Y, c.NULL) != 0) return CursorError.InitFailed;
        if (c.libevdev_enable_event_code(maybe_dev, c.EV_KEY, c.BTN_LEFT, c.NULL) != 0) return CursorError.InitFailed;
        if (c.libevdev_enable_event_code(maybe_dev, c.EV_KEY, c.BTN_RIGHT, c.NULL) != 0) return CursorError.InitFailed;

        var maybe_uidev: ?*c.libevdev_uinput = null;
        const rc = c.libevdev_uinput_create_from_device(maybe_dev, c.LIBEVDEV_UINPUT_OPEN_MANAGED, @ptrCast(&maybe_uidev));
        if (rc != 0) {
            // std.log.err("Error creating the UInput device: %s\n", c.strerror(-rc));
            return CursorError.InitFailed;
        }

        if (maybe_dev) |dev| if (maybe_uidev) |uidev| return Cursor{ .dev = dev, .uidev = uidev };
        return CursorError.InitFailed;
    }

    fn cleanup(self: Cursor) void {
        c.libevdev_uinput_destroy(self.uidev);
        c.libevdev_free(self.dev);
    }

    fn move(self: Cursor, x: c_int, y: c_int) void {
        if (x != 0) _ = c.libevdev_uinput_write_event(self.uidev, c.EV_REL, c.REL_X, x);
        if (y != 0) _ = c.libevdev_uinput_write_event(self.uidev, c.EV_REL, c.REL_Y, y);
        _ = c.libevdev_uinput_write_event(self.uidev, c.EV_SYN, c.SYN_REPORT, 0);
    }

    fn click_left(self: Cursor, state: c_int) void {
        _ = c.libevdev_uinput_write_event(self.uidev, c.EV_KEY, c.BTN_LEFT, state);
        _ = c.libevdev_uinput_write_event(self.uidev, c.EV_SYN, c.SYN_REPORT, 0);
    }
};

const Control = struct { h: bool = false, j: bool = false, k: bool = false, l: bool = false };

const Speed = struct {
    x: c_int = 0,
    y: c_int = 0,

    pub fn update(self: *Speed, control: Control) void {
        var x: f32 = 0;
        var y: f32 = 0;
        if (control.h) x -= 4;
        if (control.j) y += 4;
        if (control.k) y -= 4;
        if (control.l) x += 4;
        if (x != 0 and y != 0) {
            x = x * 0.707;
            y = y * 0.707;
        }
        self.x = @intFromFloat(x);
        self.y = @intFromFloat(y);
    }
};

const Rat = struct {
    time: Time,
    keyboard: Keyboard,
    cursor: Cursor,
    mod_value: Value = Value.Free,
    mode: Mode = Mode.Keyboard,
    speed: Speed = Speed{},
    start: u64 = 0,
    control: Control = Control{},

    pub fn init(keyboard: Keyboard, cursor: Cursor) !Rat {
        const time: Time = try Time.init();
        return Rat{ .time = time, .keyboard = keyboard, .cursor = cursor };
    }

    pub fn x(self: *Rat) void {
        if (self.mode == Mode.Keyboard) self.x_keyboard();
        if (self.mode == Mode.Cursor) self.x_cursor();
    }

    pub fn set_mod(self: *Rat, ev: Event) void {
        if (ev.code == @intFromEnum(Code.MOD)) self.mod_value = @enumFromInt(ev.value);
    }

    pub fn toggle(self: Rat, ev: Event) bool {
        return ev.code == @intFromEnum(Code.TAB) and ev.value == @intFromEnum(Value.Down) and self.mod_value != Value.Free;
    }

    pub fn x_keyboard(self: *Rat) void {
        const ev = self.keyboard.next_event() orelse return;
        if (ev.type != c.EV_KEY) {
            self.keyboard.write_event(ev);
            return;
        }
        self.set_mod(ev);
        if (self.toggle(ev)) {
            self.mode = Mode.Cursor;
            return;
        }
        self.keyboard.write_event(ev);
    }

    pub fn x_cursor(self: *Rat) void {
        if (self.time.nextFrame()) self.cursor.move(self.speed.x, self.speed.y);

        const ev = self.keyboard.next_event() orelse return;
        if (ev.type != c.EV_KEY) {
            self.keyboard.write_event(ev);
            return;
        }
        self.set_mod(ev);
        if (self.toggle(ev)) {
            self.mode = Mode.Keyboard;
            return;
        }

        if (ev.code == @intFromEnum(Code.SPACE) and ev.value != @intFromEnum(Value.Hold)) self.cursor.click_left(ev.value);

        switch (ev.code) {
            @intFromEnum(Code.H) => self.control.h = ev.value != @intFromEnum(Value.Free),
            @intFromEnum(Code.J) => self.control.j = ev.value != @intFromEnum(Value.Free),
            @intFromEnum(Code.K) => self.control.k = ev.value != @intFromEnum(Value.Free),
            @intFromEnum(Code.L) => self.control.l = ev.value != @intFromEnum(Value.Free),
            else => {},
        }

        self.speed.update(self.control);
    }
};

pub fn main() !void {
    hello();
    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    if (args.len != 2) {
        try stdout.print("Usage: {s} /path/to/keyboard\n", .{args[0]});
        return Error.ExpectedArgument;
    }
    const keyboard = try Keyboard.init(args[1]);
    defer keyboard.cleanup();
    const cursor = try Cursor.init();
    defer cursor.cleanup();
    std.time.sleep(10 * std.time.ns_per_ms);
    try keyboard.device.grab();
    defer keyboard.device.ungrab();
    var rat = try Rat.init(keyboard, cursor);
    while (true) {
        rat.x();
    }

    // var rat = try Rat.init();
    // defer rat.cleanup();
    // while (true) {
    //     rat.move();
    //     rat.handleEvents();
    // }
}
