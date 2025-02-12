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
const IFFMagicHeader = "FORM";
const ILBMMagicHeader = "ILBM";
const PBMMagicHeader = "PBM ";

pub const Chunk = struct {
    id: u32,
    name: []const u8,

    pub fn init(name: []const u8) Chunk {
        std.debug.assert(name.len == 4);
        return .{ .name = name, .id = std.mem.bigToNative(u32, std.mem.bytesToValue(u32, name)) };
    }
};

pub const Chunks = struct {
    pub const BMHD = Chunk.init("BMHD");
    pub const BODY = Chunk.init("BODY");
    pub const CAMG = Chunk.init("CAMG");
    pub const CMAP = Chunk.init("CMAP");
};

pub fn getILBMFormatId(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!Format {
    var magic_buffer: [iff_description_length]u8 = undefined;

    _ = try stream.reader().readAll(magic_buffer[0..]);
    const is_iff = std.mem.eql(u8, magic_buffer[0..4], IFFMagicHeader[0..]);
    if (!is_iff) {
        return ImageUnmanaged.ReadError.InvalidData;
    }
    const format = if (std.mem.eql(u8, magic_buffer[8..], PBMMagicHeader[0..])) Format.pbm else Format.ilbm;

    return format;
}

pub fn loadHeader(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!BitmapHeader {
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

pub fn extend_ehb_palette(palette: *utils.FixedStorage(color.Rgba32, 256)) void {
    palette.resize(64);
    const data = palette.data;
    for (0..32) |i| {
        const c = data[i];
        // EHB mode extends the palette to 64 colors by adding 32 darker colors
        data[i + 32] = color.Rgba32.initRgb(c.r >> 1, c.g >> 1, c.b >> 1);
    }
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
    pub fn isEHB(mode: u32) bool {
        return (@intFromEnum(ViewportMode.ehb) & mode) != 0;
    }
};

pub const Format = enum(u8) {
    // Amiga interleaved format
    ilbm = 0,
    // PC-DeluxePaint chunky format
    pbm = 1,
    bad = 2,
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

pub fn decodeByteRun1(stream: *ImageUnmanaged.Stream, tmp_buffer: []u8, length: u32) !void {
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
                tmp_buffer[output_offset] = try reader.readByte();
                output_offset += 1;
                input_offset += 1;
            }
        } else if (control > 128) {
            const value = try reader.readByte();
            input_offset += 1;
            for (0..257 - control) |_| {
                tmp_buffer[output_offset] = value;
                output_offset += 1;
            }
        }
    }
}

pub const ILBM = struct {
    format_id: Format = undefined,
    header: BitmapHeader = undefined,
    palette: utils.FixedStorage(color.Rgba32, 256) = .{},
    pitch: u16 = 0,
    viewportMode: u32 = 0,

    pub fn width(self: *ILBM) usize {
        return self.header.width;
    }

    pub fn height(self: *ILBM) usize {
        return self.header.height;
    }

    pub fn pixelFormat(self: *ILBM) ImageUnmanaged.Error!PixelFormat {
        if (self.header.planes <= 8) {
            return PixelFormat.indexed8;
        } else {
            return ImageUnmanaged.Error.Unsupported;
        }
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        const format_id = getILBMFormatId(stream) catch Format.bad;

        if (format_id == .bad) {
            return false;
        } else {
            return true;
        }
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var ilbm = ILBM{};

        const pixels = try ilbm.read(stream, allocator);

        result.pixels = pixels;
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

    pub fn read(self: *ILBM, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        self.format_id = try getILBMFormatId(stream);
        self.header = try loadHeader(stream);
        self.pitch = (std.math.divCeil(u16, self.header.width, 16) catch 0) * 2;
        self.header.debug();

        const pixels = try self.decodeChunks(stream, allocator);

        return pixels;
    }

    pub fn decodeChunks(self: *ILBM, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !color.PixelStorage {
        const reader = stream.reader();
        const end_pos = try stream.getEndPos();
        while (true) {
            const chunk = try utils.readStruct(reader, ChunkHeader, .big);
            switch (chunk.type) {
                Chunks.BODY.id => return try self.decodeBODYChunk(stream, &chunk, allocator),
                Chunks.CAMG.id => try self.decodeCAMGChunk(stream),
                Chunks.CMAP.id => try self.decodeCMAPChunk(stream, &chunk),
                // skip unsupported chunks
                else => try stream.seekBy(chunk.length),
            }
            if (try stream.getPos() >= end_pos - 1) {
                break;
            }
        }

        return ImageUnmanaged.Error.Unsupported;
    }

    pub fn planarToChunky(self: *ILBM, bitplanes: []u8, chunky_buffer: []u8) !void {
        const header = self.header;
        const planes = header.planes;
        const w = header.width;
        const h = header.height;
        const pitch = self.pitch;
        const dest_len = chunky_buffer.len;

        // we already have a chunky buffer: no need to convert to planar
        if (self.format_id == .pbm) {
            @memcpy(chunky_buffer[0..dest_len], bitplanes[0..dest_len]);
            return;
        }

        @memset(chunky_buffer, 0);

        for (0..h) |y| {
            for (0..planes) |p| {
                const plane_mask: u8 = @as(u8, 1) << @intCast(p);
                for (0..pitch) |i| {
                    const offset = (pitch * planes * y) + (p * pitch) + i;
                    const bit = bitplanes[offset];

                    for (0..8) |b| {
                        const mask = @as(u8, 1) << @intCast((@as(u8, 7) - b));
                        if ((bit & mask) > 0) {
                            const x = (i * 8) + b;
                            chunky_buffer[(y * w) + x] |= plane_mask;
                        }
                    }
                }
            }
        }
    }

    pub fn decodeCAMGChunk(self: *ILBM, stream: *ImageUnmanaged.Stream) !void {
        const reader = stream.reader();
        self.viewportMode = try reader.readInt(u32, .big);
    }

    pub fn decodeCMAPChunk(self: *ILBM, stream: *ImageUnmanaged.Stream, chunk: *const ChunkHeader) !void {
        const num_colors = chunk.length / 3;
        const reader = stream.reader();
        self.palette.resize(num_colors);
        const palette = self.palette.data;

        for (0..num_colors) |i| {
            const c = try utils.readStruct(reader, color.Rgb24, .little);
            palette[i] = color.Rgba32.fromU32Rgb(c.toU32Rgb());
        }
    }

    pub fn decodeBODYChunk(self: *ILBM, stream: *ImageUnmanaged.Stream, chunk: *const ChunkHeader, allocator: std.mem.Allocator) !color.PixelStorage {
        std.debug.assert(self.pitch != 0);

        const pixel_format = try self.pixelFormat();

        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.width() * self.height());
        errdefer pixels.deinit(allocator);

        const tmp_buffer: []u8 = try allocator.alloc(u8, self.pitch * self.height() * self.header.planes);
        defer allocator.free(tmp_buffer);

        // first uncompress planes data if needed
        if (self.header.compression_type == CompressionType.byterun) {
            try decodeByteRun1(stream, tmp_buffer, chunk.length);
        } else {
            const reader = stream.reader();
            _ = try reader.readAll(tmp_buffer);
        }

        const chunky_buffer: []u8 = try allocator.alloc(u8, self.width() * self.height());
        defer allocator.free(chunky_buffer);

        try self.planarToChunky(tmp_buffer, chunky_buffer);

        if (ViewportMode.isEHB(self.viewportMode) and self.palette.data.len < 64) {
            extend_ehb_palette(&self.palette);
        }

        switch (pixels) {
            .indexed8 => |*storage| {
                @memcpy(storage.indices[0..], chunky_buffer[0..storage.indices.len]);

                storage.resizePalette(self.palette.data.len);
                for (0..self.palette.data.len) |index| {
                    const palette = storage.palette;
                    palette[index] = self.palette.data[index];
                }
            },
            else => unreachable,
        }

        return pixels;
    }
};
