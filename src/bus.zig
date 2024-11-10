const Cart = @import("cart.zig").Cart;

const MemoryBus = struct {
    cart: *const Cart,

    pub fn read8(self: MemoryBus, address: u32) u8 {
        return self.cart.data[address];
    }

    pub fn read16(self: MemoryBus, address: u32) u16 {
        const lower = self.read8(address);
        const upper = self.read8(address + 1);

        return lower | (upper << 8);
    }

    pub fn read32(self: MemoryBus, address: u32) u32 {
        const lower = self.read16(address);
        const upper = self.read16(address + 2);

        return lower | (upper << 16);
    }
};
