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

pub const DeflateDecompressor = struct {
    allocator: *Allocator,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return Self {
            .allocator = allocator,
        };
    }

    pub fn deinit() void {
    }

    pub fn read(self: *Self, in_stream: var, out_stream: var) !void {
        var bit_stream = io.bitInStream(std.builtin.Endian.Little, in_stream);

        var read_bits: usize = 0;

        const bfinal = (try bit_stream.readBits(u1, 1, &read_bits)) == 1;
        const raw_type = try bit_stream.readBits(u2, 2, &read_bits);
        const btype = @intToEnum(CompressionType, raw_type);

        std.debug.warn("bfinal={}, btype={}\n", .{bfinal, btype});

        switch(btype) {
            .NoCompression => {
                try self.readNoCompression(&bit_stream, out_stream);
            },
            .FixedHuffman => {
                try self.readFixedHuffman(&bit_stream, out_stream);
            },
            .DynamicHuffman => {
                try self.readDynamicHuffman(&bit_stream, out_stream);
            },
            .Reserved => {
                return error.InvalidDeflateBlock;
            },
        }
    }

    fn readNoCompression(self: *Self, bit_stream: var, out_stream: var) !void {
        bit_stream.alignToByte();

        const inStream = bit_stream.inStream();
        const length = try inStream.readIntLittle(u16);
        const complement_length = try inStream.readIntLittle(u16);

        if (complement_length != ~length) {
            return error.DeflateInvalidLength;
        }

        const read_data = try inStream.readAllAlloc(self.allocator, length);
        defer self.allocator.free(read_data);

        try out_stream.writeAll(read_data);
    }

    fn readFixedHuffman(self: *Self, bit_stream: var, out_stream: var) !void {

    }

    fn readDynamicHuffman(self: *Self, bit_stream: var, out_stream: var) !void {
        var read_bits: usize = 0;

        const literal_count = try bit_stream.readBits(u5, 5, &read_bits);
        const distance_count = try bit_stream.readBits(u5, 5, &read_bits);
        const codelength_count = try bit_stream.readBits(u4, 4, &read_bits);

        std.debug.warn("literal_count={}, distance_count={}, codelength_count={}\n", .{literal_count, distance_count, codelength_count});
    }
};
