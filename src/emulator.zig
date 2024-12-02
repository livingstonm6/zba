const std = @import("std");
const initCPU = @import("cpu.zig").createCPU;
const createBus = @import("bus.zig").createBus;
const createCart = @import("cart.zig").createCart;

pub fn run(filename: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const cart = try createCart(allocator, filename);
    defer cart.deinit();
    const bus = try createBus(&cart, allocator);
    defer bus.deinit();
    var cpu = initCPU(&bus);

    while (cpu.running) {
        cpu.step();
    }
}
