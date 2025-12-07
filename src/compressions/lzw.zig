const std = @import("std");
const io = @import("../io.zig");

// Implement a variable code size LZW decoder with support for clear code and end of information code required for GIF decoding
pub fn Decoder(comptime endian: std.builtin.Endian) type {
    return struct {
        area_allocator: std.heap.ArenaAllocator,
        code_size: u8 = 0,
        clear_code: u13 = 0,
        initial_code_size: u8 = 0,
        end_information_code: u13 = 0,
        next_code: u13 = 0,
        previous_code: ?u13 = null,
        dictionary: std.AutoArrayHashMap(u13, []const u8),

        remaining_data: ?u13 = null,
        remaining_bits: u4 = 0,

        // Some LZW encoders (eg. TIFF) increase the code size too early
        early_change: u8 = 0,

        const MaxCodeSize = 12;

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, initial_code_size: u8, early_change: u8) !Self {
            var result = Self{
                .area_allocator = std.heap.ArenaAllocator.init(allocator),
                .code_size = initial_code_size,
                .dictionary = std.AutoArrayHashMap(u13, []const u8).init(allocator),
                .initial_code_size = initial_code_size,
                .clear_code = @as(u13, 1) << @intCast(initial_code_size),
                .end_information_code = (@as(u13, 1) << @intCast(initial_code_size)) + 1,
                .next_code = (@as(u13, 1) << @intCast(initial_code_size)) + 2,
                .early_change = early_change,
            };

            // Reset dictionary and code to its default state
            try result.resetDictionary();

            return result;
        }

        pub fn deinit(self: *Self) void {
            self.area_allocator.deinit();
            self.dictionary.deinit();
        }

        pub fn decode(self: *Self, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
            var bit_reader: io.BitReader(endian) = .{
                .reader = reader,
            };

            var bits_to_read = self.code_size + 1;

            var read_size: u16 = 0;
            var read_code: u13 = 0;

            if (self.remaining_data) |remaining_data| {
                const rest_of_data = try bit_reader.readBits(u13, self.remaining_bits, &read_size);

                if (read_size > 0) {
                    switch (endian) {
                        .little => {
                            read_code = remaining_data | (rest_of_data << @as(u4, @intCast(bits_to_read - self.remaining_bits)));
                        },
                        .big => {
                            read_code = (remaining_data << self.remaining_bits) | rest_of_data;
                        },
                    }
                }
                self.remaining_data = null;
            } else {
                read_code = try bit_reader.readBits(u13, bits_to_read, &read_size);
            }

            var allocator = self.area_allocator.allocator();

            while (read_size > 0) {
                if (self.dictionary.get(read_code)) |value| {
                    _ = try writer.write(value);

                    if (self.previous_code) |previous_code| {
                        if (self.dictionary.get(previous_code)) |previous_value| {
                            var new_value = try allocator.alloc(u8, previous_value.len + 1);
                            std.mem.copyForwards(u8, new_value, previous_value);
                            new_value[previous_value.len] = value[0];
                            try self.dictionary.put(self.next_code, new_value);

                            self.next_code += 1;

                            const max_code = @as(u13, 1) << @intCast(self.code_size + 1);
                            if (self.next_code == (max_code - self.early_change) and (self.code_size + 1) < MaxCodeSize) {
                                self.code_size += 1;
                                bits_to_read += 1;
                            }
                        }
                    }
                } else {
                    if (read_code == self.clear_code) {
                        try self.resetDictionary();
                        bits_to_read = self.code_size + 1;
                        self.previous_code = read_code;
                    } else if (read_code == self.end_information_code) {
                        return;
                    } else {
                        if (self.previous_code) |previous_code| {
                            if (self.dictionary.get(previous_code)) |previous_value| {
                                var new_value = try allocator.alloc(u8, previous_value.len + 1);
                                std.mem.copyForwards(u8, new_value, previous_value);
                                new_value[previous_value.len] = previous_value[0];
                                try self.dictionary.put(self.next_code, new_value);

                                _ = try writer.write(new_value);

                                self.next_code += 1;

                                const max_code = @as(u13, 1) << @intCast(self.code_size + 1);
                                if (self.next_code == (max_code - self.early_change) and (self.code_size + 1) < MaxCodeSize) {
                                    self.code_size += 1;
                                    bits_to_read += 1;
                                }
                            }
                        }
                    }
                }

                self.previous_code = read_code;

                read_code = try bit_reader.readBits(u13, bits_to_read, &read_size);
                if (read_size != bits_to_read) {
                    self.remaining_data = read_code;
                    self.remaining_bits = @intCast(bits_to_read - read_size);
                    return;
                }
            }
        }

        fn resetDictionary(self: *Self) !void {
            self.dictionary.clearRetainingCapacity();
            self.area_allocator.deinit();

            self.code_size = self.initial_code_size;
            self.next_code = (@as(u13, 1) << @intCast(self.initial_code_size)) + 2;

            self.area_allocator = std.heap.ArenaAllocator.init(self.area_allocator.child_allocator);
            var allocator = self.area_allocator.allocator();

            const roots_size = @as(usize, 1) << @intCast(self.code_size);

            var index: u13 = 0;

            while (index < roots_size) : (index += 1) {
                var data = try allocator.alloc(u8, 1);
                data[0] = @as(u8, @truncate(index));

                try self.dictionary.put(index, data);
            }
        }
    };
}

/// LZW Encoder - compresses data using LZW algorithm
/// GIF uses LSB (Least Significant Bit first) ordering
pub fn Encoder(comptime endian: std.builtin.Endian) type {
    return struct {
        // Constants matching Go implementation
        const max_code: u32 = (1 << 12) - 1; // 4095 - maximum 12-bit code
        const invalid_code: u32 = std.math.maxInt(u32);
        const table_size: u32 = 4 * (1 << 12); // 16384
        const table_mask: u32 = table_size - 1;
        const invalid_entry: u32 = 0;

        const Self = @This();

        // Bit buffer for accumulating bits before writing bytes
        bits: u32 = 0,
        n_bits: u5 = 0,

        // Code width management
        lit_width: u4, // literal width (typically 8 for GIF)
        width: u5, // current code width in bits
        hi: u32, // next code to be assigned
        overflow: u32, // code at which width increases

        // State
        saved_code: u32 = invalid_code,
        closed: bool = false,

        // Hash table: maps (prefix_code << 8 | byte) -> code
        // Entry format: (key << 12) | code, where key = (prefix << 8 | byte)
        table: [table_size]u32 = [_]u32{invalid_entry} ** table_size,

        pub const Error = error{
            WriteFailed,
            InvalidLitWidth,
            EncoderClosed,
            InputTooLarge,
        };

        pub fn init(lit_width: u4) Error!Self {
            if (lit_width < 2 or lit_width > 8) {
                return Error.InvalidLitWidth;
            }

            const clear_code = @as(u32, 1) << lit_width;

            return Self{
                .lit_width = lit_width,
                .width = lit_width + 1,
                .hi = clear_code + 1,
                .overflow = clear_code << 1,
            };
        }

        pub fn deinit(self: *Self) void {
            _ = self;
            // No allocations to free - table is inline
        }

        /// Write a single code to the output
        fn writeCode(self: *Self, writer: *std.Io.Writer, code: u32) Error!void {
            switch (endian) {
                .little => try self.writeCodeLSB(writer, code),
                .big => try self.writeCodeMSB(writer, code),
            }
        }

        /// Write code using LSB-first ordering (used by GIF)
        fn writeCodeLSB(self: *Self, writer: *std.Io.Writer, code: u32) Error!void {
            self.bits |= code << self.n_bits;
            self.n_bits += @intCast(self.width);

            while (self.n_bits >= 8) {
                writer.writeByte(@truncate(self.bits)) catch return Error.WriteFailed;
                self.bits >>= 8;
                self.n_bits -= 8;
            }
        }

        /// Write code using MSB-first ordering (used by TIFF)
        fn writeCodeMSB(self: *Self, writer: *std.Io.Writer, code: u32) Error!void {
            self.bits |= code << (@as(u5, 32) - self.width - self.n_bits);
            self.n_bits += @intCast(self.width);

            while (self.n_bits >= 8) {
                writer.writeByte(@truncate(self.bits >> 24)) catch return Error.WriteFailed;
                self.bits <<= 8;
                self.n_bits -= 8;
            }
        }

        /// Increment hi (next code) and handle overflow/reset
        /// Returns true if table was reset (out of codes)
        fn incHi(self: *Self, writer: *std.Io.Writer) Error!bool {
            self.hi += 1;

            if (self.hi == self.overflow) {
                self.width += 1;
                self.overflow <<= 1;
            }

            if (self.hi == max_code) {
                // Out of codes - emit clear code and reset
                const clear_code = @as(u32, 1) << self.lit_width;
                try self.writeCode(writer, clear_code);

                self.width = self.lit_width + 1;
                self.hi = clear_code + 1;
                self.overflow = clear_code << 1;

                // Clear the hash table
                @memset(&self.table, invalid_entry);

                return true; // Signal that we reset
            }

            return false;
        }

        /// Encode data and write compressed output
        pub fn encode(self: *Self, writer: *std.Io.Writer, data: []const u8) Error!void {
            if (self.closed) {
                return Error.EncoderClosed;
            }

            if (data.len == 0) {
                return;
            }

            // Validate input bytes are within literal range
            const max_lit: u8 = @as(u8, @truncate((@as(u16, 1) << self.lit_width) - 1));
            if (max_lit != 0xff) {
                for (data) |byte| {
                    if (byte > max_lit) {
                        return Error.InputTooLarge;
                    }
                }
            }

            var code = self.saved_code;
            var input = data;

            if (code == invalid_code) {
                // First write - emit clear code
                const clear_code = @as(u32, 1) << self.lit_width;
                try self.writeCode(writer, clear_code);

                // First byte becomes the initial code
                code = input[0];
                input = input[1..];
            }

            for (input) |byte| {
                const literal = @as(u32, byte);
                const key = (code << 8) | literal;

                // Hash lookup with linear probing
                var hash = ((key >> 12) ^ key) & table_mask;
                var found = false;

                while (self.table[hash] != invalid_entry) {
                    const entry = self.table[hash];
                    if ((entry >> 12) == key) {
                        // Found in table - extend the sequence
                        code = entry & max_code;
                        found = true;
                        break;
                    }
                    hash = (hash + 1) & table_mask;
                }

                if (!found) {
                    // Not in table - emit current code
                    try self.writeCode(writer, code);
                    code = literal;

                    // Try to add new entry to table
                    const reset = try self.incHi(writer);
                    if (!reset) {
                        // Find empty slot and insert
                        var insert_hash = ((key >> 12) ^ key) & table_mask;
                        while (self.table[insert_hash] != invalid_entry) {
                            insert_hash = (insert_hash + 1) & table_mask;
                        }
                        self.table[insert_hash] = (key << 12) | self.hi;
                    }
                }
            }

            self.saved_code = code;
        }

        /// Finish encoding - emit final code and EOF
        pub fn finish(self: *Self, writer: *std.Io.Writer) Error!void {
            if (self.closed) {
                return;
            }
            self.closed = true;

            const clear_code = @as(u32, 1) << self.lit_width;
            const eof_code = clear_code + 1;

            if (self.saved_code != invalid_code) {
                // Write the final pending code
                try self.writeCode(writer, self.saved_code);
                _ = try self.incHi(writer);
            } else {
                // No data was written - just emit clear code
                try self.writeCode(writer, clear_code);
            }

            // Write EOF code
            try self.writeCode(writer, eof_code);

            // Flush remaining bits
            if (self.n_bits > 0) {
                if (endian == .big) {
                    self.bits >>= 24;
                }
                writer.writeByte(@truncate(self.bits)) catch return Error.WriteFailed;
            }
        }
    };
}

// ============================================================================
// Decoder Tests
// ============================================================================

test "Should decode a simple LZW little-endian stream" {
    const initial_code_size = 2;
    const test_data = [_]u8{ 0x4c, 0x01 };

    var read_stream = io.ReadStream.initMemory(test_data[0..]);

    var out_data_storage: [256]u8 = undefined;
    var out_write_stream = io.WriteStream.initMemory(out_data_storage[0..]);

    var lzw = try Decoder(.little).init(std.testing.allocator, initial_code_size, 0);
    defer lzw.deinit();

    const out_writer = out_write_stream.writer();
    try lzw.decode(read_stream.reader(), out_writer);

    try std.testing.expectEqual(@as(usize, 1), out_writer.end);
    try std.testing.expectEqual(@as(u8, 1), out_data_storage[0]);
}

// ============================================================================
// Encoder Tests
// ============================================================================

test "Encoder init with valid lit_width" {
    var encoder = try Encoder(.little).init(8);
    defer encoder.deinit();

    try std.testing.expectEqual(@as(u4, 8), encoder.lit_width);
    try std.testing.expectEqual(@as(u5, 9), encoder.width);
    try std.testing.expectEqual(@as(u32, 257), encoder.hi); // clear(256) + 1
    try std.testing.expectEqual(@as(u32, 512), encoder.overflow);
}

test "Encoder init with minimum lit_width" {
    var encoder = try Encoder(.little).init(2);
    defer encoder.deinit();

    try std.testing.expectEqual(@as(u4, 2), encoder.lit_width);
    try std.testing.expectEqual(@as(u5, 3), encoder.width);
    try std.testing.expectEqual(@as(u32, 5), encoder.hi); // clear(4) + 1
    try std.testing.expectEqual(@as(u32, 8), encoder.overflow);
}

test "Encoder init rejects invalid lit_width" {
    const result1 = Encoder(.little).init(1);
    try std.testing.expectError(Encoder(.little).Error.InvalidLitWidth, result1);

    const result2 = Encoder(.little).init(9);
    try std.testing.expectError(Encoder(.little).Error.InvalidLitWidth, result2);
}

test "Encoder encode empty data does nothing" {
    var encoder = try Encoder(.little).init(8);
    defer encoder.deinit();

    var out_buffer: [256]u8 = undefined;
    var write_stream = io.WriteStream.initMemory(&out_buffer);
    const writer = write_stream.writer();

    try encoder.encode(writer, &[_]u8{});

    try std.testing.expectEqual(@as(usize, 0), writer.end);
    try std.testing.expectEqual(Encoder(.little).invalid_code, encoder.saved_code);
}

test "Encoder encode single byte" {
    var encoder = try Encoder(.little).init(8);
    defer encoder.deinit();

    var out_buffer: [256]u8 = undefined;
    var write_stream = io.WriteStream.initMemory(&out_buffer);
    const writer = write_stream.writer();

    try encoder.encode(writer, &[_]u8{0x41}); // 'A'
    try encoder.finish(writer);

    // Should have written: clear code, 'A', eof code
    try std.testing.expect(writer.end > 0);
}

test "Encoder rejects data after close" {
    var encoder = try Encoder(.little).init(8);
    defer encoder.deinit();

    var out_buffer: [256]u8 = undefined;
    var write_stream = io.WriteStream.initMemory(&out_buffer);
    const writer = write_stream.writer();

    try encoder.encode(writer, &[_]u8{0x41});
    try encoder.finish(writer);

    const result = encoder.encode(writer, &[_]u8{0x42});
    try std.testing.expectError(Encoder(.little).Error.EncoderClosed, result);
}

test "Encoder validates input range for small lit_width" {
    var encoder = try Encoder(.little).init(2); // max value is 3
    defer encoder.deinit();

    var out_buffer: [256]u8 = undefined;
    var write_stream = io.WriteStream.initMemory(&out_buffer);
    const writer = write_stream.writer();

    // Value 4 is too large for lit_width=2
    const result = encoder.encode(writer, &[_]u8{4});
    try std.testing.expectError(Encoder(.little).Error.InputTooLarge, result);
}

test "Encoder roundtrip - encode then decode simple data" {
    const original = "AAAAAAA";

    // Encode
    var encoded_buffer: [256]u8 = undefined;
    var encode_stream = io.WriteStream.initMemory(&encoded_buffer);
    const encode_writer = encode_stream.writer();

    var encoder = try Encoder(.little).init(8);
    try encoder.encode(encode_writer, original);
    try encoder.finish(encode_writer);

    const encoded_len = encode_writer.end;
    try std.testing.expect(encoded_len > 0);

    // Decode
    var decoded_buffer: [256]u8 = undefined;
    var decode_write_stream = io.WriteStream.initMemory(&decoded_buffer);
    const decode_writer = decode_write_stream.writer();

    var read_stream = io.ReadStream.initMemory(encoded_buffer[0..encoded_len]);
    var decoder = try Decoder(.little).init(std.testing.allocator, 8, 0);
    defer decoder.deinit();

    try decoder.decode(read_stream.reader(), decode_writer);

    // Verify roundtrip
    try std.testing.expectEqualSlices(u8, original, decoded_buffer[0..decode_writer.end]);
}

test "Encoder roundtrip - encode then decode varied data" {
    const original = [_]u8{ 0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 6, 7 };

    // Encode
    var encoded_buffer: [256]u8 = undefined;
    var encode_stream = io.WriteStream.initMemory(&encoded_buffer);
    const encode_writer = encode_stream.writer();

    var encoder = try Encoder(.little).init(8);
    try encoder.encode(encode_writer, &original);
    try encoder.finish(encode_writer);

    const encoded_len = encode_writer.end;

    // Decode
    var decoded_buffer: [256]u8 = undefined;
    var decode_write_stream = io.WriteStream.initMemory(&decoded_buffer);
    const decode_writer = decode_write_stream.writer();

    var read_stream = io.ReadStream.initMemory(encoded_buffer[0..encoded_len]);
    var decoder = try Decoder(.little).init(std.testing.allocator, 8, 0);
    defer decoder.deinit();

    try decoder.decode(read_stream.reader(), decode_writer);

    try std.testing.expectEqualSlices(u8, &original, decoded_buffer[0..decode_writer.end]);
}

test "Encoder roundtrip - encode then decode with small lit_width" {
    // For GIF with small palettes, lit_width can be 2-7
    const original = [_]u8{ 0, 1, 2, 3, 0, 1, 0, 2, 1, 3 }; // values 0-3

    // Encode with lit_width=2
    var encoded_buffer: [256]u8 = undefined;
    var encode_stream = io.WriteStream.initMemory(&encoded_buffer);
    const encode_writer = encode_stream.writer();

    var encoder = try Encoder(.little).init(2);
    try encoder.encode(encode_writer, &original);
    try encoder.finish(encode_writer);

    const encoded_len = encode_writer.end;

    // Decode
    var decoded_buffer: [256]u8 = undefined;
    var decode_write_stream = io.WriteStream.initMemory(&decoded_buffer);
    const decode_writer = decode_write_stream.writer();

    var read_stream = io.ReadStream.initMemory(encoded_buffer[0..encoded_len]);
    var decoder = try Decoder(.little).init(std.testing.allocator, 2, 0);
    defer decoder.deinit();

    try decoder.decode(read_stream.reader(), decode_writer);

    try std.testing.expectEqualSlices(u8, &original, decoded_buffer[0..decode_writer.end]);
}
