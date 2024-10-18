const std = @import("std");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Enter ROM filename:", .{});

    var input_buffer: [100]u8 = undefined;
    var file_name: []const u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |value| {
        file_name = std.mem.trimRight(u8, value[0 .. value.len - 1], "\r");
        std.log.debug("{s}", .{file_name});
    } else {
        std.log.debug("Error reading input.", .{});
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buffered_file = std.io.bufferedReader(file.reader());
    var buffer: [1]u8 = undefined;

    while (true) {
        const num_bytes_read = try buffered_file.read(&buffer);

        if (num_bytes_read == 0) {
            break;
        }

        try list.append(buffer[0]);
    }

    std.log.debug("list: {any}", .{list.items});
}
