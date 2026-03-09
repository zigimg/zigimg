const color = @import("../color.zig");
const compressions = @import("../compressions.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const std = @import("std");
const utils = @import("../utils.zig");

const toU5 = color.ScaleValue(u5);
const toU8 = color.ScaleValue(u8);

pub const TGAImageType = packed struct(u8) {
    indexed: bool = false,
    truecolor: bool = false,
    pad0: bool = false,
    run_length: bool = false,
    pad1: u4 = 0,
};

pub const TGAColorMapSpec = extern struct {
    first_entry_index: u16 align(1) = 0,
    length: u16 align(1) = 0,
    bit_depth: u8 align(1) = 0,
};

pub const TGADescriptor = packed struct(u8) {
    num_attributes_bit: u4 = 0,
    right_to_left: bool = false,
    top_to_bottom: bool = false,
    pad: u2 = 0,
};

pub const TGAImageSpec = extern struct {
    origin_x: u16 align(1) = 0,
    origin_y: u16 align(1) = 0,
    width: u16 align(1) = 0,
    height: u16 align(1) = 0,
    bit_per_pixel: u8 align(1) = 0,
    descriptor: TGADescriptor align(1) = .{},
};

pub const TGAHeader = extern struct {
    id_length: u8 align(1) = 0,
    has_color_map: u8 align(1) = 0,
    image_type: TGAImageType align(1) = .{},
    color_map_spec: TGAColorMapSpec align(1) = .{},
    image_spec: TGAImageSpec align(1) = .{},

    pub fn isValid(self: TGAHeader) bool {
        if (self.has_color_map != 0 and self.has_color_map != 1) {
            return false;
        }

        if (self.image_type.pad0) {
            return false;
        }

        if (self.image_type.pad1 != 0) {
            return false;
        }

        switch (self.color_map_spec.bit_depth) {
            0, 15, 16, 24, 32 => {},
            else => {
                return false;
            },
        }

        return true;
    }
};

pub const TGAExtensionComment = extern struct {
    lines: [4][80:0]u8 = @splat(@splat(0)),
};

pub const TGAExtensionSoftwareVersion = extern struct {
    number: u16 align(1) = 0,
    letter: u8 align(1) = ' ',
};

pub const TGAExtensionTimestamp = extern struct {
    month: u16 align(1) = 0,
    day: u16 align(1) = 0,
    year: u16 align(1) = 0,
    hour: u16 align(1) = 0,
    minute: u16 align(1) = 0,
    second: u16 align(1) = 0,
};

pub const TGAExtensionJobTime = extern struct {
    hours: u16 align(1) = 0,
    minutes: u16 align(1) = 0,
    seconds: u16 align(1) = 0,
};

pub const TGAExtensionRatio = extern struct {
    numerator: u16 align(1) = 0,
    denominator: u16 align(1) = 0,
};

pub const TGAAttributeType = enum(u8) {
    no_alpha = 0,
    undefined_alpha_ignore = 1,
    undefined_alpha_retained = 2,
    useful_alpha_channel = 3,
    premultipled_alpha = 4,
};

pub const TGAExtension = extern struct {
    extension_size: u16 align(1) = @sizeOf(TGAExtension),
    author_name: [40:0]u8 align(1) = @splat(0),
    author_comment: TGAExtensionComment align(1) = .{},
    timestamp: TGAExtensionTimestamp align(1) = .{},
    job_id: [40:0]u8 align(1) = @splat(0),
    job_time: TGAExtensionJobTime align(1) = .{},
    software_id: [40:0]u8 align(1) = @splat(0),
    software_version: TGAExtensionSoftwareVersion align(1) = .{},
    key_color: color.Bgra32 align(1) = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    pixel_aspect: TGAExtensionRatio align(1) = .{},
    gamma_value: TGAExtensionRatio align(1) = .{},
    color_correction_offset: u32 align(1) = 0,
    postage_stamp_offset: u32 align(1) = 0,
    scanline_offset: u32 align(1) = 0,
    attributes: TGAAttributeType align(1) = .no_alpha,
};

pub const TGAFooter = extern struct {
    extension_offset: u32 align(1) = 0,
    dev_area_offset: u32 align(1) = 0,
    signature: [16]u8 align(1) = undefined,
    dot: u8 align(1) = '.',
    null_value: u8 align(1) = 0,
};

pub const TGASignature = "TRUEVISION-XFILE";

comptime {
    std.debug.assert(@sizeOf(TGAHeader) == 18);
    std.debug.assert(@sizeOf(TGAExtension) == 495);
}

const RLEPacketType = enum(u1) {
    raw = 0,
    repeated = 1,
};

const RLEPacketHeader = packed struct {
    count: u7,
    packet_type: RLEPacketType,
};

const TargaRLEDecoder = struct {
    source_reader: *std.Io.Reader,

    allocator: std.mem.Allocator,
    bytes_per_pixel: usize,

    state: State = .read_header,
    repeat_count: usize = 0,
    repeat_data: []u8 = undefined,
    wrote_repeat_data: usize = 0,

    reader: std.Io.Reader,

    const State = enum {
        read_header,
        repeated,
        raw,
    };

    const vtable: std.Io.Reader.VTable = .{
        .stream = stream,
    };

    pub fn init(allocator: std.mem.Allocator, source_reader: *std.Io.Reader, bytes_per_pixels: usize, decompress_buffer: []u8) !TargaRLEDecoder {
        var result = TargaRLEDecoder{
            .allocator = allocator,
            .source_reader = source_reader,
            .bytes_per_pixel = bytes_per_pixels,
            .reader = .{
                .vtable = &vtable,
                .buffer = decompress_buffer,
                .seek = 0,
                .end = 0,
            },
        };

        result.repeat_data = try allocator.alloc(u8, bytes_per_pixels);
        return result;
    }

    pub fn deinit(self: TargaRLEDecoder) void {
        self.allocator.free(self.repeat_data);
    }

    // Reader interface
    fn stream(reader: *std.Io.Reader, writer: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        const self: *TargaRLEDecoder = @alignCast(@fieldParentPtr("reader", reader));

        var remaining: usize = @intFromEnum(limit);

        state_machine: switch (self.state) {
            .read_header => {
                const packet_header = try self.source_reader.takeStruct(RLEPacketHeader, .little);

                switch (packet_header.packet_type) {
                    .repeated => {
                        self.state = .repeated;
                        self.repeat_count = @as(usize, @intCast(packet_header.count)) + 1;
                        try self.source_reader.readSliceAll(self.repeat_data);

                        continue :state_machine .repeated;
                    },
                    .raw => {
                        self.state = .raw;
                        self.repeat_count = (@as(usize, @intCast(packet_header.count)) + 1) * self.bytes_per_pixel;

                        continue :state_machine .raw;
                    },
                }
            },
            .raw => {
                if (self.repeat_count > 0) {
                    const read_count = try self.source_reader.stream(writer, .min(.limited(remaining), .limited(self.repeat_count)));
                    self.repeat_count -|= read_count;
                    remaining -|= read_count;
                    if (self.repeat_count == 0 and remaining > 0) {
                        self.state = .read_header;
                        continue :state_machine .read_header;
                    } else {
                        return @intFromEnum(limit) - remaining;
                    }
                } else {
                    self.state = .read_header;
                    continue :state_machine .read_header;
                }
            },
            .repeated => {
                if (self.wrote_repeat_data > 0 and self.wrote_repeat_data < self.repeat_data.len) {
                    const to_write = @min(self.repeat_data.len - self.wrote_repeat_data, remaining);
                    const written = try writer.write(self.repeat_data[self.wrote_repeat_data..(self.wrote_repeat_data + to_write)]);
                    remaining -|= written;

                    if ((self.wrote_repeat_data + written) == self.repeat_data.len) {
                        self.wrote_repeat_data = 0;
                        self.repeat_count -|= 1;
                    } else {
                        self.wrote_repeat_data += written;
                    }
                } else {
                    const repeat_byte_size = self.repeat_count * self.repeat_data.len;
                    const effective_repeat_count = if (remaining > repeat_byte_size) self.repeat_count else @min(remaining / self.repeat_data.len, self.repeat_count);
                    const repeated_byte_count = try writer.writeSplat(&.{self.repeat_data}, effective_repeat_count);
                    if (repeated_byte_count > 0) {
                        self.repeat_count -|= repeated_byte_count / self.repeat_data.len;
                        remaining -|= repeated_byte_count;
                    } else {
                        const to_write = @min(self.repeat_data.len - self.wrote_repeat_data, remaining);
                        const written = try writer.write(self.repeat_data[self.wrote_repeat_data..(self.wrote_repeat_data + to_write)]);
                        remaining -|= written;

                        if ((self.wrote_repeat_data + written) == self.repeat_data.len) {
                            self.wrote_repeat_data = 0;
                            self.repeat_count -|= 1;
                        } else {
                            self.wrote_repeat_data += written;
                        }
                    }
                }

                if (self.repeat_count == 0) {
                    self.state = .read_header;
                }

                if (remaining > 0) {
                    if (self.state == .read_header) {
                        continue :state_machine .read_header;
                    } else if (self.state == .repeated) {
                        continue :state_machine .repeated;
                    }
                } else {
                    return @intFromEnum(limit) - remaining;
                }
            },
        }

        return 0;
    }
};

const RLE_MAXIMUM_LENGTH = 1 << 7;

const TargaRlePacketFormatter = struct {
    pub fn flushRLE(comptime IntType: type, writer: *std.Io.Writer, value: IntType, count: usize) !void {
        const rle_packet_header = RLEPacketHeader{
            .count = @truncate(count - 1),
            .packet_type = .repeated,
        };
        try writer.writeByte(@bitCast(rle_packet_header));
        try writer.writeInt(IntType, value, .little);
    }

    pub fn flushRaw(comptime IntType: type, writer: *std.Io.Writer, slice: []const IntType) !void {
        const rle_packet_header = RLEPacketHeader{
            .count = @truncate(slice.len - 1),
            .packet_type = .raw,
        };
        try writer.writeByte(@bitCast(rle_packet_header));

        for (slice) |entry| {
            try writer.writeInt(IntType, entry, .little);
        }
    }
};

fn RleStreamEncoder(comptime IntType: type) type {
    return compressions.rle.Compressor(.{
        .IntType = IntType,
        .PacketFormatterType = TargaRlePacketFormatter,
        .maximum_length = RLE_MAXIMUM_LENGTH,
    }).StreamEncoder;
}

fn RLEStreamColorEncoder(comptime ColorType: type) type {
    return struct {
        encoder: RleStreamEncoder(IntType) = .{},

        const IntType = switch (ColorType) {
            color.Bgr24 => u24,
            color.Bgra32 => u32,
            else => @compileError("Not supported color format"),
        };

        const Self = @This();

        pub fn encode(self: *Self, writer: *std.Io.Writer, value: ColorType) std.Io.Writer.Error!void {
            return self.encoder.encode(writer, @as(IntType, @bitCast(value)));
        }

        pub fn flush(self: *Self, writer: *std.Io.Writer) !void {
            return self.encoder.flush(writer);
        }
    };
}

test "TGA RLE Stream Color Encoder: Produce optimal raw packets (Bgr24)" {
    const colors = @import("../predefined_colors.zig");
    const WHITE = colors.Colors(color.Bgr24).White;
    const BLACK = colors.Colors(color.Bgr24).Black;
    const RED = colors.Colors(color.Bgr24).Red;
    const GREEN = colors.Colors(color.Bgr24).Green;
    const BLUE = colors.Colors(color.Bgr24).Blue;

    const UNCOMPRESSED_DATA = [_]color.Bgr24{ RED, GREEN, BLUE, RED, GREEN, BLUE, WHITE, WHITE, WHITE, WHITE, RED, GREEN, BLUE, BLACK };
    const COMPRESSED_DATA = [_]u8{ 0x05, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x83, 0xFF, 0xFF, 0xFF, 0x03, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00 };

    var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer allocating_writer.deinit();

    const writer = &allocating_writer.writer;

    var stream_encoder: RLEStreamColorEncoder(color.Bgr24) = .{};

    for (UNCOMPRESSED_DATA) |entry| {
        try stream_encoder.encode(writer, entry);
    }

    try stream_encoder.flush(writer);

    try std.testing.expectEqualSlices(u8, &COMPRESSED_DATA, allocating_writer.written());
}

fn RunLengthSimpleEncoder(comptime IntType: type) type {
    return compressions.rle.Compressor(.{
        .IntType = IntType,
        .PacketFormatterType = TargaRlePacketFormatter,
        .maximum_length = RLE_MAXIMUM_LENGTH,
    }).Simple;
}

test "TGA RLE simple u24 encoder" {
    const uncompressed_source = [_]color.Rgb24{
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0xEF, .g = 0xCD, .b = 0xAB },
        .{ .r = 0x1, .g = 0x2, .b = 0x3 },
        .{ .r = 0x4, .g = 0x5, .b = 0x6 },
        .{ .r = 0x7, .g = 0x8, .b = 0x9 },
    };
    const uncompressed_data = std.mem.sliceAsBytes(uncompressed_source[0..]);

    const compressed_data = [_]u8{
        0x87, 0xEF, 0xCD, 0xAB,
        0x02, 0x01, 0x02, 0x03,
        0x04, 0x05, 0x06, 0x07,
        0x08, 0x09,
    };

    var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer allocating_writer.deinit();

    try RunLengthSimpleEncoder(u24).encode(uncompressed_data[0..], &allocating_writer.writer);

    try std.testing.expectEqualSlices(u8, compressed_data[0..], allocating_writer.written());
}

fn RunLengthSIMDEncoder(
    comptime IntType: type,
    comptime optional_parameters: struct {
        vector_length: ?comptime_int = null,
    },
) type {
    return compressions.rle.Compressor(.{
        .IntType = IntType,
        .PacketFormatterType = TargaRlePacketFormatter,
        .maximum_length = RLE_MAXIMUM_LENGTH,
        .vector_length = optional_parameters.vector_length,
    }).Simd;
}

test "TGA RLE SIMD u8 (bytes) encoder" {
    const uncompressed_data = [_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 64, 64, 2, 2, 2, 2, 2, 215, 215, 215, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 200, 200, 200, 200, 210, 210 };
    const compressed_data = [_]u8{ 0x88, 0x01, 0x81, 0x40, 0x84, 0x02, 0x82, 0xD7, 0x89, 0x03, 0x83, 0xC8, 0x81, 0xD2 };

    const Test = struct {
        pub fn do(comptime vector_length: comptime_int) !void {
            var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer allocating_writer.deinit();

            try RunLengthSIMDEncoder(u8, .{ .vector_length = vector_length }).encode(uncompressed_data[0..], &allocating_writer.writer);
            try std.testing.expectEqualSlices(u8, compressed_data[0..], allocating_writer.written());
        }
    };

    try Test.do(4);
    try Test.do(8);
    try Test.do(16);
    try Test.do(32);
}

test "TGA RLE SIMD u8 (bytes) encoder should compress raw data more" {
    const uncompressed_data = [_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 64, 64, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const compressed_data = [_]u8{ 0x88, 0x01, 0x81, 0x40, 0x0F, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x10 };

    const Test = struct {
        pub fn do(comptime vector_length: comptime_int) !void {
            var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer allocating_writer.deinit();

            try RunLengthSIMDEncoder(u8, .{ .vector_length = vector_length }).encode(uncompressed_data[0..], &allocating_writer.writer);
            try std.testing.expectEqualSlices(u8, compressed_data[0..], allocating_writer.written());
        }
    };

    try Test.do(4);
    try Test.do(8);
    try Test.do(16);
    try Test.do(32);
}

test "TGA RLE SIMD u8 (bytes) encoder should encore more than 128 bytes similar" {
    const first_uncompressed_part: [135]u8 = @splat(0x45);
    const second_uncompresse_part = [_]u8{ 0x1, 0x1, 0x1, 0x1 };
    const uncompressed_data = first_uncompressed_part ++ second_uncompresse_part;

    const compressed_data = [_]u8{ 0xFF, 0x45, 0x86, 0x45, 0x83, 0x1 };

    const Test = struct {
        pub fn do(comptime vector_length: comptime_int) !void {
            var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer allocating_writer.deinit();

            try RunLengthSIMDEncoder(u8, .{ .vector_length = vector_length }).encode(uncompressed_data[0..], &allocating_writer.writer);

            try std.testing.expectEqualSlices(u8, compressed_data[0..], allocating_writer.written());
        }
    };

    try Test.do(4);
    try Test.do(8);
    try Test.do(16);
    try Test.do(32);
}

test "TGA RLE SIMD u16 encoder" {
    const uncompressed_source = [_]u16{ 0x301, 0x301, 0x301, 0x301, 0x301, 0x301, 0x301, 0x301, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8 };
    const uncompressed_data = std.mem.sliceAsBytes(uncompressed_source[0..]);

    const compressed_data = [_]u8{ 0x87, 0x01, 0x03, 0x07, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05, 0x00, 0x06, 0x00, 0x07, 0x00, 0x08, 0x00 };

    const Test = struct {
        pub fn do(comptime vector_length: comptime_int, compressed_data_param: []const u8, uncompressed_data_param: []const u8) !void {
            var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer allocating_writer.deinit();

            try RunLengthSIMDEncoder(u16, .{ .vector_length = vector_length }).encode(uncompressed_data_param[0..], &allocating_writer.writer);

            try std.testing.expectEqualSlices(u8, compressed_data_param[0..], allocating_writer.written());
        }
    };

    try Test.do(4, compressed_data[0..], uncompressed_data);
    try Test.do(8, compressed_data[0..], uncompressed_data);
    try Test.do(16, compressed_data[0..], uncompressed_data);
    try Test.do(32, compressed_data[0..], uncompressed_data);
}

test "TGA RLE SIMD u32 encoder" {
    const uncompressed_source = [_]u32{ 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0xFFABCDEF, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8 };
    const uncompressed_data = std.mem.sliceAsBytes(uncompressed_source[0..]);

    const compressed_data = [_]u8{ 0x87, 0xEF, 0xCD, 0xAB, 0xFF, 0x07, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00 };

    const Test = struct {
        pub fn do(comptime vector_length: comptime_int, compressed_data_param: []const u8, uncompressed_data_param: []const u8) !void {
            var allocating_writer = std.Io.Writer.Allocating.init(std.testing.allocator);
            defer allocating_writer.deinit();

            try RunLengthSIMDEncoder(u32, .{ .vector_length = vector_length }).encode(uncompressed_data_param[0..], &allocating_writer.writer);

            try std.testing.expectEqualSlices(u8, compressed_data_param[0..], allocating_writer.written());
        }
    };

    try Test.do(4, compressed_data[0..], uncompressed_data);
    try Test.do(8, compressed_data[0..], uncompressed_data);
    try Test.do(16, compressed_data[0..], uncompressed_data);
    try Test.do(32, compressed_data[0..], uncompressed_data);
}

pub const TGA = struct {
    header: TGAHeader = .{},
    id: utils.FixedStorage(u8, 256) = .{},
    extension: ?TGAExtension = null,

    pub const EncoderOptions = struct {
        rle_compressed: bool = true,
        top_to_bottom_image: bool = true,
        color_map_depth: u8 = 24,
        image_id: []const u8 = &.{},
        author_name: [:0]const u8 = &.{},
        author_comment: TGAExtensionComment = .{},
        timestamp: TGAExtensionTimestamp = .{},
        job_id: [:0]const u8 = &.{},
        job_time: TGAExtensionJobTime = .{},
        software_id: [:0]const u8 = &.{},
        software_version: TGAExtensionSoftwareVersion = .{},
    };

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        defer read_stream.seekTo(0) catch {};

        const reader = read_stream.reader();

        const end_pos = try read_stream.getEndPos();

        const is_valid_tga_v2: bool = blk: {
            if (@sizeOf(TGAFooter) < end_pos) {
                const footer_position = end_pos - @sizeOf(TGAFooter);

                try read_stream.seekTo(footer_position);
                const footer = try reader.peekStruct(TGAFooter, .little);

                if (footer.dot != '.') {
                    break :blk false;
                }

                if (footer.null_value != 0) {
                    break :blk false;
                }

                if (std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
                    break :blk true;
                }
            }

            break :blk false;
        };

        // Not a TGA 2.0 file, try to detect an TGA 1.0 image
        const is_valid_tga_v1: bool = blk: {
            if (!is_valid_tga_v2 and @sizeOf(TGAHeader) < end_pos) {
                try read_stream.seekTo(0);

                const header = try reader.peekStruct(TGAHeader, .little);
                break :blk header.isValid();
            }

            break :blk false;
        };

        return is_valid_tga_v2 or is_valid_tga_v1;
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result = Image{};
        errdefer result.deinit(allocator);

        var tga = TGA{};

        const pixels = try tga.read(allocator, read_stream);

        result.width = tga.width();
        result.height = tga.height();
        result.pixels = pixels;

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        _ = allocator;

        const tga_encoder_options = encoder_options.tga;

        const image_width = image.width;
        const image_height = image.height;

        if (image_width > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        if (image_height > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        if (!(tga_encoder_options.color_map_depth == 16 or tga_encoder_options.color_map_depth == 24)) {
            return Image.WriteError.Unsupported;
        }

        var tga = TGA{};
        tga.header.image_spec.width = @truncate(image_width);
        tga.header.image_spec.height = @truncate(image_height);
        tga.extension = TGAExtension{};

        if (tga_encoder_options.rle_compressed) {
            tga.header.image_type.run_length = true;
        }
        if (tga_encoder_options.top_to_bottom_image) {
            tga.header.image_spec.descriptor.top_to_bottom = true;
        }

        if (tga_encoder_options.image_id.len > 0) {
            if (tga_encoder_options.image_id.len > tga.id.storage.len) {
                return Image.WriteError.Unsupported;
            }

            tga.header.id_length = @truncate(tga_encoder_options.image_id.len);
            tga.id.resize(tga_encoder_options.image_id.len);

            @memcpy(tga.id.data[0..], tga_encoder_options.image_id[0..]);
        }

        if (tga.extension) |*extension| {
            if (tga_encoder_options.author_name.len >= extension.author_name.len) {
                return Image.WriteError.Unsupported;
            }
            if (tga_encoder_options.job_id.len >= extension.job_id.len) {
                return Image.WriteError.Unsupported;
            }
            if (tga_encoder_options.software_id.len >= extension.software_id.len) {
                return Image.WriteError.Unsupported;
            }

            std.mem.copyForwards(u8, extension.author_name[0..], tga_encoder_options.author_name[0..]);
            extension.author_comment = tga_encoder_options.author_comment;

            extension.timestamp = tga_encoder_options.timestamp;

            std.mem.copyForwards(u8, extension.job_id[0..], tga_encoder_options.job_id[0..]);
            extension.job_time = tga_encoder_options.job_time;

            std.mem.copyForwards(u8, extension.software_id[0..], tga_encoder_options.software_id[0..]);
            extension.software_version = tga_encoder_options.software_version;
        }

        switch (image.pixels) {
            .grayscale8 => {
                tga.header.image_type.indexed = true;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 8;
            },
            .indexed8 => |indexed| {
                tga.header.image_type.indexed = true;

                tga.header.image_spec.bit_per_pixel = 8;

                tga.header.color_map_spec.bit_depth = tga_encoder_options.color_map_depth;
                tga.header.color_map_spec.first_entry_index = 0;
                tga.header.color_map_spec.length = @truncate(indexed.palette.len);

                tga.header.has_color_map = 1;
            },
            .rgb555 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;
                tga.header.image_spec.bit_per_pixel = 16;
            },
            .rgb24, .bgr24 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 24;
            },
            .rgba32, .bgra32 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 32;

                tga.header.image_spec.descriptor.num_attributes_bit = 8;

                tga.extension.?.attributes = .useful_alpha_channel;
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        try tga.write(write_stream, image.pixels);
    }

    pub fn width(self: TGA) usize {
        return self.header.image_spec.width;
    }

    pub fn height(self: TGA) usize {
        return self.header.image_spec.height;
    }

    pub fn pixelFormat(self: TGA) Image.Error!PixelFormat {
        if (self.header.image_type.indexed) {
            if (self.header.image_type.truecolor) {
                return PixelFormat.grayscale8;
            }

            return PixelFormat.indexed8;
        } else if (self.header.image_type.truecolor) {
            switch (self.header.image_spec.bit_per_pixel) {
                16 => return PixelFormat.rgb555,
                24 => return PixelFormat.bgr24,
                32 => return PixelFormat.bgra32,
                else => {},
            }
        }

        return Image.Error.Unsupported;
    }

    pub fn read(self: *TGA, allocator: std.mem.Allocator, read_stream: *io.ReadStream) !color.PixelStorage {
        // Read footage
        const end_pos = try read_stream.getEndPos();

        if (@sizeOf(TGAFooter) > end_pos) {
            return Image.ReadError.InvalidData;
        }

        const reader = read_stream.reader();

        try read_stream.seekTo(end_pos - @sizeOf(TGAFooter));
        const footer = try reader.takeStruct(TGAFooter, .little);

        var is_tga_version2 = true;

        if (!std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
            is_tga_version2 = false;
        }

        // Read extension
        if (is_tga_version2 and footer.extension_offset > 0) {
            const extension_pos: u64 = @intCast(footer.extension_offset);
            try read_stream.seekTo(extension_pos);
            self.extension = try reader.takeStruct(TGAExtension, .little);
        }

        // Read header
        try read_stream.seekTo(0);
        self.header = try reader.takeStruct(TGAHeader, .little);

        if (!self.header.isValid()) {
            return Image.ReadError.InvalidData;
        }

        // Read ID
        if (self.header.id_length > 0) {
            self.id.resize(self.header.id_length);

            const read_id_size = try reader.readSliceShort(self.id.data[0..]);

            if (read_id_size != self.header.id_length) {
                return Image.ReadError.InvalidData;
            }
        }

        const pixel_format = try self.pixelFormat();

        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.width() * self.height());
        errdefer pixels.deinit(allocator);

        const is_compressed = self.header.image_type.run_length;

        var targa_reader: *std.Io.Reader = reader;
        var rle_decoder: ?TargaRLEDecoder = null;
        var rle_decompression_buffer: [512]u8 = undefined;

        defer {
            if (rle_decoder) |rle| {
                rle.deinit();
            }
        }

        if (is_compressed) {
            const bytes_per_pixel = (self.header.image_spec.bit_per_pixel + 7) / 8;

            rle_decoder = try TargaRLEDecoder.init(allocator, reader, bytes_per_pixel, rle_decompression_buffer[0..]);
            if (rle_decoder) |*rle| {
                targa_reader = &rle.reader;
            }
        }

        const top_to_bottom_image = self.header.image_spec.descriptor.top_to_bottom;

        switch (pixel_format) {
            .grayscale8 => {
                if (top_to_bottom_image) {
                    try self.readGrayscale8TopToBottom(pixels.grayscale8, targa_reader);
                } else {
                    try self.readGrayscale8BottomToTop(pixels.grayscale8, targa_reader);
                }
            },
            .indexed8 => {
                // Read color map, it is not compressed by RLE so always use the original reader
                switch (self.header.color_map_spec.bit_depth) {
                    15, 16 => {
                        pixels.indexed8.resizePalette(self.header.color_map_spec.length);
                        try self.readColorMap16(pixels.indexed8, reader);
                    },
                    24 => {
                        pixels.indexed8.resizePalette(self.header.color_map_spec.length);
                        try self.readColorMap24(pixels.indexed8, reader);
                    },
                    else => {
                        return Image.Error.Unsupported;
                    },
                }

                // Read indices
                if (top_to_bottom_image) {
                    try self.readIndexed8TopToBottom(pixels.indexed8, targa_reader);
                } else {
                    try self.readIndexed8BottomToTop(pixels.indexed8, targa_reader);
                }
            },
            .rgb555 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor16TopToBottom(pixels.rgb555, targa_reader);
                } else {
                    try self.readTruecolor16BottomToTop(pixels.rgb555, targa_reader);
                }
            },
            .bgr24 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor24TopToBottom(pixels.bgr24, targa_reader);
                } else {
                    try self.readTruecolor24BottomTopTop(pixels.bgr24, targa_reader);
                }
            },
            .bgra32 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor32TopToBottom(pixels.bgra32, targa_reader);
                } else {
                    try self.readTruecolor32BottomToTop(pixels.bgra32, targa_reader);
                }
            },
            else => {
                return Image.Error.Unsupported;
            },
        }

        return pixels;
    }

    fn readGrayscale8TopToBottom(self: *TGA, data: []color.Grayscale8, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index] = color.Grayscale8{ .value = try reader.takeByte() };
        }
    }

    fn readGrayscale8BottomToTop(self: *TGA, data: []color.Grayscale8, reader: *std.Io.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data[data_index] = color.Grayscale8{ .value = try reader.takeByte() };
            }
        }
    }

    fn readIndexed8TopToBottom(self: *TGA, data: color.IndexedStorage8, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data.indices[data_index] = try reader.takeByte();
        }
    }

    fn readIndexed8BottomToTop(self: *TGA, data: color.IndexedStorage8, reader: *std.Io.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data.indices[data_index] = try reader.takeByte();
            }
        }
    }

    fn readColorMap16(self: *TGA, data: color.IndexedStorage8, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            const raw_color: u15 = @truncate(try reader.takeInt(u16, .little));
            const read_color: color.Rgb555 = @bitCast(raw_color);

            data.palette[data_index].r = toU8(read_color.r);
            data.palette[data_index].g = toU8(read_color.g);
            data.palette[data_index].b = toU8(read_color.b);
            data.palette[data_index].a = 255;
        }
    }

    fn readColorMap24(self: *TGA, data: color.IndexedStorage8, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            data.palette[data_index].b = try reader.takeByte();
            data.palette[data_index].g = try reader.takeByte();
            data.palette[data_index].r = try reader.takeByte();
            data.palette[data_index].a = 255;
        }
    }

    fn readTruecolor16TopToBottom(self: *TGA, data: []color.Rgb555, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            const raw_color = try reader.takeInt(u16, .little);

            data[data_index].r = @truncate(raw_color >> 10);
            data[data_index].g = @truncate(raw_color >> 5);
            data[data_index].b = @truncate(raw_color);
        }
    }

    fn readTruecolor16BottomToTop(self: *TGA, data: []color.Rgb555, reader: *std.Io.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;

                const raw_color = try reader.takeInt(u16, .little);

                data[data_index].r = @truncate(raw_color >> (5 * 2));
                data[data_index].g = @truncate(raw_color >> 5);
                data[data_index].b = @truncate(raw_color);
            }
        }
    }

    fn readTruecolor24TopToBottom(self: *TGA, data: []color.Bgr24, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index].b = try reader.takeByte();
            data[data_index].g = try reader.takeByte();
            data[data_index].r = try reader.takeByte();
        }
    }

    fn readTruecolor24BottomTopTop(self: *TGA, data: []color.Bgr24, reader: *std.Io.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data[data_index].b = try reader.takeByte();
                data[data_index].g = try reader.takeByte();
                data[data_index].r = try reader.takeByte();
            }
        }
    }

    fn readTruecolor32TopToBottom(self: *TGA, data: []color.Bgra32, reader: *std.Io.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index].b = try reader.takeByte();
            data[data_index].g = try reader.takeByte();
            data[data_index].r = try reader.takeByte();
            data[data_index].a = try reader.takeByte();

            if (self.extension) |extended_info| {
                if (extended_info.attributes != TGAAttributeType.useful_alpha_channel) {
                    data[data_index].a = 0xFF;
                }
            }
        }
    }

    fn readTruecolor32BottomToTop(self: *TGA, data: []color.Bgra32, reader: *std.Io.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;

                data[data_index].b = try reader.takeByte();
                data[data_index].g = try reader.takeByte();
                data[data_index].r = try reader.takeByte();
                data[data_index].a = try reader.takeByte();

                if (self.extension) |extended_info| {
                    if (extended_info.attributes != TGAAttributeType.useful_alpha_channel) {
                        data[data_index].a = 0xFF;
                    }
                }
            }
        }
    }

    pub fn write(self: TGA, write_stream: *io.WriteStream, pixels: color.PixelStorage) Image.WriteError!void {
        const writer = write_stream.writer();

        try writer.writeStruct(self.header, .little);

        if (self.header.id_length > 0) {
            if (self.id.data.len != self.header.id_length) {
                return Image.WriteError.Unsupported;
            }

            try writer.writeAll(self.id.data);
        }

        switch (pixels) {
            .indexed8 => {
                try self.writeIndexed8(writer, pixels);
            },
            .grayscale8,
            .rgb555,
            .bgr24,
            .bgra32,
            => {
                try self.writePixels(writer, pixels);
            },
            .rgb24 => {
                try self.writeRgb24(writer, pixels);
            },
            .rgba32 => {
                try self.writeRgba32(writer, pixels);
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        var extension_offset: u32 = 0;
        if (self.extension) |extension| {
            extension_offset = @truncate(write_stream.getPos());

            try writer.writeStruct(extension, .little);
        }

        var footer = TGAFooter{};
        footer.extension_offset = extension_offset;
        std.mem.copyForwards(u8, footer.signature[0..], TGASignature[0..]);
        try writer.writeStruct(footer, .little);

        try write_stream.flush();
    }

    fn writePixels(self: TGA, writer: *std.Io.Writer, pixels: color.PixelStorage) Image.WriteError!void {
        const bytes = pixels.asConstBytes();

        const effective_height = self.height();
        const effective_width = self.width();
        const bytes_per_pixel = std.meta.activeTag(pixels).pixelStride();
        const pixel_stride = effective_width * bytes_per_pixel;

        if (self.header.image_type.run_length) {
            // The TGA spec recommend that the RLE compression should be done on scanline per scanline basis
            inline for (1..(4 + 1)) |bpp| {
                const IntType = std.meta.Int(.unsigned, bpp * 8);

                if (bytes_per_pixel == bpp) {
                    if (comptime std.math.isPowerOfTwo(bpp)) {
                        if (self.header.image_spec.descriptor.top_to_bottom) {
                            for (0..effective_height) |y| {
                                const current_scanline = y * pixel_stride;

                                try RunLengthSIMDEncoder(IntType, .{}).encode(bytes[current_scanline..(current_scanline + pixel_stride)], writer);
                            }
                        } else {
                            for (0..effective_height) |y| {
                                const flipped_y = effective_height - y - 1;
                                const current_scanline = flipped_y * pixel_stride;

                                try RunLengthSIMDEncoder(IntType, .{}).encode(bytes[current_scanline..(current_scanline + pixel_stride)], writer);
                            }
                        }
                    } else {
                        if (self.header.image_spec.descriptor.top_to_bottom) {
                            for (0..effective_height) |y| {
                                const current_scanline = y * pixel_stride;

                                try RunLengthSimpleEncoder(IntType).encode(bytes[current_scanline..(current_scanline + pixel_stride)], writer);
                            }
                        } else {
                            for (0..effective_height) |y| {
                                const flipped_y = effective_height - y - 1;
                                const current_scanline = flipped_y * pixel_stride;

                                try RunLengthSimpleEncoder(IntType).encode(bytes[current_scanline..(current_scanline + pixel_stride)], writer);
                            }
                        }
                    }
                }
            }
        } else {
            if (self.header.image_spec.descriptor.top_to_bottom) {
                try writer.writeAll(bytes);
            } else {
                for (0..effective_height) |y| {
                    const flipped_y = effective_height - y - 1;
                    const current_scanline = flipped_y * pixel_stride;

                    try writer.writeAll(bytes[current_scanline..(current_scanline + pixel_stride)]);
                }
            }
        }
    }

    fn writeRgb24(self: TGA, writer: *std.Io.Writer, pixels: color.PixelStorage) Image.WriteError!void {
        const image_width = self.width();
        const image_height = self.height();

        if (self.header.image_type.run_length) {
            var rle_encoder = RLEStreamColorEncoder(color.Bgr24){};

            if (self.header.image_spec.descriptor.top_to_bottom) {
                for (0..image_height) |y| {
                    const stride = y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgb24[stride + x];

                        const bgr_color = color.Bgr24{ .r = current_color.r, .g = current_color.g, .b = current_color.b };

                        try rle_encoder.encode(writer, bgr_color);
                    }
                }
            } else {
                for (0..image_height) |y| {
                    const flipped_y = image_height - y - 1;
                    const stride = flipped_y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgb24[stride + x];

                        const bgr_color = color.Bgr24{ .r = current_color.r, .g = current_color.g, .b = current_color.b };

                        try rle_encoder.encode(writer, bgr_color);
                    }
                }
            }

            try rle_encoder.flush(writer);
        } else {
            if (self.header.image_spec.descriptor.top_to_bottom) {
                for (0..image_height) |y| {
                    const stride = y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgb24[stride + x];
                        try writer.writeByte(current_color.b);
                        try writer.writeByte(current_color.g);
                        try writer.writeByte(current_color.r);
                    }
                }
            } else {
                for (0..image_height) |y| {
                    const flipped_y = image_height - y - 1;
                    const stride = flipped_y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgb24[stride + x];
                        try writer.writeByte(current_color.b);
                        try writer.writeByte(current_color.g);
                        try writer.writeByte(current_color.r);
                    }
                }
            }
        }
    }

    fn writeRgba32(self: TGA, writer: *std.Io.Writer, pixels: color.PixelStorage) Image.WriteError!void {
        const image_width = self.width();
        const image_height = self.height();

        if (self.header.image_type.run_length) {
            var rle_encoder = RLEStreamColorEncoder(color.Bgra32){};

            if (self.header.image_spec.descriptor.top_to_bottom) {
                for (0..image_height) |y| {
                    const stride = y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgba32[stride + x];

                        const bgra_color = color.Bgra32{ .r = current_color.r, .g = current_color.g, .b = current_color.b, .a = current_color.a };

                        try rle_encoder.encode(writer, bgra_color);
                    }
                }
            } else {
                for (0..image_height) |y| {
                    const flipped_y = image_height - y - 1;
                    const stride = flipped_y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgba32[stride + x];

                        const bgra_color = color.Bgra32{ .r = current_color.r, .g = current_color.g, .b = current_color.b, .a = current_color.a };

                        try rle_encoder.encode(writer, bgra_color);
                    }
                }
            }

            try rle_encoder.flush(writer);
        } else {
            if (self.header.image_spec.descriptor.top_to_bottom) {
                for (0..image_height) |y| {
                    const stride = y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgba32[stride + x];
                        try writer.writeByte(current_color.b);
                        try writer.writeByte(current_color.g);
                        try writer.writeByte(current_color.r);
                        try writer.writeByte(current_color.a);
                    }
                }
            } else {
                for (0..image_height) |y| {
                    const flipped_y = image_height - y - 1;
                    const stride = flipped_y * image_width;

                    for (0..image_width) |x| {
                        const current_color = pixels.rgba32[stride + x];
                        try writer.writeByte(current_color.b);
                        try writer.writeByte(current_color.g);
                        try writer.writeByte(current_color.r);
                        try writer.writeByte(current_color.a);
                    }
                }
            }
        }
    }

    fn writeIndexed8(self: TGA, writer: *std.Io.Writer, pixels: color.PixelStorage) Image.WriteError!void {
        // First write color map, the color map needs to be written uncompressed
        switch (self.header.color_map_spec.bit_depth) {
            15, 16 => {
                try self.writeColorMap16(writer, pixels.indexed8);
            },
            24 => {
                try self.writeColorMap24(writer, pixels.indexed8);
            },
            else => {
                return Image.Error.Unsupported;
            },
        }

        // Then write the indice data, compressed or uncompressed
        try self.writePixels(writer, pixels);
    }

    fn writeColorMap16(self: TGA, writer: *std.Io.Writer, indexed: color.IndexedStorage8) Image.WriteError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            const converted_color = color.Rgb555{
                .r = toU5(indexed.palette[data_index].r),
                .g = toU5(indexed.palette[data_index].g),
                .b = toU5(indexed.palette[data_index].b),
            };

            try writer.writeInt(u16, @as(u15, @bitCast(converted_color)), .little);
        }
    }

    fn writeColorMap24(self: TGA, writer: *std.Io.Writer, indexed: color.IndexedStorage8) Image.WriteError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            const converted_color = color.Bgr24{
                .r = indexed.palette[data_index].r,
                .g = indexed.palette[data_index].g,
                .b = indexed.palette[data_index].b,
            };

            try writer.writeStruct(converted_color, .little);
        }
    }
};
