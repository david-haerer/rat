const std = @import("std");
const NS_PER_FRAME = std.time.ns_per_ms * 10;

pub const Time = struct {
    timer: std.time.Timer,
    frame: u64 = 0,
    now: u64 = 0,

    pub fn init() !Time {
        const timer = try std.time.Timer.start();
        return Time{ .timer = timer };
    }

    pub fn nextFrame(self: *Time) bool {
        self.now = self.timer.read();
        if (self.now < NS_PER_FRAME * self.frame + 1) {
            return false;
        }
        self.frame += 1;
        return true;
    }
};
