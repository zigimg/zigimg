// Implement DEFLATE compression (RFC 1951)
const std = @import("std");
const io = std.io;
const huffman = @import("huffman.zig");
const Allocator = std.mem.Allocator;

pub const CompressionType = packed enum(u2) {
    NoCompression,
    FixedHuffman,
    DynamicHuffman,
    Reserved,
};

pub const FixedHuffmanLiteralLengthTable = comptime blk: {
    var result: [288]u8 = undefined;
    var index: usize = 0;

    while (index <= 143) : (index += 1) {
        result[index] = 8;
    }

    while (index <= 255) : (index += 1) {
        result[index] = 9;
    }

    while (index <= 279) : (index += 1) {
        result[index] = 7;
    }

    while (index <= 287) : (index += 1) {
        result[index] = 8;
    }

    break :blk result;
};

pub const FixedHuffmanDistanceLengthTable = comptime blk: {
    var result: [32]u8 = undefined;

    var index: usize = 0;

    while (index < 32) : (index += 1) {
        result[index] = 5;
    }

    break :blk result;
};

const LiteralLengthMin = 257;
const LiteralLengthMax = 288;
const LiteralLengthTableOffset = 257;

const LiteralEndOfBlock = 256;

const DistanceLengthMin = 1;
const DistanceLengthMax = 32;
const DistanceSymbolMax = 29;

const CodeLengthMin = 4;
const CodeLengthMax = 19;

const CodeLengthLiteralMax = 15;

const CodeLengthCopyPrevious = 16;
const CodeLengthCopyPreviousMin = 3;

const CodeLengthRepeat3_10 = 17;
const CodeLengthRepeat3_10_Min = 3;

const CodeLengthRepeat11_138 = 18;
const CodeLengthRepeat11_138_Min = 11;

// RFC 1951 Section 3.2.7
const CodeLengthOrders = [_]usize{ 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 };

const LiteralLengthEntry = packed struct {
    base_length: u9,
    extra_bits: u7,
};

const LiteralLengthTable = [_]LiteralLengthEntry{
    .{ .base_length = 3, .extra_bits = 0 },
    .{ .base_length = 4, .extra_bits = 0 },
    .{ .base_length = 5, .extra_bits = 0 },
    .{ .base_length = 6, .extra_bits = 0 },
    .{ .base_length = 7, .extra_bits = 0 },
    .{ .base_length = 8, .extra_bits = 0 },
    .{ .base_length = 9, .extra_bits = 0 },
    .{ .base_length = 10, .extra_bits = 0 },
    .{ .base_length = 11, .extra_bits = 1 },
    .{ .base_length = 13, .extra_bits = 1 },
    .{ .base_length = 15, .extra_bits = 1 },
    .{ .base_length = 17, .extra_bits = 1 },
    .{ .base_length = 19, .extra_bits = 2 },
    .{ .base_length = 23, .extra_bits = 2 },
    .{ .base_length = 27, .extra_bits = 2 },
    .{ .base_length = 31, .extra_bits = 2 },
    .{ .base_length = 35, .extra_bits = 3 },
    .{ .base_length = 43, .extra_bits = 3 },
    .{ .base_length = 51, .extra_bits = 3 },
    .{ .base_length = 59, .extra_bits = 3 },
    .{ .base_length = 67, .extra_bits = 4 },
    .{ .base_length = 83, .extra_bits = 4 },
    .{ .base_length = 99, .extra_bits = 4 },
    .{ .base_length = 115, .extra_bits = 4 },
    .{ .base_length = 131, .extra_bits = 5 },
    .{ .base_length = 163, .extra_bits = 5 },
    .{ .base_length = 195, .extra_bits = 5 },
    .{ .base_length = 227, .extra_bits = 5 },
    .{ .base_length = 258, .extra_bits = 0 },
};

const DistanceEntry = packed struct {
    base_distance: u16,
    extra_bits: u4,
};

const DistanceTable = [_]DistanceEntry{
    .{ .base_distance = 1, .extra_bits = 0 },
    .{ .base_distance = 2, .extra_bits = 0 },
    .{ .base_distance = 3, .extra_bits = 0 },
    .{ .base_distance = 4, .extra_bits = 0 },
    .{ .base_distance = 5, .extra_bits = 1 },
    .{ .base_distance = 7, .extra_bits = 1 },
    .{ .base_distance = 9, .extra_bits = 2 },
    .{ .base_distance = 13, .extra_bits = 2 },
    .{ .base_distance = 17, .extra_bits = 3 },
    .{ .base_distance = 25, .extra_bits = 3 },
    .{ .base_distance = 33, .extra_bits = 4 },
    .{ .base_distance = 49, .extra_bits = 4 },
    .{ .base_distance = 65, .extra_bits = 5 },
    .{ .base_distance = 97, .extra_bits = 5 },
    .{ .base_distance = 129, .extra_bits = 6 },
    .{ .base_distance = 193, .extra_bits = 6 },
    .{ .base_distance = 257, .extra_bits = 7 },
    .{ .base_distance = 385, .extra_bits = 7 },
    .{ .base_distance = 513, .extra_bits = 8 },
    .{ .base_distance = 769, .extra_bits = 8 },
    .{ .base_distance = 1025, .extra_bits = 9 },
    .{ .base_distance = 1537, .extra_bits = 9 },
    .{ .base_distance = 2049, .extra_bits = 10 },
    .{ .base_distance = 3073, .extra_bits = 10 },
    .{ .base_distance = 4097, .extra_bits = 11 },
    .{ .base_distance = 6145, .extra_bits = 11 },
    .{ .base_distance = 8193, .extra_bits = 12 },
    .{ .base_distance = 12289, .extra_bits = 12 },
    .{ .base_distance = 16385, .extra_bits = 13 },
    .{ .base_distance = 24577, .extra_bits = 13 },
};

const DeflateBitInStream = struct {
    buffer: []const u8,
    bit_position: usize,
    bit_position_end: usize,

    const Self = @This();

    pub fn init(buffer: []const u8) Self {
        return Self{
            .buffer = buffer,
            .bit_position = 0,
            .bit_position_end = buffer.len * 8,
        };
    }

    pub fn peek(self: Self) !usize {
        const read_index = self.bit_position / 8;

        var data: usize = 0;

        const remaining = self.buffer.len - read_index;

        if (remaining >= @sizeOf(usize)) {
            data = std.mem.readIntLittle(usize, @ptrCast(*const [@sizeOf(usize)]u8, &self.buffer[read_index]));
        } else {
            data = 0;
            var i: usize = 0;
            while (i < remaining) : (i += 1) {
                data |= @intCast(usize, self.buffer[read_index + i]) << @truncate(u6, i * 8);
            }
        }

        return data >> @intCast(u6, self.bit_position % 8);
    }

    pub fn peekBits(self: Self, comptime int_type: type) !int_type {
        const bit_size = @bitSizeOf(int_type);

        const data = try self.peek();

        return @truncate(int_type, data & ((1 << bit_size) - 1));
    }

    pub fn readBits(self: *Self, comptime int_type: type) !int_type {
        const bit_size = @bitSizeOf(int_type);

        var result = try self.peekBits(int_type);

        try self.advance(bit_size);

        return result;
    }

    pub fn advance(self: *Self, steps: usize) !void {
        if (self.bit_position + steps > self.bit_position_end) {
            return error.EndOfStream;
        }

        self.bit_position += steps;
    }

    pub fn alignToByte(self: *Self) ![]const u8 {
        if (self.bit_position > self.bit_position_end) {
            return error.EndOfStream;
        }

        self.bit_position = std.mem.alignForward(self.bit_position, 8);

        return self.buffer[(self.bit_position / 8)..];
    }
};

const DeflateOutStream = struct {
    out_buffer: []u8,
    position: *usize,

    const Self = @This();

    pub fn init(buffer: []u8, position: *usize) Self {
        return Self{
            .out_buffer = buffer,
            .position = position,
        };
    }

    pub fn writeAll(self: *Self, buffer: []const u8) !void {
        if ((self.position.* + buffer.len) >= self.out_buffer.len) {
            return error.OutOfBounds;
        }

        std.mem.copy(u8, self.out_buffer[self.position.*..], buffer);
        self.position.* += buffer.len;
    }

    pub fn writeByte(self: *Self, value: u8) !void {
        if ((self.position.* + 1) >= self.out_buffer.len) {
            return error.OutOfBounds;
        }

        self.out_buffer[self.position.*] = value;
        self.position.* += 1;
    }

    pub fn outputReference(self: *Self, distance: usize, length: usize) void {
        if (length > distance or length < 8) {
            var times: usize = 0;
            while (times < length) : (times += 1) {
                self.out_buffer[self.position.*] = self.out_buffer[self.position.* - distance];
                self.position.* += 1;
            }
        } else {
            const numWords = length / @sizeOf(usize);
            const remaining = length % @sizeOf(usize);

            var count: usize = 0;
            while (count < numWords) : (count += 1) {
                const offset = count * @sizeOf(usize);
                const readWord = std.mem.readIntNative(usize, @ptrCast(*const [@sizeOf(usize)]u8, &self.out_buffer[self.position.* - distance + offset]));
                std.mem.writeIntNative(usize, @ptrCast(*[@sizeOf(usize)]u8, &self.out_buffer[self.position.* + offset]), readWord);
            }

            self.position.* += (count * @sizeOf(usize));

            var times: usize = 0;
            while (times < remaining) : (times += 1) {
                self.out_buffer[self.position.*] = self.out_buffer[self.position.* - distance];
                self.position.* += 1;
            }
        }
    }
};

pub const DeflateDecompressor = struct {
    allocator: *Allocator,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit() void {}

    pub fn read(self: *Self, in_buffer: []const u8, in_position: *usize, out_buffer: []u8, out_position: *usize) !void {
        var bit_stream = DeflateBitInStream.init(in_buffer);
        var out_stream = DeflateOutStream.init(out_buffer, out_position);

        var bfinal = false;

        while (!bfinal) {
            bfinal = (try bit_stream.readBits(u1)) == 1;
            const raw_type = try bit_stream.readBits(u2);
            const btype = @intToEnum(CompressionType, raw_type);

            switch (btype) {
                .NoCompression => {
                    try self.readNoCompression(&bit_stream, &out_stream);
                },
                .FixedHuffman => {
                    try self.readFixedHuffman(&bit_stream, &out_stream);
                },
                .DynamicHuffman => {
                    try self.readDynamicHuffman(&bit_stream, &out_stream);
                },
                .Reserved => {
                    return error.InvalidDeflateBlock;
                },
            }
        }

        _ = try bit_stream.alignToByte();
        in_position.* = bit_stream.bit_position / 8;
    }

    fn readNoCompression(self: *Self, bit_stream: *DeflateBitInStream, out_stream: *DeflateOutStream) !void {
        const current_buffer = try bit_stream.alignToByte();

        const inStream = std.io.fixedBufferStream(current_buffer).inStream();
        const length = try inStream.readIntLittle(u16);
        const complement_length = try inStream.readIntLittle(u16);

        if (complement_length != ~length) {
            return error.DeflateInvalidLength;
        }

        const read_data = try inStream.readAllAlloc(self.allocator, length);
        defer self.allocator.free(read_data);

        try out_stream.writeAll(read_data);
    }

    fn readFixedHuffman(self: *Self, bit_stream: *DeflateBitInStream, out_stream: *DeflateOutStream) !void {
        var literal_decoder = try huffman.Decoder.initFromCodewordLength(FixedHuffmanLiteralLengthTable[0..]);
        var distance_decoder = try huffman.Decoder.initFromCodewordLength(FixedHuffmanDistanceLengthTable[0..]);

        try self.decodeBlock(bit_stream, out_stream, literal_decoder, distance_decoder);
    }

    fn readDynamicHuffman(self: *Self, bit_stream: *DeflateBitInStream, out_stream: *DeflateOutStream) !void {
        const literal_count_bits = try bit_stream.readBits(u5);
        const literal_count = @intCast(usize, literal_count_bits) + 257;

        const distance_count_bits = try bit_stream.readBits(u5);
        const distance_count = @intCast(usize, distance_count_bits) + 1;

        const codelength_count_bits = try bit_stream.readBits(u4);
        const codelength_count = @intCast(usize, codelength_count_bits) + 4;

        var code_lengths: [CodeLengthMax]u8 = undefined;

        var decoded_codes_buffer: [LiteralLengthMax + DistanceLengthMax]u8 = undefined;
        var decoded_codes = decoded_codes_buffer[0..(literal_count + distance_count)];

        // Fill the codelen length table
        var index: usize = 0;
        while (index < codelength_count) : (index += 1) {
            const read_length = try bit_stream.readBits(u3);
            code_lengths[CodeLengthOrders[index]] = @as(u8, read_length);
        }

        while (index < code_lengths.len) : (index += 1) {
            code_lengths[CodeLengthOrders[index]] = 0;
        }

        var code_decoder = try huffman.Decoder.initFromCodewordLength(code_lengths[0..]);

        index = 0;
        while (index < decoded_codes.len) {
            var used_bits: usize = 0;

            var read_bits = try bit_stream.peek();
            const symbol = try code_decoder.decode(@truncate(u16, read_bits), &used_bits);
            try bit_stream.advance(used_bits);

            switch (symbol) {
                0...CodeLengthLiteralMax => {
                    decoded_codes[index] = @intCast(u8, symbol);
                    index += 1;
                },
                CodeLengthCopyPrevious => {
                    if (index < 1) {
                        return error.NoPreviousLength;
                    }

                    var repeat_count = @as(usize, try bit_stream.readBits(u2)) + CodeLengthCopyPreviousMin;

                    if ((index + repeat_count) > decoded_codes.len) {
                        return error.IndexOutOfBounds;
                    }

                    while (repeat_count > 0) : (repeat_count -= 1) {
                        decoded_codes[index] = decoded_codes[index - 1];
                        index += 1;
                    }
                },
                CodeLengthRepeat3_10 => {
                    var repeat_count = @as(usize, try bit_stream.readBits(u3)) + CodeLengthRepeat3_10_Min;

                    if ((index + repeat_count) > decoded_codes.len) {
                        return error.IndexOutOfBounds;
                    }

                    while (repeat_count > 0) : (repeat_count -= 1) {
                        decoded_codes[index] = 0;
                        index += 1;
                    }
                },
                CodeLengthRepeat11_138 => {
                    var repeat_count = @as(usize, try bit_stream.readBits(u7)) + CodeLengthRepeat11_138_Min;

                    if ((index + repeat_count) > decoded_codes.len) {
                        return error.IndexOutOfBounds;
                    }

                    while (repeat_count > 0) : (repeat_count -= 1) {
                        decoded_codes[index] = 0;
                        index += 1;
                    }
                },
                else => {
                    return error.InvalidSymbol;
                },
            }
        }

        var literal_decoder = try huffman.Decoder.initFromCodewordLength(decoded_codes[0..literal_count]);
        var distance_decoder = try huffman.Decoder.initFromCodewordLength(decoded_codes[literal_count..(literal_count + distance_count)]);

        try self.decodeBlock(bit_stream, out_stream, literal_decoder, distance_decoder);
    }

    fn decodeBlock(self: *Self, bit_stream: *DeflateBitInStream, out_stream: *DeflateOutStream, literal_decoder: huffman.Decoder, distance_decoder: huffman.Decoder) !void {
        while (true) {
            var used_bits: usize = 0;
            var total_used: usize = 0;

            var read_bits = try bit_stream.peek();
            const literal = try literal_decoder.decode(@truncate(u16, read_bits), &used_bits);
            read_bits >>= @intCast(u6, used_bits);
            total_used = used_bits;

            if (literal < 0 or literal > LiteralLengthMax) {
                return error.InvalidSymbol;
            } else if (literal <= std.math.maxInt(u8)) {
                // This is a literal
                try out_stream.writeByte(@truncate(u8, literal));
                try bit_stream.advance(used_bits);

                continue;
            } else if (literal == LiteralEndOfBlock) {
                try bit_stream.advance(used_bits);
                break;
            }

            // It's a back reference
            const length_entry = LiteralLengthTable[literal - LiteralLengthTableOffset];
            var reference_length: usize = length_entry.base_length;
            if (length_entry.extra_bits != 0) {
                reference_length += lsb(read_bits, @as(usize, length_entry.extra_bits));
                read_bits >>= @intCast(u6, length_entry.extra_bits);
                total_used += length_entry.extra_bits;
            }

            const distance_symbol = try distance_decoder.decode(@truncate(u16, read_bits), &used_bits);
            read_bits >>= @intCast(u6, used_bits);
            total_used += used_bits;

            if (distance_symbol < 0 or distance_symbol > DistanceSymbolMax) {
                return error.InvalidDistance;
            }

            const distance_entry = DistanceTable[distance_symbol];
            var reference_distance: usize = distance_entry.base_distance;
            if (distance_entry.extra_bits != 0) {
                reference_distance += lsb(read_bits, distance_entry.extra_bits);
                read_bits >>= distance_entry.extra_bits;
                total_used += distance_entry.extra_bits;
            }

            try bit_stream.advance(total_used);

            out_stream.outputReference(reference_distance, reference_length);
        }
    }

    inline fn lsb(input: usize, bits: usize) usize {
        return input & ((@as(usize, 1) << @intCast(u6, bits)) - 1);
    }
};
