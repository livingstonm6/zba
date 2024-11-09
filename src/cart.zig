const std = @import("std");

const Cart = struct {
    allocator: std.mem.Allocator,
    data: []u8 = undefined,
    title: []const u8 = undefined,

    fn loadRom(self: *Cart, filename: []const u8) !void {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        const file_size = try file.getEndPos();

        var buffered_file = std.io.bufferedReader(file.reader());
        var buffer: [1]u8 = undefined;

        self.data = try self.allocator.alloc(u8, file_size);

        for (0..file_size) |i| {
            const num_bytes_read = try buffered_file.read(&buffer);

            if (num_bytes_read == 0) {
                break;
            }

            self.data[i] = buffer[0];
        }
        const title_address = 0xA0;
        self.title = self.data[title_address .. title_address + 12];
    }

    pub fn deinit(self: Cart) void {
        self.allocator.free(self.data);
    }
};

pub fn initCart(allocator: std.mem.Allocator, filename: []const u8) !Cart {
    var cart = Cart{ .allocator = allocator };
    try cart.loadRom(filename);
    return cart;
}
