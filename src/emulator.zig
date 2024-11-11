const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const MemoryBus = @import("bus.zig").MemoryBus;
const initCart = @import("cart.zig").initCart;

pub fn run(filename: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const cart = try initCart(gpa.allocator(), filename);
    const bus = MemoryBus{ .cart = &cart };
    var cpu = CPU{ .bus = &bus };

    while (cpu.running) {
        cpu.step();
    }
}
