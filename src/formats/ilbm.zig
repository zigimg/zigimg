const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

const iff_description_length = 12;
const IFFMagicHeader = [_]u8{ 'F', 'O', 'R', 'M' };
const ILBMMagicHeader = [_]u8{ 'I', 'L', 'B', 'M' };
const PBMMagicHeader = [_]u8{ 'P', 'B', 'M', ' ' };

pub const Chunk = struct {
    id: u32,
    name: *const [4:0]u8,

    pub fn init(name: *const [4:0]u8) Chunk {
        return .{ .name = name, .id = std.mem.bigToNative(u32, std.mem.bytesToValue(u32, name)) };
    }
};

pub const Chunks = struct {
    pub const BMHD = Chunk.init("BMHD");
    pub const CMAP = Chunk.init("CMAP");
    pub const BODY = Chunk.init("BODY");
};

pub fn isILBMHeader(stream: *ImageUnmanaged.Stream) ImageUnmanaged.Stream.ReadError!bool {
    var magic_buffer: [iff_description_length]u8 = undefined;

    _ = try stream.reader().readAll(magic_buffer[0..]);
    const is_iff = std.mem.eql(u8, magic_buffer[0..4], IFFMagicHeader[0..]);
    if (!is_iff) {
        return false;
    }
    if (std.mem.eql(u8, magic_buffer[8..], PBMMagicHeader[0..])) {
        return true;
    }

    return false;
}

pub fn loadHeader(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!BitmapHeader {
    if (!try isILBMHeader(stream)) {
        return ImageUnmanaged.ReadError.InvalidData;
    }

    var reader = stream.reader();
    const chunk = try utils.readStruct(reader, ChunkHeader, .big);
    if (chunk.type != Chunks.BMHD.id) return ImageUnmanaged.ReadError.InvalidData;
    if (chunk.length != @sizeOf(BitmapHeader)) return ImageUnmanaged.ReadError.InvalidData;

    var header_data: [@sizeOf(BitmapHeader)]u8 = undefined;
    try reader.readNoEof(&header_data);

    var struct_stream = std.io.fixedBufferStream(&header_data);

    const header = try utils.readStruct(struct_stream.reader(), BitmapHeader, .big);

    return header;
}

pub const ChunkHeader = extern struct {
    type: u32 align(1),
    length: u32 align(1),

    const Self = @This();

    pub fn name(self: *const Self) []const u8 {
        return std.mem.asBytes(&self.type);
    }
};

pub const CompressionType = enum(u8) {
    none = 0,
    byterun = 1,
};

pub const MaskType = enum(u8) {
    none = 0,
    has_mask = 1,
    has_transparent_color = 2,
    has_lasso = 3,
};

pub const ViewportMode = enum(u32) {
    ehb = 0x80,
    ham = 0x800,
};

pub const Format = enum(u8) {
    // Amiga interleaved format
    ilbm = 0,
    // PC-DeluxePaint chunky format
    pbm = 1,
};

pub const BitmapHeader = extern struct {
    width: u16 = 0,
    height: u16 = 0,
    x: i16 = 0,
    y: i16 = 0,
    planes: u8 = 0,
    mask_type: MaskType = .none,
    compression_type: CompressionType = .none,
    pad: u8 = 0,
    transparent_color: u16 = 0,
    x_asoect: u8 = 0,
    y_aspect: u8 = 0,
    page_width: u16 = 0,
    page_height: u16 = 0,

    const Self = @This();

    pub const HeaderSize = @sizeOf(BitmapHeader);

    pub fn debug(self: *const Self) void {
        std.debug.print("Width: {}, Height: {}, planes: {}, compression: {}\n", .{ self.width, self.height, self.planes, self.compression_type });
    }
};

pub fn decodeByteRun1(stream: *ImageUnmanaged.Stream, tmp_buffer: *[]u8, length: u32) !void {
    const reader = stream.reader();
    var output_offset: u32 = 0;
    var input_offset: u32 = 0;

    while (input_offset < length - 1) {
        const control: usize = try reader.readByte();
        input_offset += 1;
        if (control < 128) {
            for (0..control + 1) |_| {
                if (input_offset >= length) {
                    return;
                }
                tmp_buffer.*[output_offset] = try reader.readByte();
                output_offset += 1;
                input_offset += 1;
            }
        } else if (control > 128) {
            const value = try reader.readByte();
            input_offset += 1;
            for (0..257 - control) |_| {
                tmp_buffer.*[output_offset] = value;
                output_offset += 1;
            }
        }
    }
}

pub const ILBM = struct {
    header: BitmapHeader = undefined,
    pixels: PixelStorage = undefined,

    pub fn width(self: *ILBM) usize {
        return self.header.width;
    }

    pub fn height(self: *ILBM) usize {
        return self.header.height;
    }

    pub fn format() ImageUnmanaged.Format {
        return ImageUnmanaged.Format.ilbm;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) ImageUnmanaged.Stream.ReadError!bool {
        return try isILBMHeader(stream);
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var ilbm = ILBM{};

        try ilbm.load(stream, allocator);

        result.pixels = ilbm.pixels;
        result.width = ilbm.width();
        result.height = ilbm.height();

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    pub fn load(self: *ILBM, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!void {
        self.header = try loadHeader(stream);
        self.header.debug();

        self.pixels = try color.PixelStorage.init(allocator, PixelFormat.indexed8, self.width() * self.height());
        errdefer self.pixels.deinit(allocator);

        try self.decodeChunks(stream, allocator);
    }

    pub fn decodeChunks(self: *ILBM, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !void {
        const reader = stream.reader();
        const end_pos = try stream.getEndPos();
        while (true) {
            const chunk = try utils.readStruct(reader, ChunkHeader, .big);
            try self.processChunk(&chunk, stream, allocator);
            if (try stream.getPos() >= end_pos - 1) {
                break;
            }
        }
    }

    pub fn processChunk(self: *ILBM, chunk: *const ChunkHeader, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !void {
        switch (chunk.type) {
            Chunks.CMAP.id => try self.decodeCMAPChunk(stream, chunk),
            Chunks.BODY.id => try self.decodeBODYChunk(stream, chunk, allocator),
            // skip unsupported chunks
            else => try stream.seekBy(chunk.length),
        }
    }

    pub fn decodeCMAPChunk(self: *ILBM, stream: *ImageUnmanaged.Stream, chunk: *const ChunkHeader) !void {
        const num_colors = chunk.length / 3;
        var palette = switch (self.pixels) {
            .indexed8 => |*storage| storage.palette[0..],
            else => undefined,
        };

        const reader = stream.reader();

        for (0..num_colors) |i| {
            const c = try utils.readStruct(reader, color.Rgb24, .little);
            palette[i].r = c.r;
            palette[i].g = c.g;
            palette[i].b = c.b;
            palette[i].a = 255;
        }
    }

    pub fn decodeBODYChunk(self: *ILBM, stream: *ImageUnmanaged.Stream, chunk: *const ChunkHeader, allocator: std.mem.Allocator) !void {
        if (self.header.compression_type == CompressionType.byterun) {
            var tmp_buffer = try allocator.alloc(u8, self.width() * self.height());
            defer allocator.free(tmp_buffer);
            try decodeByteRun1(stream, &tmp_buffer, chunk.length);

            switch (self.pixels) {
                .indexed8 => |storage| {
                    @memcpy(storage.indices[0..], tmp_buffer[0..]);
                },
                else => unreachable,
            }
        } else unreachable;
    }
};
