const std = @import("std");
const Cart = @import("cart.zig").Cart;

pub const MemoryBus = struct {
    cart: *const Cart,
    allocator: std.mem.Allocator,
    ram: []u8 = undefined,

    pub fn init(self: *MemoryBus) !void {
        const bios = try std.fs.cwd().openFile("bios.bin", .{});
        defer bios.close();

        const file_size = try bios.getEndPos();
        self.ram = try self.allocator.alloc(u8, file_size);

        var buffered_bios = std.io.bufferedReader(bios.reader());
        var buffer: [1]u8 = undefined;

        for (0..file_size) |i| {
            const num_bytes_read = try buffered_bios.read(&buffer);

            if (num_bytes_read == 0) break;

            self.ram[i] = buffer[0];
        }
    }

    pub fn deinit(self: MemoryBus) void {
        self.allocator.free(self.ram);
    }

    pub fn read8(self: MemoryBus, address: u32) u8 {
        if (address < 0x05000000) {
            return self.ram[address];
        }
        if (address > 0x07FFFFFF and address < 0x10000000) {
            return self.cart.data[address - 0x08000000];
        }
        unreachable;
    }

    pub fn read16(self: MemoryBus, address: u32) u16 {
        const lower = self.read8(address);
        const upper = self.read8(address + 1);

        return lower | (@as(u16, upper) << 8);
    }

    pub fn read32(self: MemoryBus, address: u32) u32 {
        const lower = self.read16(address);
        const upper = self.read16(address + 2);

        return lower | (@as(u32, upper) << 16);
    }

    pub fn write8(self: MemoryBus, address: u32, value: u8) void {
        if (address < 0x05000000) {
            self.ram[address] = value;
        }
        unreachable;
    }

    pub fn write16(self: MemoryBus, address: u32, value: u16) void {
        self.write8(address, @intCast(value & 0xFF));
        self.write8(address + 1, @intCast((value >> 8) & 0xFF));
    }

    pub fn write32(self: MemoryBus, address: u32, value: u32) void {
        self.write16(address, @intCast(value & 0xFFFF));
        self.write16(address + 2, @intCast((value >> 16) & 0xFFFF));
    }
};

pub fn createBus(cart: *const Cart, allocator: std.mem.Allocator) !MemoryBus {
    var bus = MemoryBus{ .cart = cart, .allocator = allocator };
    try bus.init();

    return bus;
}
