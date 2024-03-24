const c = @cImport({
    @cDefine("XK_LATIN1", "1");
    @cDefine("XK_MISCELLANY", "1");
    @cInclude("X11/keysymdef.h");
});
const geo = @import("geo.zig");
const config = @import("config.zig");

pub const Mode = enum { Exit, Normal, Scroll };
pub const Button = enum(u8) { Left = 1, Middle = 2, Right = 3 };
pub const KeyCode = c_ulong;
pub const EventType = enum { Press, Release };
pub const Event = struct { key: KeyCode, type: EventType };
pub const KEY_SHIFT_LEFT: KeyCode = c.XK_Shift_L;

pub const Key = struct {
    pressed: u64 = 0,
    released: u64 = 0,
    released_old: u64 = 0,
    direction: geo.Direction,

    pub fn press(self: *Key, now: u64) bool {
        // Ignore KeyRelease events followed immediately by a KeyPress event, while the user holds down a key.
        if (self.released == now) {
            self.released = self.released_old;
            return false;
        }
        self.pressed = now;
        return true;
    }

    pub fn release(self: *Key, now: u64) void {
        self.released_old = self.released;
        self.released = now;
    }

    pub fn isClicked(self: Key, now: u64) bool {
        return self.pressed > self.released and now - self.pressed < config.NS_PER_CLICK;
    }

    pub fn isPressed(self: Key) bool {
        return self.pressed > self.released;
    }
};

pub const Keys = [4]Key;

const InputTag = enum { mode, direction, button };

pub const Input = union(InputTag) {
    mode: Mode,
    direction: geo.Direction,
    button: Button,

    pub fn read(event: Event) ?Input {
        return switch (event.key) {
            c.XK_h, c.XK_Left => Input{ .direction = geo.Direction.LEFT },
            c.XK_j, c.XK_Down => Input{ .direction = geo.Direction.DOWN },
            c.XK_k, c.XK_Up => Input{ .direction = geo.Direction.UP },
            c.XK_l, c.XK_Right => Input{ .direction = geo.Direction.RIGHT },
            c.XK_space => Input{ .button = Button.Left },
            c.XK_x => Input{ .button = Button.Middle },
            c.XK_r => Input{ .button = Button.Right },
            c.XK_s => Input{ .mode = Mode.Scroll },
            c.XK_Escape => Input{ .mode = Mode.Normal },
            c.XK_q => Input{ .mode = Mode.Exit },
            else => null,
        };
    }
};
