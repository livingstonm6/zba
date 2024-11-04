const std = @import("std");
const cart = @import("cart.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var cartridge = cart.Cart{ .allocator = gpa.allocator() };
    try cartridge.init();
    defer cartridge.deinit();

    std.log.debug("bytes: {}", .{cartridge.data.len});
}
