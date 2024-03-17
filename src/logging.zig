const std = @import("std");

pub fn logFn(
    comptime level: std.log.Level,
    comptime _: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const allocator = std.heap.page_allocator;
    const home = std.os.getenv("HOME") orelse {
        std.debug.print("Failed to read $HOME.\n", .{});
        return;
    };
    const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, ".local/share/rat.log" }) catch |err| {
        std.debug.print("Failed to create log file path: {}\n", .{err});
        return;
    };
    defer allocator.free(path);

    const file = std.fs.createFileAbsolute(path, .{ .truncate = false }) catch |err| {
        std.debug.print("Failed to open log file: {}\n", .{err});
        return;
    };
    defer file.close();

    const stat = file.stat() catch |err| {
        std.debug.print("Failed to get stat of log file: {}\n", .{err});
        return;
    };
    file.seekTo(stat.size) catch |err| {
        std.debug.print("Failed to seek log file: {}\n", .{err});
        return;
    };

    var timestamp_buffer: [256]u8 = undefined;
    const timestamp = std.fmt.bufPrint(timestamp_buffer[0..], "{} ", .{std.time.milliTimestamp()}) catch |err| {
        std.debug.print("Failed to format timestamp: {}\n", .{err});
        return;
    };
    file.writeAll(timestamp) catch |err| {
        std.debug.print("Failed to write timestamp: {}\n", .{err});
    };

    const prefix = "[" ++ comptime level.asText() ++ "] ";
    var buffer: [256]u8 = undefined;
    const message = std.fmt.bufPrint(buffer[0..], prefix ++ format ++ "\n", args) catch |err| {
        std.debug.print("Failed to format log message: {}\n", .{err});
        return;
    };
    file.writeAll(message) catch |err| {
        std.debug.print("Failed to write log message: {}\n", .{err});
    };
}

pub fn hello() void {
    std.log.info("", .{});
    std.log.info("  +----------------------------------+", .{});
    std.log.info("  | Rat 🐀: keyboard. driven. mouse. |", .{});
    std.log.info("  +----------------------------------+", .{});
    std.log.info("", .{});
}
