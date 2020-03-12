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

const PNGMagicHeader = "\x89PNG\x0D\x0A\x1A\x0A";

pub const ColorType = packed enum(u8) {
    Grayscale = 0,
    Truecolor = 2,
    Indexed = 3,
    GrayscaleAlpha = 4,
    TruecolorAlpha = 6,
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

    pub fn read(self: *Self, readBuffer: []u8) !bool {
        var stream = std.io.StreamSource{ .buffer = std.io.fixedBufferStream(readBuffer) };
        self.* = try utils.readStructBig(stream.inStream(), Self);
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

    pub fn read(self: *Self, readBuffer: []u8) !bool {
        self.data = readBuffer;
        return false;
    }
};

pub const IEND = packed struct {
    pub const ChunkType = "IEND";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {}

    pub fn read(self: *Self, readBuffer: []u8) !bool {
        return true;
    }
};

pub const gAMA = packed struct {
    iGamma: u32,

    pub const ChunkType = "gAMA";
    pub const ChunkID = utils.toMagicNumberBig(ChunkType);

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {}

    pub fn read(self: *Self, readBuffer: []u8) !bool {
        var stream = std.io.fixedBufferStream(readBuffer);
        self.iGamma = try stream.inStream().readIntBig(u32);
        return true;
    }

    pub fn toGammaExponent(self: Self) f32 {
        return @intToFloat(f32, self.iGamma) / 100000.0;
    }
};

pub const ChunkVariant = union(enum) {
    IDAT: IDAT,
    gAMA: gAMA,

    const Self = @This();

    pub fn deinit(self: Self, allocator: *Allocator) void {
        switch (self) {
            .IDAT => |instance| instance.deinit(allocator),
            .gAMA => |instance| instance.deinit(allocator),
        }
    }

    pub fn getChunkID(self: Self) u32 {
        return switch (self) {
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

// remember, PNG uses network byte order (aka Big Endian)
pub const PNG = struct {
    header: IHDR = undefined,
    chunks: std.ArrayList(ChunkVariant) = undefined,
    pixel_format: PixelFormat = undefined,
    allocator: *Allocator = undefined,

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

    pub fn readForImage(allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !ImageInfo {
        var png = PNG.init(allocator);
        defer png.deinit();

        try png.read(allocator, inStream, seekStream, pixelsOpt);

        var imageInfo = ImageInfo{};
        imageInfo.width = png.header.width;
        imageInfo.height = png.header.height;
        imageInfo.pixel_format = png.pixel_format;

        return imageInfo;
    }

    pub fn read(self: *Self, allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        var magicNumberBuffer: [8]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        if (!std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader)) {
            return errors.ImageError.InvalidMagicHeader;
        }

        while (try self.readChunk(allocator, inStream)) {}

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

        pixelsOpt.* = try color.ColorStorage.init(allocator, self.pixel_format, self.header.width * self.header.height);
    }

    fn readChunk(self: *Self, allocator: *Allocator, inStream: ImageInStream) !bool {
        const chunkSize = try inStream.readIntBig(u32);

        var chunkType: [4]u8 = undefined;
        _ = try inStream.read(chunkType[0..]);

        var readBuffer = try allocator.alloc(u8, chunkSize);
        errdefer allocator.free(readBuffer);

        _ = try inStream.read(readBuffer);

        const readCrc = try inStream.readIntBig(u32);

        var crcHash = crc.Crc32.init();
        crcHash.update(chunkType[0..]);
        crcHash.update(readBuffer[0..]);

        const computedCrc = crcHash.final();

        if (computedCrc != readCrc) {
            return errors.PngError.InvalidCRC;
        }

        var found = false;
        var deallocateBuffer = true;
        var continueReading = true;

        const readChunkID = utils.toMagicNumberBig(chunkType[0..]);

        // TODO: fix the bug in Zig to make this works
        // inline for (AllChunks) |chunkInfo| {
        //     const typeChunkID = @field(chunkInfo.chunk_type, "ChunkID");

        //     if (readChunkID == typeChunkID) {
        //         found = true;

        //         if (readChunkID == IHDR.ChunkID) {
        //             deallocateBuffer = try self.header.read(readBuffer);
        //         } else if (readChunkID == IEND.ChunkID) {
        //             continueReading = false;
        //         } else if (chunkInfo.store) {
        //             const finalChunk = try self.chunks.addOne();
        //             finalChunk.* = @unionInit(ChunkVariant, @typeName(chunkInfo.chunk_type), undefined);
        //             deallocateBuffer = try @field(finalChunk, @typeName(chunkInfo.chunk_type)).read(readBuffer);
        //         }
        //         break;
        //     }
        // }

        // Remove this when the code below works
        switch (readChunkID) {
            IHDR.ChunkID => {
                deallocateBuffer = try self.header.read(readBuffer);
                found = true;
            },
            IEND.ChunkID => {
                continueReading = false;
                found = true;
            },
            gAMA.ChunkID => {
                const gammaChunk = try self.chunks.addOne();
                gammaChunk.* = @unionInit(ChunkVariant, gAMA.ChunkType, undefined);
                deallocateBuffer = try @field(gammaChunk, gAMA.ChunkType).read(readBuffer);
                found = true;
            },
            IDAT.ChunkID => {
                const dataChunk = try self.chunks.addOne();
                dataChunk.* = @unionInit(ChunkVariant, IDAT.ChunkType, undefined);
                deallocateBuffer = try @field(dataChunk, IDAT.ChunkType).read(readBuffer);
                found = true;
            },
            else => {},
        }

        if (deallocateBuffer) {
            allocator.free(readBuffer);
        }

        const chunkIsCritical = (chunkType[0] & (1 << 5)) == 0;

        if (chunkIsCritical and !found) {
            return errors.PngError.InvalidChunk;
        }

        return continueReading;
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
