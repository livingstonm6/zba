const std = @import("std");
const emulator = @import("emulator.zig");

fn getFilename() ![]const u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Enter ROM filename:", .{});

    var input_buffer: [100]u8 = undefined;
    var filename: []const u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |value| {
        filename = std.mem.trimRight(u8, value[0 .. value.len - 1], "\r");
        std.log.debug("Filename: {s}", .{filename});
        return filename;
    } else {
        std.log.debug("Error reading input.", .{});
        return "";
    }
}

pub fn main() !void {
    const filename = "pkmn.gba";
    try emulator.run(filename);
}
