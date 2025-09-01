const std = @import("std");
const builtin = @import("builtin");

pub const DEFAULT_BUFFER_SIZE = 4096;

pub const ReadStream = union(enum) {
    memory: std.Io.Reader,
    file: std.fs.File.Reader,

    pub const Error = SeekError || EndPosError || std.Io.Reader.Error;
    pub const SeekError = std.fs.File.Reader.SeekError;
    pub const EndPosError = std.fs.File.Reader.SizeError;

    pub fn initMemory(buffer: []const u8) ReadStream {
        return .{
            .memory = std.Io.Reader.fixed(buffer),
        };
    }

    pub fn initFile(file: std.fs.File, buffer: []u8) ReadStream {
        return .{
            .file = file.reader(buffer),
        };
    }

    pub fn reader(self: *ReadStream) *std.io.Reader {
        return switch (self.*) {
            .memory => |*memory_reader| memory_reader,
            .file => |*file_reader| &file_reader.interface,
        };
    }

    pub fn seekTo(self: *ReadStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                if (offset >= memory.end) {
                    return SeekError.Unseekable;
                }

                memory.seek = offset;
            },
            .file => |*file_reader| {
                const file_size = file_reader.getSize() catch {
                    return SeekError.Unseekable;
                };

                if (offset >= file_size) {
                    return SeekError.Unseekable;
                }

                try file_reader.seekTo(offset);
            },
        }
    }

    pub fn seekBy(self: *ReadStream, offset: i64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                const new_pos: i64 = @as(i64, @intCast(memory.seek)) + offset;
                if (new_pos < 0 or new_pos >= memory.end) {
                    return std.fs.File.SeekError.Unseekable;
                }

                memory.seek = @intCast(new_pos);
            },
            .file => |*file_reader| {
                // Workaround seekBy not working properly (https://github.com/ziglang/zig/issues/25020)
                var new_pos: i64 = @intCast(@as(i64, @intCast(file_reader.interface.seek)) + offset);
                if (new_pos >= 0 and new_pos < file_reader.interface.end) {
                    file_reader.interface.seek = @intCast(new_pos);
                } else {
                    file_reader.interface.seek = 0;
                    file_reader.interface.end = 0;

                    new_pos = @as(i64, @intCast(file_reader.pos)) + offset;

                    const file_size = file_reader.getSize() catch {
                        return std.fs.File.SeekError.Unseekable;
                    };

                    if (new_pos < 0 or new_pos >= file_size) {
                        return std.fs.File.SeekError.Unseekable;
                    }

                    file_reader.pos = @intCast(new_pos);
                }
            },
        }
    }

    pub fn getPos(self: *const ReadStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.seek,
            .file => |*file_reader| file_reader.logicalPos(),
        };
    }

    pub fn getEndPos(self: *ReadStream) EndPosError!u64 {
        return switch (self.*) {
            .memory => |*memory| memory.buffer.len,
            .file => |*file_reader| file_reader.getSize(),
        };
    }
};

pub const WriteStream = union(enum) {
    memory: std.Io.Writer,
    file: std.fs.File.Writer,

    pub const Error = SeekError || std.Io.Writer.Error;
    pub const SeekError = std.fs.File.SeekError;

    pub fn initMemory(buffer: []u8) WriteStream {
        return .{
            .memory = std.Io.Writer.fixed(buffer),
        };
    }

    pub fn initFile(file: std.fs.File, buffer: []u8) WriteStream {
        return .{
            .file = file.writer(buffer),
        };
    }

    pub fn writer(self: *WriteStream) *std.io.Writer {
        return switch (self.*) {
            .memory => |*memory_writer| memory_writer,
            .file => |*file_writer| &file_writer.interface,
        };
    }

    pub fn seekTo(self: *WriteStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                if (offset >= memory.buffer.len) {
                    return SeekError.Unseekable;
                }

                memory.end = offset;
            },
            .file => |*file_writer| {
                self.flush() catch {
                    return SeekError.Unexpected;
                };
                file_writer.interface.end = 0;
                try file_writer.seekTo(offset);
            },
        }
    }

    pub fn getPos(self: *const WriteStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.end,
            .file => |*file_writer| file_writer.pos + file_writer.interface.end,
        };
    }

    pub fn flush(self: *WriteStream) std.Io.Writer.Error!void {
        return switch (self.*) {
            .memory => |*memory| memory.flush(),
            .file => |*file_writer| file_writer.interface.flush(),
        };
    }
};

// BitReader and BitWriter are imported from zig standard library of 0.14.1

//General note on endianess:
//Big endian is packed starting in the most significant part of the byte and subsequent
// bytes contain less significant bits. Thus we always take bits from the high
// end and place them below existing bits in our output.
//Little endian is packed starting in the least significant part of the byte and
// subsequent bytes contain more significant bits. Thus we always take bits from
// the low end and place them above existing bits in our output.
//Regardless of endianess, within any given byte the bits are always in most
// to least significant order.
//Also regardless of endianess, the buffer always aligns bits to the low end
// of the byte.
pub fn BitReader(comptime endian: std.builtin.Endian) type {
    return struct {
        reader: *std.Io.Reader,
        bits: u8 = 0,
        count: u4 = 0,

        const low_bit_mask = [9]u8{
            0b00000000,
            0b00000001,
            0b00000011,
            0b00000111,
            0b00001111,
            0b00011111,
            0b00111111,
            0b01111111,
            0b11111111,
        };

        fn Bits(comptime T: type) type {
            return struct {
                T,
                u16,
            };
        }

        fn initBits(comptime T: type, out: anytype, num: u16) Bits(T) {
            const UT = std.meta.Int(.unsigned, @bitSizeOf(T));
            return .{
                @bitCast(@as(UT, @intCast(out))),
                num,
            };
        }

        /// Reads `bits` bits from the reader and returns a specified type
        ///  containing them in the least significant end, returning an error if the
        ///  specified number of bits could not be read.
        pub fn readBitsNoEof(self: *@This(), comptime T: type, num: u16) !T {
            const b, const c = try self.readBitsTuple(T, num);
            if (c < num) return error.EndOfStream;
            return b;
        }

        /// Reads `bits` bits from the reader and returns a specified type
        ///  containing them in the least significant end. The number of bits successfully
        ///  read is placed in `out_bits`, as reaching the end of the stream is not an error.
        pub fn readBits(self: *@This(), comptime T: type, num: u16, out_bits: *u16) !T {
            const b, const c = try self.readBitsTuple(T, num);
            out_bits.* = c;
            return b;
        }

        /// Reads `bits` bits from the reader and returns a tuple of the specified type
        ///  containing them in the least significant end, and the number of bits successfully
        ///  read. Reaching the end of the stream is not an error.
        pub fn readBitsTuple(self: *@This(), comptime T: type, num: u16) !Bits(T) {
            const UT = std.meta.Int(.unsigned, @bitSizeOf(T));
            const U = if (@bitSizeOf(T) < 8) u8 else UT; //it is a pain to work with <u8

            //dump any bits in our buffer first
            if (num <= self.count) return initBits(T, self.removeBits(@intCast(num)), num);

            var out_count: u16 = self.count;
            var out: U = self.removeBits(self.count);

            //grab all the full bytes we need and put their
            //bits where they belong
            const full_bytes_left = (num - out_count) / 8;

            for (0..full_bytes_left) |_| {
                const byte = self.reader.takeByte() catch |err| switch (err) {
                    error.EndOfStream => return initBits(T, out, out_count),
                    else => |e| return e,
                };

                switch (endian) {
                    .big => {
                        if (U == u8) out = 0 else out <<= 8; //shifting u8 by 8 is illegal in Zig
                        out |= byte;
                    },
                    .little => {
                        const pos = @as(U, byte) << @intCast(out_count);
                        out |= pos;
                    },
                }
                out_count += 8;
            }

            const bits_left = num - out_count;
            const keep = 8 - bits_left;

            if (bits_left == 0) return initBits(T, out, out_count);

            const final_byte = self.reader.takeByte() catch |err| switch (err) {
                error.EndOfStream => return initBits(T, out, out_count),
                else => |e| return e,
            };

            switch (endian) {
                .big => {
                    out <<= @intCast(bits_left);
                    out |= final_byte >> @intCast(keep);
                    self.bits = final_byte & low_bit_mask[keep];
                },
                .little => {
                    const pos = @as(U, final_byte & low_bit_mask[bits_left]) << @intCast(out_count);
                    out |= pos;
                    self.bits = final_byte >> @intCast(bits_left);
                },
            }

            self.count = @intCast(keep);
            return initBits(T, out, num);
        }

        //convenience function for removing bits from
        //the appropriate part of the buffer based on
        //endianess.
        fn removeBits(self: *@This(), num: u4) u8 {
            if (num == 8) {
                self.count = 0;
                return self.bits;
            }

            const keep = self.count - num;
            const bits = switch (endian) {
                .big => self.bits >> @intCast(keep),
                .little => self.bits & low_bit_mask[num],
            };
            switch (endian) {
                .big => self.bits &= low_bit_mask[keep],
                .little => self.bits >>= @intCast(num),
            }

            self.count = keep;
            return bits;
        }

        pub fn alignToByte(self: *@This()) void {
            self.bits = 0;
            self.count = 0;
        }
    };
}

test "BitReader: api coverage" {
    const mem_be = [_]u8{ 0b11001101, 0b00001011 };
    const mem_le = [_]u8{ 0b00011101, 0b10010101 };

    var mem_in_be = std.Io.Reader.fixed(mem_be[0..]);
    var bit_stream_be: BitReader(.big) = .{
        .reader = &mem_in_be,
    };

    var out_bits: u16 = undefined;

    const expect = std.testing.expect;
    const expectError = std.testing.expectError;

    try expect(1 == try bit_stream_be.readBits(u2, 1, &out_bits));
    try expect(out_bits == 1);
    try expect(2 == try bit_stream_be.readBits(u5, 2, &out_bits));
    try expect(out_bits == 2);
    try expect(3 == try bit_stream_be.readBits(u128, 3, &out_bits));
    try expect(out_bits == 3);
    try expect(4 == try bit_stream_be.readBits(u8, 4, &out_bits));
    try expect(out_bits == 4);
    try expect(5 == try bit_stream_be.readBits(u9, 5, &out_bits));
    try expect(out_bits == 5);
    try expect(1 == try bit_stream_be.readBits(u1, 1, &out_bits));
    try expect(out_bits == 1);

    mem_in_be.seek = 0;
    bit_stream_be.count = 0;
    try expect(0b110011010000101 == try bit_stream_be.readBits(u15, 15, &out_bits));
    try expect(out_bits == 15);

    mem_in_be.seek = 0;
    bit_stream_be.count = 0;
    try expect(0b1100110100001011 == try bit_stream_be.readBits(u16, 16, &out_bits));
    try expect(out_bits == 16);

    _ = try bit_stream_be.readBits(u0, 0, &out_bits);

    try expect(0 == try bit_stream_be.readBits(u1, 1, &out_bits));
    try expect(out_bits == 0);
    try expectError(error.EndOfStream, bit_stream_be.readBitsNoEof(u1, 1));

    var mem_in_le = std.Io.Reader.fixed(mem_le[0..]);
    var bit_stream_le: BitReader(.little) = .{
        .reader = &mem_in_le,
    };

    try expect(1 == try bit_stream_le.readBits(u2, 1, &out_bits));
    try expect(out_bits == 1);
    try expect(2 == try bit_stream_le.readBits(u5, 2, &out_bits));
    try expect(out_bits == 2);
    try expect(3 == try bit_stream_le.readBits(u128, 3, &out_bits));
    try expect(out_bits == 3);
    try expect(4 == try bit_stream_le.readBits(u8, 4, &out_bits));
    try expect(out_bits == 4);
    try expect(5 == try bit_stream_le.readBits(u9, 5, &out_bits));
    try expect(out_bits == 5);
    try expect(1 == try bit_stream_le.readBits(u1, 1, &out_bits));
    try expect(out_bits == 1);

    mem_in_le.seek = 0;
    bit_stream_le.count = 0;
    try expect(0b001010100011101 == try bit_stream_le.readBits(u15, 15, &out_bits));
    try expect(out_bits == 15);

    mem_in_le.seek = 0;
    bit_stream_le.count = 0;
    try expect(0b1001010100011101 == try bit_stream_le.readBits(u16, 16, &out_bits));
    try expect(out_bits == 16);

    _ = try bit_stream_le.readBits(u0, 0, &out_bits);

    try expect(0 == try bit_stream_le.readBits(u1, 1, &out_bits));
    try expect(out_bits == 0);
    try expectError(error.EndOfStream, bit_stream_le.readBitsNoEof(u1, 1));
}

pub fn BitWriter(comptime endian: std.builtin.Endian) type {
    return struct {
        writer: *std.Io.Writer,
        bits: u8 = 0,
        count: u4 = 0,

        const low_bit_mask = [9]u8{
            0b00000000,
            0b00000001,
            0b00000011,
            0b00000111,
            0b00001111,
            0b00011111,
            0b00111111,
            0b01111111,
            0b11111111,
        };

        /// Write the specified number of bits to the writer from the least significant bits of
        ///  the specified value. Bits will only be written to the writer when there
        ///  are enough to fill a byte.
        pub fn writeBits(self: *@This(), value: anytype, num: u16) !void {
            const T = @TypeOf(value);
            const UT = std.meta.Int(.unsigned, @bitSizeOf(T));
            const U = if (@bitSizeOf(T) < 8) u8 else UT; //<u8 is a pain to work with

            var in: U = @as(UT, @bitCast(value));
            var in_count: u16 = num;

            if (self.count > 0) {
                //if we can't fill the buffer, add what we have
                const bits_free = 8 - self.count;
                if (num < bits_free) {
                    self.addBits(@truncate(in), @intCast(num));
                    return;
                }

                //finish filling the buffer and flush it
                if (num == bits_free) {
                    self.addBits(@truncate(in), @intCast(num));
                    return self.flushBits();
                }

                switch (endian) {
                    .big => {
                        const bits = in >> @intCast(in_count - bits_free);
                        self.addBits(@truncate(bits), bits_free);
                    },
                    .little => {
                        self.addBits(@truncate(in), bits_free);
                        in >>= @intCast(bits_free);
                    },
                }
                in_count -= bits_free;
                try self.flushBits();
            }

            //write full bytes while we can
            const full_bytes_left = in_count / 8;
            for (0..full_bytes_left) |_| {
                switch (endian) {
                    .big => {
                        const bits = in >> @intCast(in_count - 8);
                        try self.writer.writeByte(@truncate(bits));
                    },
                    .little => {
                        try self.writer.writeByte(@truncate(in));
                        if (U == u8) in = 0 else in >>= 8;
                    },
                }
                in_count -= 8;
            }

            //save the remaining bits in the buffer
            self.addBits(@truncate(in), @intCast(in_count));
        }

        //convenience funciton for adding bits to the buffer
        //in the appropriate position based on endianess
        fn addBits(self: *@This(), bits: u8, num: u4) void {
            if (num == 8) self.bits = bits else switch (endian) {
                .big => {
                    self.bits <<= @intCast(num);
                    self.bits |= bits & low_bit_mask[num];
                },
                .little => {
                    const pos = bits << @intCast(self.count);
                    self.bits |= pos;
                },
            }
            self.count += num;
        }

        /// Flush any remaining bits to the writer, filling
        /// unused bits with 0s.
        pub fn flushBits(self: *@This()) !void {
            if (self.count == 0) return;
            if (endian == .big) self.bits <<= @intCast(8 - self.count);
            try self.writer.writeByte(self.bits);
            self.bits = 0;
            self.count = 0;
        }
    };
}

test "BitWriter: api coverage" {
    var mem_be = [_]u8{0} ** 2;
    var mem_le = [_]u8{0} ** 2;

    var mem_out_be = std.Io.Writer.fixed(mem_be[0..]);
    var bit_stream_be: BitWriter(.big) = .{
        .writer = &mem_out_be,
    };

    const testing = std.testing;

    try bit_stream_be.writeBits(@as(u2, 1), 1);
    try bit_stream_be.writeBits(@as(u5, 2), 2);
    try bit_stream_be.writeBits(@as(u128, 3), 3);
    try bit_stream_be.writeBits(@as(u8, 4), 4);
    try bit_stream_be.writeBits(@as(u9, 5), 5);
    try bit_stream_be.writeBits(@as(u1, 1), 1);

    try testing.expect(mem_be[0] == 0b11001101 and mem_be[1] == 0b00001011);

    mem_out_be.end = 0;

    try bit_stream_be.writeBits(@as(u15, 0b110011010000101), 15);
    try bit_stream_be.flushBits();
    try testing.expect(mem_be[0] == 0b11001101 and mem_be[1] == 0b00001010);

    mem_out_be.end = 0;
    try bit_stream_be.writeBits(@as(u32, 0b110011010000101), 16);
    try testing.expect(mem_be[0] == 0b01100110 and mem_be[1] == 0b10000101);

    try bit_stream_be.writeBits(@as(u0, 0), 0);

    var mem_out_le = std.Io.Writer.fixed(mem_le[0..]);
    var bit_stream_le: BitWriter(.little) = .{
        .writer = &mem_out_le,
    };

    try bit_stream_le.writeBits(@as(u2, 1), 1);
    try bit_stream_le.writeBits(@as(u5, 2), 2);
    try bit_stream_le.writeBits(@as(u128, 3), 3);
    try bit_stream_le.writeBits(@as(u8, 4), 4);
    try bit_stream_le.writeBits(@as(u9, 5), 5);
    try bit_stream_le.writeBits(@as(u1, 1), 1);

    try testing.expect(mem_le[0] == 0b00011101 and mem_le[1] == 0b10010101);

    mem_out_le.end = 0;
    try bit_stream_le.writeBits(@as(u15, 0b110011010000101), 15);
    try bit_stream_le.flushBits();
    try testing.expect(mem_le[0] == 0b10000101 and mem_le[1] == 0b01100110);

    mem_out_le.end = 0;
    try bit_stream_le.writeBits(@as(u32, 0b1100110100001011), 16);
    try testing.expect(mem_le[0] == 0b00001011 and mem_le[1] == 0b11001101);

    try bit_stream_le.writeBits(@as(u0, 0), 0);
}
