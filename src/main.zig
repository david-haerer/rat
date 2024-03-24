const std = @import("std");
const logging = @import("logging.zig");
const Rat = @import("rat.zig").Rat;

pub const std_options = .{ .logFn = logging.logFn };

pub fn main() !void {
    logging.hello();
    var rat = try Rat.init();
    defer rat.cleanup();
    while (rat.running()) {
        rat.move();
        rat.handleEvents();
    }
}
