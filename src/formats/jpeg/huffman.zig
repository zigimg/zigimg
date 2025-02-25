//! This module contains implementation of huffman table encodings
//! as specified by section 2.4.2 in t-81 1992

const std = @import("std");
const Allocator = std.mem.Allocator;

const buffered_stream_source = @import("../../buffered_stream_source.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const HuffmanCode = struct { length_minus_one: u4, code: u16 };
const HuffmanCodeMap = std.AutoArrayHashMap(HuffmanCode, u8);

const JPEG_DEBUG = false;
const JPEG_VERY_DEBUG = false;

const fast_bits = 9;

pub const Table = struct {
    const Self = @This();

    allocator: Allocator,

    code_counts: [16]u8,
    code_map: HuffmanCodeMap,
    fast_table: [1 << fast_bits]u8,
    fast_size: [1 << fast_bits]u5,

    table_class: u8,

    pub fn read(allocator: Allocator, table_class: u8, reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!Self {
        if (table_class & 1 != table_class)
            return ImageReadError.InvalidData;

        var code_counts: [16]u8 = undefined;
        if ((try reader.readAll(code_counts[0..])) < 16) {
            return ImageReadError.InvalidData;
        }

        if (JPEG_DEBUG) std.debug.print("  Code counts: {any}\n", .{code_counts});

        var total_huffman_codes: usize = 0;
        for (code_counts) |count| total_huffman_codes += count;

        var huffman_code_map = HuffmanCodeMap.init(allocator);
        errdefer huffman_code_map.deinit();

        var fast_table: [1 << fast_bits]u8 = @splat(255);
        var fast_size: [1 << fast_bits]u5 = @splat(0);

        if (JPEG_VERY_DEBUG) std.debug.print("  Decoded huffman codes map:\n", .{});

        var code: u16 = 0;
        for (code_counts, 0..) |count, i| {
            if (JPEG_VERY_DEBUG) {
                std.debug.print("    Length {}: ", .{i + 1});
                if (count == 0) {
                    std.debug.print("(none)\n", .{});
                } else {
                    std.debug.print("\n", .{});
                }
            }

            var j: usize = 0;
            while (j < count) : (j += 1) {
                // Check if we hit all 1s, i.e. 111111 for i == 6, which is an invalid value
                if (code == (@as(u17, @intCast(1)) << (@as(u5, @intCast(i)) + 1)) - 1) {
                    return ImageReadError.InvalidData;
                }

                const byte = try reader.readByte();
                try huffman_code_map.put(.{ .length_minus_one = @as(u4, @intCast(i)), .code = code }, byte);

                // construct accelaration structure see stb_image
                if (i + 1 <= fast_bits) {
                    const first_index = code << fast_bits - @as(u4, @intCast(i + 1));
                    const num_indexes = @as(usize, 1) << @as(u4, @intCast(fast_bits - (i + 1)));
                    for (0..num_indexes) |index| {
                        std.debug.assert(fast_table[first_index + index] == 255);
                        fast_table[first_index + index] = byte;
                        fast_size[first_index + index] = @as(u5, @intCast(i + 1));
                    }
                }

                if (JPEG_VERY_DEBUG) std.debug.print("      {b} => 0x{X}\n", .{ code, byte });
                code += 1;
            }

            code <<= 1;
        }

        return Self{
            .allocator = allocator,
            .code_counts = code_counts,
            .code_map = huffman_code_map,
            .fast_table = fast_table,
            .fast_size = fast_size,
            .table_class = table_class,
        };
    }

    pub fn deinit(self: *Self) void {
        self.code_map.deinit();
    }
};

pub const Reader = struct {
    const Self = @This();

    table: ?*const Table = null,
    reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader,
    stream: *buffered_stream_source.DefaultBufferedStreamSourceReader,
    bit_buffer: u32 = 0,
    bit_count: u5 = 0,

    pub fn init(stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) Self {
        return .{
            .reader = stream.reader(),
            .stream = stream,
        };
    }

    pub fn setHuffmanTable(self: *Self, table: *const Table) void {
        self.table = table;
    }

    pub fn peekBits(self: *Self, num_bits: u5) ImageReadError!u32 {
        if (num_bits > 16) {
            return ImageReadError.InvalidData;
        }

        try self.fillBits(num_bits);

        return (self.bit_buffer >> 1) >> (31 - num_bits);
    }

    pub fn fillBits(self: *Self, num_bits: u5) ImageReadError!void {
        while (self.bit_count < num_bits) {
            var byte_curr: u32 = try self.reader.readByte();

            while (byte_curr == 0xFF) {
                const byte_next: u8 = try self.reader.readByte();

                if (byte_next == 0x00) {
                    break;
                } else if (byte_next == 0xFF) {
                    continue;
                } else if (byte_next >= 0xD0 and byte_next <= 0xD7) {
                    byte_curr = try self.reader.readByte();
                } else {
                    try self.stream.seekBy(-2);
                    return ImageReadError.InvalidData;
                }
            }

            self.bit_buffer |= byte_curr << (24 - self.bit_count);
            self.bit_count += 8;
        }
    }

    pub fn consumeBits(self: *Self, num_bits: u5) void {
        std.debug.assert(num_bits <= self.bit_count and num_bits <= 16);

        self.bit_buffer <<= num_bits;
        self.bit_count -= num_bits;
    }

    pub fn readBits(self: *Self, num_bits: u5) ImageReadError!u32 {
        const bits: u32 = try peekBits(self, num_bits);
        consumeBits(self, num_bits);
        return bits;
    }

    pub fn flushBits(self: *Self) void {
        if (self.bit_count > 8 and self.bit_count % 8 != 0) {
            const bits_to_flush: u5 = self.bit_count % 8;
            self.bit_buffer <<= bits_to_flush;
            self.bit_count = self.bit_count - bits_to_flush;
        } else if (self.bit_count % 8 == 0) {
            return;
        } else if (self.bit_count < 8) {
            self.bit_buffer = 0;
            self.bit_count = 0;
        } else {
            unreachable;
        }
    }

    pub fn readCode(self: *Self) ImageReadError!u8 {
        const fast_index = self.peekBits(fast_bits) catch 0;

        if (self.bit_count >= fast_bits) {
            const value = self.table.?.fast_table[fast_index];
            if (value != 255) {
                const length = self.table.?.fast_size[fast_index];
                self.consumeBits(length);
                return value;
            }
        }

        var code: u32 = 0;

        var length: u5 = if (self.bit_count < fast_bits) 1 else fast_bits + 1;
        while (length <= 16) : (length += 1) {
            code = try self.peekBits(length);
            if (self.table.?.code_map.get(.{ .length_minus_one = @intCast(length - 1), .code = @intCast(code) })) |value| {
                self.consumeBits(length);
                return value;
            }
        }

        if (JPEG_DEBUG) std.debug.print("found unknown code: {x}\n", .{code});
        return ImageReadError.InvalidData;
    }

    /// This function implements T.81 section F1.2.1, Huffman encoding of DC coefficients.
    pub fn readMagnitudeCoded(self: *Self, magnitude: u5) ImageReadError!i32 {
        if (magnitude == 0)
            return 0;

        var coeff: i32 = @intCast(try self.peekBits(magnitude));
        self.consumeBits(magnitude);

        if (coeff < @as(i32, 1) << (magnitude - 1)) {
            coeff -= (@as(i32, 1) << magnitude) - 1;
        }

        return coeff;
    }
};
