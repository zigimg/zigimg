// Implement PNG image format according to W3C Portable Network Graphics (PNG) specification second edition (ISO/IEC 15948:2003 (E))
// Last version: https://www.w3.org/TR/PNG/
const Allocator = std.mem.Allocator;
const crc = std.hash.crc;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageInStream = image.ImageInStream;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const image = @import("../image.zig");
const std = @import("std");
const utils = @import("../utils.zig");
const zlib = @import("../compression/zlib.zig");
const deflate = @import("../compression/deflate.zig");

const PNGMagicHeader = "\x89PNG\x0D\x0A\x1A\x0A";

pub const ColorType = packed enum(u8) {
    Grayscale = 0,
    Truecolor = 2,
    Indexed = 3,
    GrayscaleAlpha = 4,
    TruecolorAlpha = 6,

    const Self = @This();

    pub fn getChannelCount(self: Self) u8 {
        return switch (self) {
            .Grayscale => 1,
            .Truecolor => 3,
            .Indexed => 1,
            .GrayscaleAlpha => 2,
            .TruecolorAlpha => 4,
        };
    }
};

pub const FilterType = enum(u8) {
    None,
    Sub,
    Up,
    Average,
    Paeth,
};

pub const InterlaceMethod = packed enum(u8) {
    Standard,
    Adam7,
};

pub const IHDR = packed struct {
    width: u32,
    height: u32,
    bit_depth: u8,
    color_type: ColorType,
    compression_method: u8,
    filter_method: u8,
    interlace_method: InterlaceMethod,

    pub const ChunkType = "IHDR";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {}

    pub fn read(self: *Self, allocator: *Allocator, read_buffer: []u8) !bool {
        var stream = std.io.StreamSource{ .buffer = std.io.fixedBufferStream(read_buffer) };
        self.* = try utils.readStructBig(stream.inStream(), Self);
        return true;
    }
};

pub const PLTE = struct {
    palette: []color.Color,

    pub const ChunkType = "PLTE";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {
        allocator.free(self.palette);
    }

    pub fn read(self: *Self, allocator: *Allocator, read_buffer: []u8) !bool {
        if (read_buffer.len % 3 != 0) {
            return errors.PngError.InvalidPalette;
        }

        self.palette = try allocator.alloc(color.Color, read_buffer.len / 3);

        var palette_index: usize = 0;
        var buffer_index: usize = 0;
        while (buffer_index < read_buffer.len) {
            self.palette[palette_index].R = color.toColorFloat(read_buffer[buffer_index]);
            self.palette[palette_index].G = color.toColorFloat(read_buffer[buffer_index + 1]);
            self.palette[palette_index].B = color.toColorFloat(read_buffer[buffer_index + 2]);

            palette_index += 1;
            buffer_index += 3;
        }

        return true;
    }
};

pub const IDAT = struct {
    data: []u8 = undefined,

    pub const ChunkType = "IDAT";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {
        allocator.free(self.data);
    }

    pub fn read(self: *Self, allocator: *Allocator, read_buffer: []u8) !bool {
        self.data = read_buffer;
        return false;
    }
};

pub const IEND = packed struct {
    pub const ChunkType = "IEND";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {}

    pub fn read(self: *Self, allocator: *Allocator, read_buffer: []u8) !bool {
        return true;
    }
};

pub const gAMA = packed struct {
    iGamma: u32,

    pub const ChunkType = "gAMA";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {}

    pub fn read(self: *Self, allocator: *Allocator, read_buffer: []u8) !bool {
        var stream = std.io.fixedBufferStream(read_buffer);
        self.iGamma = try stream.inStream().readIntBig(u32);
        return true;
    }

    pub fn toGammaExponent(self: Self) f32 {
        return @intToFloat(f32, self.iGamma) / 100000.0;
    }
};

pub const ChunkVariant = union(enum) {
    PLTE: PLTE,
    IDAT: IDAT,
    gAMA: gAMA,

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {
        switch (self) {
            .PLTE => |instance| instance.deinit(allocator),
            .IDAT => |instance| instance.deinit(allocator),
            .gAMA => |instance| instance.deinit(allocator),
        }
    }

    pub fn getChunkID(self: Self) u32 {
        return switch (self) {
            .PLTE => |instance| @field(@TypeOf(instance), "ChunkID"),
            .IDAT => |instance| @field(@TypeOf(instance), "ChunkID"),
            .gAMA => |instance| @field(@TypeOf(instance), "ChunkID"),
        };
    }
};

const ChunkAllowed = enum {
    OneOrMore,
    OnlyOne,
    ZeroOrOne,
    ZeroOrMore,
};

const ChunkInfo = struct {
    chunk_type: type,
    allowed: ChunkAllowed,
    store: bool,
};

const AllChunks = [_]ChunkInfo{
    .{
        .chunk_type = IHDR,
        .allowed = .OnlyOne,
        .store = false,
    },
    .{
        .chunk_type = PLTE,
        .allowed = .ZeroOrOne,
        .store = true,
    },
    .{
        .chunk_type = IDAT,
        .allowed = .OneOrMore,
        .store = true,
    },
    .{
        .chunk_type = gAMA,
        .allowed = .ZeroOrOne,
        .store = true,
    },
    .{
        .chunk_type = IEND,
        .allowed = .OnlyOne,
        .store = false,
    },
};

fn ValidBitDepths(color_type: ColorType) []const u8 {
    return switch (color_type) {
        .Grayscale => &[_]u8{ 1, 2, 4, 8, 16 },
        .Truecolor => &[_]u8{ 8, 16 },
        .Indexed => &[_]u8{ 1, 2, 4, 8 },
        .GrayscaleAlpha => &[_]u8{ 8, 16 },
        .TruecolorAlpha => &[_]u8{ 8, 16 },
    };
}

/// Implement filtering defined by https://www.w3.org/TR/2003/REC-PNG-20031110/#9Filters
const PngFilter = struct {
    context: []u8 = undefined,
    index: usize = 0,
    line_stride: usize = 0,
    pixel_stride: usize = 0,

    const Self = @This();

    pub fn init(allocator: *Allocator, line_stride: usize, bit_depth: usize) !Self {
        const context = try allocator.alloc(u8, line_stride * 2);
        std.mem.secureZero(u8, context[0..]);
        return Self{
            .context = context,
            .line_stride = line_stride,
            .pixel_stride = if (bit_depth >= 8) bit_depth / 8 else 1,
        };
    }

    pub fn deinit(self: Self, allocator: *Allocator) void {
        allocator.free(self.context);
    }

    pub fn decode(self: *Self, filter_type: FilterType, input: []const u8) !void {
        const current_start_position = self.startPosition();
        const previous_start_position: usize = if (self.index < self.line_stride) 0 else ((self.index - self.line_stride) % self.context.len);

        var current_row = self.context[current_start_position..(current_start_position + self.line_stride)];
        var previous_row = self.context[previous_start_position..(previous_start_position + self.line_stride)];

        switch (filter_type) {
            .None => {
                std.mem.copy(u8, current_row, input);
            },
            .Sub => {
                var i: usize = 0;
                while (i < input.len) : (i += 1) {
                    const a = self.getA(i, current_row, previous_row);
                    current_row[i] = input[i] +% a;
                }
            },
            .Up => {
                var i: usize = 0;
                while (i < input.len) : (i += 1) {
                    const b = self.getB(i, current_row, previous_row);
                    current_row[i] = input[i] +% b;
                }
            },
            .Average => {
                var i: usize = 0;
                while (i < input.len) : (i += 1) {
                    const a = @intToFloat(f64, self.getA(i, current_row, previous_row));
                    const b = @intToFloat(f64, self.getB(i, current_row, previous_row));
                    const result: u8 = @intCast(u8, @floatToInt(u16, std.math.floor((a + b) / 2.0)) & 0xFF);

                    current_row[i] = input[i] +% result;
                }
            },
            .Paeth => {
                var i: usize = 0;
                while (i < input.len) : (i += 1) {
                    const a = self.getA(i, current_row, previous_row);
                    const b = self.getB(i, current_row, previous_row);
                    const c = self.getC(i, current_row, previous_row);

                    const source = input[i];
                    const predictor = try paethPredictor(a, b, c);
                    const result = @intCast(u8, (@as(u16, source) + @as(u16, predictor)) & 0xFF);

                    current_row[i] = result;
                }
            },
        }

        self.index += self.line_stride;
    }

    pub fn getSlice(self: Self) []u8 {
        const start = self.startPosition();
        return self.context[start..(start + self.line_stride)];
    }

    fn startPosition(self: Self) usize {
        return self.index % self.context.len;
    }

    inline fn getA(self: Self, index: usize, current_row: []const u8, previous_row: []const u8) u8 {
        if (index >= self.pixel_stride) {
            return current_row[index - self.pixel_stride];
        } else {
            return 0;
        }
    }

    inline fn getB(self: Self, index: usize, current_row: []const u8, previous_row: []const u8) u8 {
        return previous_row[index];
    }

    inline fn getC(self: Self, index: usize, current_row: []const u8, previous_row: []const u8) u8 {
        if (index >= self.pixel_stride) {
            return previous_row[index - self.pixel_stride];
        } else {
            return 0;
        }
    }

    fn paethPredictor(a: u8, b: u8, c: u8) !u8 {
        const large_a = @intCast(isize, a);
        const large_b = @intCast(isize, b);
        const large_c = @intCast(isize, c);
        const p = large_a + large_b - large_c;
        const pa = try std.math.absInt(p - large_a);
        const pb = try std.math.absInt(p - large_b);
        const pc = try std.math.absInt(p - large_c);

        if (pa <= pb and pa <= pc) {
            return @intCast(u8, large_a & 0xFF);
        } else if (pb <= pc) {
            return @intCast(u8, large_b & 0xFF);
        } else {
            return @intCast(u8, large_c & 0xFF);
        }
    }
};

// remember, PNG uses network byte order (aka Big Endian)
// TODO: Proper validation of chunk order and count
pub const PNG = struct {
    header: IHDR = undefined,
    chunks: std.ArrayList(ChunkVariant) = undefined,
    pixel_format: PixelFormat = undefined,
    allocator: *Allocator = undefined,

    const DecompressionContext = struct {
        pixels: *color.ColorStorage = undefined,
        pixels_index: usize = 0,
        compressed_data: std.ArrayList(u8) = undefined,
        filter: PngFilter = undefined,
        pass: i8 = -1,
        x: usize = 0,
        y: usize = 0,
    };

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return Self{
            .chunks = std.ArrayList(ChunkVariant).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.chunks.span()) |chunk| {
            chunk.deinit(self.allocator);
        }

        self.chunks.deinit();
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Png;
    }

    pub fn formatDetect(inStream: ImageInStream, seekStream: ImageSeekStream) !bool {
        var magicNumberBuffer: [8]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        return std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader);
    }

    pub fn findFirstChunk(self: Self, chunk_type: []const u8) ?ChunkVariant {
        const chunkID = utils.toMagicNumberBig(chunk_type);

        for (self.chunks.span()) |chunk| {
            if (chunk.getChunkID() == chunkID) {
                return chunk;
            }
        }

        return null;
    }

    pub fn getPalette(self: Self) ?PLTE {
        const palette_variant_opt = self.findFirstChunk(PLTE.ChunkType);

        if (palette_variant_opt) |variant| {
            return variant.PLTE;
        }

        return null;
    }

    pub fn readForImage(allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !ImageInfo {
        var png = PNG.init(allocator);
        defer png.deinit();

        try png.read(inStream, seekStream, pixelsOpt);

        var imageInfo = ImageInfo{};
        imageInfo.width = png.header.width;
        imageInfo.height = png.header.height;
        imageInfo.pixel_format = png.pixel_format;

        return imageInfo;
    }

    pub fn read(self: *Self, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        var magicNumberBuffer: [8]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        if (!std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader)) {
            return errors.ImageError.InvalidMagicHeader;
        }

        while (try self.readChunk(inStream)) {}

        if (!self.validateBitDepth()) {
            return errors.PngError.InvalidBitDepth;
        }

        switch (self.header.color_type) {
            .Grayscale => {
                self.pixel_format = switch (self.header.bit_depth) {
                    1 => PixelFormat.Grayscale1,
                    2 => PixelFormat.Grayscale2,
                    4 => PixelFormat.Grayscale4,
                    8 => PixelFormat.Grayscale8,
                    16 => PixelFormat.Grayscale16,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                };
            },
            .Truecolor => {
                self.pixel_format = switch (self.header.bit_depth) {
                    8 => PixelFormat.Rgb24,
                    16 => PixelFormat.Rgb48,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                };
            },
            .Indexed => {
                self.pixel_format = switch (self.header.bit_depth) {
                    1 => PixelFormat.Bpp1,
                    2 => PixelFormat.Bpp2,
                    4 => PixelFormat.Bpp4,
                    8 => PixelFormat.Bpp8,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                };
            },
            .GrayscaleAlpha => {
                self.pixel_format = switch (self.header.bit_depth) {
                    8 => PixelFormat.Grayscale8Alpha,
                    16 => PixelFormat.Grayscale16Alpha,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                };
            },
            .TruecolorAlpha => {
                self.pixel_format = switch (self.header.bit_depth) {
                    8 => PixelFormat.Rgba32,
                    16 => PixelFormat.Rgba64,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                };
            },
        }

        pixelsOpt.* = try color.ColorStorage.init(self.allocator, self.pixel_format, self.header.width * self.header.height);

        if (pixelsOpt.*) |*pixels| {
            if (self.header.color_type == .Indexed) {
                if (self.getPalette()) |palette_chunk| {
                    switch (pixels.*) {
                        .Bpp1 => |instance| {
                            std.mem.copy(color.Color, instance.palette, palette_chunk.palette);
                        },
                        .Bpp2 => |instance| {
                            std.mem.copy(color.Color, instance.palette, palette_chunk.palette);
                        },
                        .Bpp4 => |instance| {
                            std.mem.copy(color.Color, instance.palette, palette_chunk.palette);
                        },
                        .Bpp8 => |instance| {
                            std.mem.copy(color.Color, instance.palette, palette_chunk.palette);
                        },
                        else => {
                            return error.NotIndexedPixelFormat;
                        },
                    }
                }
            }
            var decompression_context = DecompressionContext{};
            decompression_context.pixels = pixels;

            // With standard interlace method, we can allocate the filter once.
            // When doing Adam7 interlacing, the filter will be reinit on each pass
            if (self.header.interlace_method == .Standard) {
                const line_stride = (((self.header.width * self.header.bit_depth + 31) & ~@as(usize, 31)) / 8) * self.header.color_type.getChannelCount();
                decompression_context.filter = try PngFilter.init(self.allocator, line_stride, self.header.bit_depth * self.header.color_type.getChannelCount());
            }
            defer decompression_context.filter.deinit(self.allocator);

            decompression_context.pass = -1;
            decompression_context.x = self.header.width;
            decompression_context.y = self.header.height;

            decompression_context.compressed_data = std.ArrayList(u8).init(self.allocator);
            defer decompression_context.compressed_data.deinit();

            // Concatenate all IDAT chunks into a single buffer
            for (self.chunks.span()) |chunk| {
                if (chunk.getChunkID() == IDAT.ChunkID) {
                    try decompression_context.compressed_data.appendSlice(chunk.IDAT.data);
                }
            }

            try self.readPixelsFromCompressedData(&decompression_context);
        } else {
            return errors.ImageError.UnsupportedPixelFormat;
        }
    }

    fn readChunk(self: *Self, inStream: ImageInStream) !bool {
        const chunk_size = try inStream.readIntBig(u32);

        var chunk_type: [4]u8 = undefined;
        _ = try inStream.read(chunk_type[0..]);

        var read_buffer = try self.allocator.alloc(u8, chunk_size);
        errdefer self.allocator.free(read_buffer);

        _ = try inStream.read(read_buffer);

        const read_crc = try inStream.readIntBig(u32);

        var crc_hash = crc.Crc32.init();
        crc_hash.update(chunk_type[0..]);
        crc_hash.update(read_buffer[0..]);

        const computed_crc = crc_hash.final();

        if (computed_crc != read_crc) {
            return errors.PngError.InvalidCRC;
        }

        var found = false;
        var deallocate_buffer = true;
        var continue_reading = true;

        const read_chunk_id = utils.toMagicNumberBig(chunk_type[0..]);

        // TODO: fix the bug in Zig to make this works
        // inline for (AllChunks) |chunkInfo| {
        //     const typeChunkID = @field(chunkInfo.chunk_type, "ChunkID");

        //     if (read_chunk_id == typeChunkID) {
        //         found = true;

        //         if (read_chunk_id == IHDR.ChunkID) {
        //             deallocate_buffer = try self.header.read(self.allocator, read_buffer);
        //         } else if (read_chunk_id == IEND.ChunkID) {
        //             continue_reading = false;
        //         } else if (chunkInfo.store) {
        //             const finalChunk = try self.chunks.addOne();
        //             finalChunk.* = @unionInit(ChunkVariant, @typeName(chunkInfo.chunk_type), undefined);
        //             deallocate_buffer = try @field(finalChunk, @typeName(chunkInfo.chunk_type)).read(self.allocator, read_buffer);
        //         }
        //         break;
        //     }
        // }

        // Remove this when the code below works
        switch (read_chunk_id) {
            IHDR.ChunkID => {
                deallocate_buffer = try self.header.read(self.allocator, read_buffer);
                found = true;
            },
            IEND.ChunkID => {
                continue_reading = false;
                found = true;
            },
            PLTE.ChunkID => {
                const plteChunk = try self.chunks.addOne();
                plteChunk.* = @unionInit(ChunkVariant, PLTE.ChunkType, undefined);
                deallocate_buffer = try @field(plteChunk, PLTE.ChunkType).read(self.allocator, read_buffer);
                found = true;
            },
            gAMA.ChunkID => {
                const gammaChunk = try self.chunks.addOne();
                gammaChunk.* = @unionInit(ChunkVariant, gAMA.ChunkType, undefined);
                deallocate_buffer = try @field(gammaChunk, gAMA.ChunkType).read(self.allocator, read_buffer);
                found = true;
            },
            IDAT.ChunkID => {
                const dataChunk = try self.chunks.addOne();
                dataChunk.* = @unionInit(ChunkVariant, IDAT.ChunkType, undefined);
                deallocate_buffer = try @field(dataChunk, IDAT.ChunkType).read(self.allocator, read_buffer);
                found = true;
            },
            else => {},
        }

        if (deallocate_buffer) {
            self.allocator.free(read_buffer);
        }

        const chunkIsCritical = (chunk_type[0] & (1 << 5)) == 0;

        if (chunkIsCritical and !found) {
            return errors.PngError.InvalidChunk;
        }

        return continue_reading;
    }

    fn readPixelsFromCompressedData(self: Self, context: *DecompressionContext) !void {
        var dataStream = std.io.fixedBufferStream(context.compressed_data.items);

        var uncompressStream = try std.compress.zlib.zlibStream(self.allocator, dataStream.reader());
        defer uncompressStream.deinit();

        const finalData = try uncompressStream.reader().readAllAlloc(self.allocator, std.math.maxInt(usize));
        defer self.allocator.free(finalData);

        var finalDataStream = std.io.fixedBufferStream(finalData);

        switch (self.header.interlace_method) {
            .Standard => try self.readPixelsNonInterlaced(context, &finalDataStream, &finalDataStream.reader()),
            .Adam7 => try self.readPixelsInterlaced(context, &finalDataStream, &finalDataStream.reader()),
        }
    }

    fn readPixelsNonInterlaced(self: Self, context: *DecompressionContext, pixel_stream_source: anytype, pixel_stream: anytype) !void {
        var scanline = try self.allocator.alloc(u8, context.filter.line_stride);
        defer self.allocator.free(scanline);

        var pixel_current_pos = try pixel_stream_source.getPos();
        const pixel_end_pos = try pixel_stream_source.getEndPos();

        const pixels_length = context.pixels.len();

        while (pixel_current_pos < pixel_end_pos and context.pixels_index < pixels_length) {
            const filter_type = try pixel_stream.readByte();

            _ = try pixel_stream.readAll(scanline);

            const filter_slice = context.filter.getSlice();

            try context.filter.decode(@intToEnum(FilterType, filter_type), scanline);

            var index: usize = 0;
            var x: usize = 0;

            switch (context.pixels.*) {
                .Grayscale1 => |data| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 0;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            data[context.pixels_index].value = @intCast(u1, (current_byte >> @intCast(u3, (7 - bit))) & 1);

                            x += 1;
                            bit += 1;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Grayscale2 => |data| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 1;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            data[context.pixels_index].value = @intCast(u2, (current_byte >> @intCast(u3, (7 - bit))) & 0b00000011);

                            x += 1;
                            bit += 2;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Grayscale4 => |data| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 3;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            data[context.pixels_index].value = @intCast(u4, (current_byte >> @intCast(u3, (7 - bit))) & 0b00001111);

                            x += 1;
                            bit += 4;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Grayscale8 => |data| {
                    while (index < filter_slice.len and context.pixels_index < pixels_length and x < self.header.width) {
                        data[context.pixels_index].value = filter_slice[index];

                        index += 1;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Grayscale16 => |data| {
                    while (index < filter_slice.len and context.pixels_index < pixels_length and x < self.header.width) {
                        const read_value = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[index]));
                        data[context.pixels_index].value = read_value;

                        index += 2;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Rgb24 => |data| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        data[context.pixels_index].R = filter_slice[count];
                        data[context.pixels_index].G = filter_slice[count + 1];
                        data[context.pixels_index].B = filter_slice[count + 2];

                        count += 3;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Rgb48 => |data| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        data[context.pixels_index].R = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count]));
                        data[context.pixels_index].G = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 2]));
                        data[context.pixels_index].B = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 4]));

                        count += 6;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Bpp1 => |indexed| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 0;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            indexed.indices[context.pixels_index] = @intCast(u1, (current_byte >> @intCast(u3, (7 - bit))) & 1);

                            x += 1;
                            bit += 1;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Bpp2 => |indexed| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 1;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            indexed.indices[context.pixels_index] = @intCast(u2, (current_byte >> @intCast(u3, (7 - bit))) & 0b00000011);

                            x += 1;
                            bit += 2;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Bpp4 => |indexed| {
                    while (index < filter_slice.len) : (index += 1) {
                        const current_byte = filter_slice[index];

                        var bit: usize = 3;
                        while (context.pixels_index < pixels_length and x < self.header.width and bit < 8) {
                            indexed.indices[context.pixels_index] = @intCast(u4, (current_byte >> @intCast(u3, (7 - bit))) & 0b00001111);

                            x += 1;
                            bit += 4;
                            context.pixels_index += 1;
                        }
                    }
                },
                .Bpp8 => |indexed| {
                    while (index < filter_slice.len and context.pixels_index < pixels_length and x < self.header.width) {
                        indexed.indices[context.pixels_index] = filter_slice[index];

                        index += 1;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Grayscale8Alpha => |grey_alpha| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        grey_alpha[context.pixels_index].value = filter_slice[count];
                        grey_alpha[context.pixels_index].alpha = filter_slice[count + 1];

                        count += 2;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Grayscale16Alpha => |grey_alpha| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        grey_alpha[context.pixels_index].value = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count]));
                        grey_alpha[context.pixels_index].alpha = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 2]));

                        count += 4;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Rgba32 => |data| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        data[context.pixels_index].R = filter_slice[count];
                        data[context.pixels_index].G = filter_slice[count + 1];
                        data[context.pixels_index].B = filter_slice[count + 2];
                        data[context.pixels_index].A = filter_slice[count + 3];

                        count += 4;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                .Rgba64 => |data| {
                    var count: usize = 0;
                    const count_end = filter_slice.len;
                    while (count < count_end and context.pixels_index < pixels_length and x < self.header.width) {
                        data[context.pixels_index].R = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count]));
                        data[context.pixels_index].G = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 2]));
                        data[context.pixels_index].B = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 4]));
                        data[context.pixels_index].A = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &filter_slice[count + 6]));

                        count += 8;
                        x += 1;
                        context.pixels_index += 1;
                    }
                },
                else => {
                    return errors.ImageError.UnsupportedPixelFormat;
                },
            }

            pixel_current_pos = try pixel_stream_source.getPos();
        }
    }

    const InterlacedStartingWidth = [7]usize{ 0, 4, 0, 2, 0, 1, 0 };
    const InterlacedStartingHeight = [7]usize{ 0, 0, 4, 0, 2, 0, 1 };
    const InterlacedWidthIncrement = [7]usize{ 8, 8, 4, 4, 2, 2, 1 };
    const InterlacedHeightIncrement = [7]usize{ 8, 8, 8, 4, 4, 2, 2 };
    const InterlacedBlockWidth = [7]usize{ 8, 4, 4, 2, 2, 1, 1 };
    const InterlacedBlockHeight = [7]usize{ 8, 8, 4, 4, 2, 2, 1 };

    fn readPixelsInterlaced(self: Self, context: *DecompressionContext, pixel_stream_source: anytype, pixel_stream: anytype) !void {
        var scanline: ?[]u8 = null;
        defer {
            if (scanline) |scan| {
                self.allocator.free(scan);
            }
        }
        var pixel_current_pos = try pixel_stream_source.getPos();
        const pixel_end_pos = try pixel_stream_source.getEndPos();

        const pixel_stride = self.header.bit_depth * self.header.color_type.getChannelCount();
        const bytes_per_pixel = std.math.max(1, pixel_stride / 8);
        const bit_per_bytes = bytes_per_pixel * 8;

        while (context.pass < 7 and pixel_current_pos < pixel_end_pos) {
            var current_pass = @intCast(usize, @bitCast(u8, context.pass));

            if (context.y >= self.header.height) {
                context.pass += 1;
                current_pass = @intCast(usize, @bitCast(u8, context.pass));

                if (current_pass < 7) {
                    const current_pass_width = std.math.max(1, self.header.width / InterlacedWidthIncrement[current_pass]);
                    const line_stride = std.mem.alignForward(current_pass_width * self.header.bit_depth * self.header.color_type.getChannelCount(), 8) / 8;

                    if (context.filter.context.len > 0) {
                        context.filter.deinit(self.allocator);
                    }

                    context.filter = try PngFilter.init(self.allocator, line_stride, pixel_stride);

                    if (scanline) |scan| {
                        self.allocator.free(scan);
                    }

                    scanline = try self.allocator.alloc(u8, context.filter.line_stride);
                } else {
                    continue;
                }

                context.y = InterlacedStartingHeight[@intCast(usize, context.pass)];
            }

            const filter_type = try pixel_stream.readByte();

            _ = try pixel_stream.readAll(scanline.?);

            const filter_slice = context.filter.getSlice();

            try context.filter.decode(@intToEnum(FilterType, filter_type), scanline.?);

            var slice_index: usize = 0;
            var pixel_index: usize = 0;
            var bit_index: usize = 0;

            const current_pass_width = self.header.width / InterlacedWidthIncrement[current_pass];

            context.x = InterlacedStartingWidth[current_pass];

            while (slice_index < filter_slice.len and context.x < self.header.width and pixel_index < current_pass_width) {
                const block_width = std.math.min(InterlacedBlockWidth[current_pass], self.header.width - context.x);
                const block_height = std.math.min(InterlacedBlockHeight[current_pass], self.header.height - context.y);

                try self.writePixelInterlaced(filter_slice[slice_index..], pixel_index, context, block_width, block_height);

                pixel_index += 1;
                bit_index += pixel_stride;
                if ((bit_index % bit_per_bytes) == 0) {
                    slice_index += bytes_per_pixel;
                }
                context.x += InterlacedWidthIncrement[current_pass];
            }

            pixel_current_pos = try pixel_stream_source.getPos();

            context.y += InterlacedHeightIncrement[current_pass];
        }
    }

    fn writePixelInterlaced(self: Self, bytes: []const u8, pixel_index: usize, context: *DecompressionContext, block_width: usize, block_height: usize) !void {
        switch (context.pixels.*) {
            .Grayscale1 => |data| {
                const bit = (pixel_index & 0b111);
                const value = @intCast(u1, (bytes[0] >> @intCast(u3, 7 - bit)) & 1);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index].value = value;
                            }
                        }
                    }
                }
            },
            .Grayscale2 => |data| {
                const bit = (pixel_index & 0b011) * 2 + 1;
                const value = @intCast(u2, (bytes[0] >> @intCast(u3, (7 - bit))) & 0b00000011);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index].value = value;
                            }
                        }
                    }
                }
            },
            .Grayscale4 => |data| {
                const bit = (pixel_index & 0b1) * 4 + 3;
                const value = @intCast(u4, (bytes[0] >> @intCast(u3, (7 - bit))) & 0b00001111);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index].value = value;
                            }
                        }
                    }
                }
            },
            .Grayscale8 => |data| {
                const value = bytes[0];

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index].value = value;
                            }
                        }
                    }
                }
            },
            .Grayscale16 => |data| {
                const value = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, bytes));

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index].value = value;
                            }
                        }
                    }
                }
            },
            .Rgb24 => |data| {
                const pixel = color.Rgb24{
                    .R = bytes[0],
                    .G = bytes[1],
                    .B = bytes[2],
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index] = pixel;
                            }
                        }
                    }
                }
            },
            .Rgb48 => |data| {
                const pixel = color.Rgb48{
                    .R = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[0])),
                    .G = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[2])),
                    .B = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[4])),
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index] = pixel;
                            }
                        }
                    }
                }
            },
            .Bpp1 => |indexed| {
                const bit = (pixel_index & 0b111);
                const value = @intCast(u1, (bytes[0] >> @intCast(u3, 7 - bit)) & 1);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < indexed.indices.len) {
                                indexed.indices[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Bpp2 => |indexed| {
                const bit = (pixel_index & 0b011) * 2 + 1;
                const value = @intCast(u2, (bytes[0] >> @intCast(u3, (7 - bit))) & 0b00000011);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < indexed.indices.len) {
                                indexed.indices[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Bpp4 => |indexed| {
                const bit = (pixel_index & 0b1) * 4 + 3;
                const value = @intCast(u4, (bytes[0] >> @intCast(u3, (7 - bit))) & 0b00001111);

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < indexed.indices.len) {
                                indexed.indices[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Bpp8 => |indexed| {
                const value = bytes[0];

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < indexed.indices.len) {
                                indexed.indices[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Grayscale8Alpha => |grey_alpha| {
                const value = color.Grayscale8Alpha{
                    .value = bytes[0],
                    .alpha = bytes[1],
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < grey_alpha.len) {
                                grey_alpha[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Grayscale16Alpha => |grey_alpha| {
                const value = color.Grayscale16Alpha{
                    .value = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[0])),
                    .alpha = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[2])),
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < grey_alpha.len) {
                                grey_alpha[data_index] = value;
                            }
                        }
                    }
                }
            },
            .Rgba32 => |data| {
                const pixel = color.Rgba32{
                    .R = bytes[0],
                    .G = bytes[1],
                    .B = bytes[2],
                    .A = bytes[3],
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index] = pixel;
                            }
                        }
                    }
                }
            },
            .Rgba64 => |data| {
                const pixel = color.Rgba64{
                    .R = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[0])),
                    .G = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[2])),
                    .B = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[4])),
                    .A = std.mem.readIntBig(u16, @ptrCast(*const [2]u8, &bytes[6])),
                };

                var height: usize = 0;
                while (height < block_height) : (height += 1) {
                    if ((context.y + height) < self.header.height) {
                        var width: usize = 0;

                        var scanline = (context.y + height) * self.header.width;

                        while (width < block_width) : (width += 1) {
                            const data_index = scanline + context.x + width;
                            if ((context.x + width) < self.header.width and data_index < data.len) {
                                data[data_index] = pixel;
                            }
                        }
                    }
                }
            },
            else => {
                return errors.ImageError.UnsupportedPixelFormat;
            },
        }
    }

    fn validateBitDepth(self: Self) bool {
        const validBitDepths = ValidBitDepths(self.header.color_type);

        for (validBitDepths) |bitDepth| {
            if (self.header.bit_depth == bitDepth) {
                return true;
            }
        }

        return false;
    }
};
