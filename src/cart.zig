const std = @import("std");

pub const Cart = struct {
    allocator: std.mem.Allocator,
    data: []u8 = undefined,

    pub fn init(self: *Cart) !void {
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();

        try stdout.print("Enter ROM filename:", .{});

        var input_buffer: [100]u8 = undefined;
        var filename: []const u8 = undefined;

        if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |value| {
            filename = std.mem.trimRight(u8, value[0 .. value.len - 1], "\r");
            std.log.debug("Filename: {s}", .{filename});
            try self.loadRom(filename);
        } else {
            std.log.debug("Error reading input.", .{});
            return;
        }
    }

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
    }

    pub fn deinit(self: Cart) void {
        self.allocator.free(self.data);
    }
};
