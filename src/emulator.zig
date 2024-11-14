const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const createBus = @import("bus.zig").createBus;
const initCart = @import("cart.zig").initCart;

pub fn run(filename: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const cart = try initCart(allocator, filename);
    defer cart.deinit();
    const bus = try createBus(&cart, allocator);
    defer bus.deinit();
    var cpu = CPU{ .bus = &bus };

    while (cpu.running) {
        cpu.step();
    }
}
