const std = @import("std");
const cart = @import("cart.zig");

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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const filename = "pkmn.gba";
    var cartridge = try cart.initCart(gpa.allocator(), filename);
    defer cartridge.deinit();

    std.log.debug("ROM title: {s}", .{cartridge.title});
    std.log.debug("ROM Size (bytes): {}", .{cartridge.data.len});
}
