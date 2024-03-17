const std = @import("std");
const logging = @import("logging.zig");
const x11 = @import("x11.zig");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cDefine("XK_LATIN1", "1");
    @cDefine("XK_MISCELLANY", "1");
    @cInclude("X11/keysymdef.h");
    @cInclude("X11/extensions/XTest.h");
});

pub const std_options = .{
    .logFn = logging.logFn,
};

const Display = x11.Display;
const Event = c.XEvent;

const InputTag = enum { mode, direction, button };
const Mode = enum { Exit, Normal, Scroll };
const Direction = enum(u8) { Left = 0, Down = 1, Up = 2, Right = 3 };
const Button = enum(c.uint) { Left = 1, Middle = 2, Right = 3 };
const Input = union(InputTag) { mode: Mode, direction: Direction, button: Button };

const Record = struct { speed: i32 = 0, pressed: u64 = 0, released: u64 = 0, released_old: u64 = 0 };
const Records = [4]Record;

fn pressButton(display: Display, button: Button) void {
    _ = c.XTestFakeButtonEvent(display, @intFromEnum(button), c.True, c.CurrentTime);
    std.log.debug("press", .{});
}

fn releaseButton(display: Display, button: Button) void {
    _ = c.XTestFakeButtonEvent(display, @intFromEnum(button), c.False, c.CurrentTime);
    std.log.debug("release", .{});
}

fn scrollVertical(display: Display, direction: Direction) void {
    const code: c.uint = switch (direction) {
        .Up, .Left => 4,
        .Down, .Right => 5,
    };
    _ = c.XTestFakeButtonEvent(display, code, c.True, c.CurrentTime);
    _ = c.XTestFakeButtonEvent(display, code, c.False, c.CurrentTime);
}

fn scrollHorizontal(display: Display, direction: Direction) void {
    const shift = c.XKeysymToKeycode(display, c.XK_Shift_L);
    _ = c.XTestFakeKeyEvent(display, shift, c.True, c.CurrentTime);
    scrollVertical(display, direction);
    _ = c.XTestFakeKeyEvent(display, shift, c.False, c.CurrentTime);
}

fn scroll(display: x11.Display, records: Records, frame: u64) void {
    if (records[at(Direction.Down)].pressed > records[at(Direction.Down)].released and frame % 8 == 0) {
        scrollVertical(display, Direction.Down);
    }
    if (records[at(Direction.Up)].pressed > records[at(Direction.Up)].released and frame % 8 == 0) {
        scrollVertical(display, Direction.Up);
    }
    if (records[at(Direction.Right)].pressed > records[at(Direction.Right)].released and frame % 4 == 0) {
        scrollHorizontal(display, Direction.Right);
    }
    if (records[at(Direction.Left)].pressed > records[at(Direction.Left)].released and frame % 4 == 0) {
        scrollHorizontal(display, Direction.Left);
    }
}

fn move(display: ?Display, speed: Speed) void {
    _ = c.XTestFakeRelativeMotionEvent(display, speed.x, speed.y, 0);
}

const Speed = struct {
    x: i32,
    y: i32,
};

fn getSpeed(records: Records) Speed {
    const x: i32 = records[at(Direction.Right)].speed - records[at(Direction.Left)].speed;
    const y: i32 = records[at(Direction.Down)].speed - records[at(Direction.Up)].speed;
    return Speed{
        .x = @divTrunc(x, 20),
        .y = @divTrunc(y, 20),
    };
}

fn read(display: Display, event: Event) ?Input {
    const key_symbol = c.XKeycodeToKeysym(display, @intCast(event.xkey.keycode), 0);
    return switch (key_symbol) {
        c.XK_h, c.XK_Left => Input{ .direction = Direction.Left },
        c.XK_j, c.XK_Down => Input{ .direction = Direction.Down },
        c.XK_k, c.XK_Up => Input{ .direction = Direction.Up },
        c.XK_l, c.XK_Right => Input{ .direction = Direction.Right },
        c.XK_space => Input{ .button = Button.Left },
        c.XK_x => Input{ .button = Button.Middle },
        c.XK_r => Input{ .button = Button.Right },
        c.XK_s => Input{ .mode = Mode.Scroll },
        c.XK_Escape => Input{ .mode = Mode.Normal },
        c.XK_q => Input{ .mode = Mode.Exit },
        else => null,
    };
}

fn pressDirection(record: *Record, opposite: *Record, now: u64) void {
    if (record.released == now) {
        record.released = record.released_old;
        return;
    }
    record.pressed = now;
    opposite.speed = 0;
}

fn releaseDirection(record: *Record, now: u64) void {
    record.released_old = record.released;
    record.released = now;
}

fn accel(record: *Record) void {
    if (record.pressed > record.released) {
        record.speed += 4;
    } else if (record.speed > 0) {
        record.speed -= 3;
    }
}

const NS_PER_FRAME = std.time.ns_per_ms * 10;

fn at(direction: Direction) u8 {
    return @intFromEnum(direction);
}

fn atOpposite(direction: Direction) u8 {
    return 3 - @intFromEnum(direction);
}

pub fn main() !void {
    logging.hello();
    const display = try x11.connect();
    defer x11.disconnect(display);

    var event: Event = undefined;
    var timer = try std.time.Timer.start();
    var now: u64 = 0;
    var frame: u64 = 0;
    var records: Records = [_]Record{Record{}} ** 4;
    var input: Input = undefined;
    var mode = Mode.Normal;

    while (mode != Mode.Exit) {
        now = timer.read();

        if (now > NS_PER_FRAME * (frame + 1)) {
            frame = frame + 1;
            for (&records) |*record| {
                accel(record);
            }
            switch (mode) {
                .Normal => {
                    move(display, getSpeed(records));
                },
                .Scroll => {
                    scroll(display, records, frame);
                },
                .Exit => {},
            }
        }

        while (c.XPending(display) > 0) {
            _ = c.XNextEvent(display, &event);
            input = read(display, event) orelse continue;
            switch (event.type) {
                c.KeyPress => {
                    switch (input) {
                        Input.direction => |direction| {
                            pressDirection(&records[at(direction)], &records[atOpposite(direction)], now);
                        },
                        Input.button => |button| {
                            pressButton(display, button);
                        },
                        Input.mode => |m| {
                            if (m == Mode.Scroll and mode == Mode.Scroll) {
                                mode = Mode.Normal;
                            } else {
                                mode = m;
                            }
                        },
                    }
                },
                c.KeyRelease => {
                    switch (input) {
                        Input.direction => |direction| {
                            releaseDirection(&records[at(direction)], now);
                        },
                        Input.button => |button| {
                            releaseButton(display, button);
                        },
                        Input.mode => {},
                    }
                },
                else => {},
            }
        }
    }
}
