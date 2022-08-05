const std = @import("std");
const Image = @import("../Image.zig");

// Implement a variable code size LZW decoder with support for clear code and end of information code required for GIF decoding
pub fn Decoder(comptime endian: std.builtin.Endian) type {
    return struct {
        area_allocator: std.heap.ArenaAllocator,
        code_size: u8 = 0,
        clear_code: u12 = 0,
        end_information_code: u12 = 0,
        next_code: u12 = 0,
        previous_code: ?u12 = null,
        dictionary: std.AutoArrayHashMap(u12, []const u8),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, initial_code_size: u8) !Self {
            var result = Self{
                .area_allocator = std.heap.ArenaAllocator.init(allocator),
                .code_size = initial_code_size,
                .dictionary = std.AutoArrayHashMap(u12, []const u8).init(allocator),
            };

            // Reset dictionary and code to its default state
            try result.resetDictionary();

            return result;
        }

        pub fn deinit(self: *Self) void {
            self.area_allocator.deinit();
            self.dictionary.deinit();
        }

        pub fn decode(self: *Self, reader: Image.Stream.Reader, writer: Image.Stream.Writer) !void {
            var bit_reader = std.io.bitReader(endian, reader);

            var bits_to_read = self.code_size + 1;

            var read_size: usize = 0;
            var read_code = try bit_reader.readBits(u12, bits_to_read, &read_size);

            var allocator = self.area_allocator.allocator();

            while (read_size > 0) {
                if (self.dictionary.get(read_code)) |value| {
                    _ = try writer.write(value);

                    if (self.previous_code) |previous_code| {
                        if (self.dictionary.get(previous_code)) |previous_value| {
                            var new_value = try allocator.alloc(u8, previous_value.len + 1);
                            std.mem.copy(u8, new_value, previous_value);
                            new_value[previous_value.len] = value[0];
                            try self.dictionary.put(self.next_code, new_value);

                            self.next_code += 1;

                            const max_code = (@as(u12, 1) << @intCast(u4, self.code_size)) + 1;
                            if (self.next_code == max_code) {
                                self.code_size += 1;
                                bits_to_read += 1;
                            }
                        }
                    }
                } else {
                    if (read_code == self.clear_code) {
                        try self.resetDictionary();
                    } else if (read_code == self.end_information_code) {
                        return;
                    } else {
                        if (self.previous_code) |previous_code| {
                            if (self.dictionary.get(previous_code)) |previous_value| {
                                var new_value = try allocator.alloc(u8, previous_value.len + 1);
                                std.mem.copy(u8, new_value, previous_value);
                                new_value[previous_value.len] = previous_value[0];
                                try self.dictionary.put(self.next_code, new_value);

                                _ = try writer.write(new_value);

                                self.next_code += 1;

                                const max_code = (@as(u12, 1) << @intCast(u4, self.code_size)) + 1;
                                if (self.next_code == max_code) {
                                    self.code_size += 1;
                                    bits_to_read += 1;
                                }
                            }
                        }
                    }
                }

                self.previous_code = read_code;

                read_code = try bit_reader.readBits(u12, bits_to_read, &read_size);
            }
        }

        fn resetDictionary(self: *Self) !void {
            self.dictionary.clearRetainingCapacity();
            self.area_allocator.deinit();

            self.area_allocator = std.heap.ArenaAllocator.init(self.area_allocator.child_allocator);
            var allocator = self.area_allocator.allocator();

            const roots_size = @as(usize, 1) << @intCast(u6, self.code_size);

            var index: u12 = 0;

            while (index < roots_size) : (index += 1) {
                var data = try allocator.alloc(u8, 1);
                data[0] = @truncate(u8, index);

                try self.dictionary.put(index, data);
            }

            self.clear_code = index;
            self.end_information_code = index + 1;
            self.next_code = index + 2;
            self.previous_code = null;
        }
    };
}

test "Should decode a simple LZW little-endian stream" {
    const initial_code_size = 2;
    const test_data = [_]u8{ 0x4c, 0x01 };

    var reader = Image.Stream{
        .const_buffer = std.io.fixedBufferStream(&test_data),
    };

    var out_data_storage: [256]u8 = undefined;
    var out_data_buffer = Image.Stream{
        .buffer = std.io.fixedBufferStream(&out_data_storage),
    };

    var lzw = try Decoder(.Little).init(std.testing.allocator, initial_code_size);
    defer lzw.deinit();

    try lzw.decode(reader.reader(), out_data_buffer.writer());

    try std.testing.expectEqual(@as(usize, 1), out_data_buffer.buffer.pos);
    try std.testing.expectEqual(@as(u8, 1), out_data_storage[0]);
}