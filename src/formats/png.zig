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
};

// const CriticalChunks = struct {
//     // Image header
//     pub const IHDR = "IHDR";
//     // Palette table
//     pub const PLTE = "PLTE";
//     // Image data chunk
//     pub const IDAT = "IDAT";
//     // Image trailer
//     pub const IEND = "IEND";
// };

// const AncillaryChuncks = struct {
//     // Transparency information
//     pub const tRNS = "tRNS";
//     // Color space information
//     pub const cHRM = "cHRM";
//     pub const gAMA = "gAMA";
//     pub const iCCP = "iCPP";
//     pub const sBIT = "sBIT";
//     pub const sRGB = "sRGB";
//     // Textual information
//     pub const iTXt = "iTXt";
//     pub const tEXT = "tEXT";
//     pub const zTXt = "zTXt";
//     // Miscellaneous information
//     pub const bKGD = "bKGD";
//     pub const hIST = "hIST";
//     pub const pHYs = "pHYs";
//     pub const sPLT = "sPLT";
//     // Time information
//     pub const tIME = "tIME";
// };

const Chunk = packed struct {
    length: u32 = 0,
    chunkType: [4]u8 = undefined,
    data: []u8 = undefined,
    crc: u32 = undefined,
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
    pixel_format: PixelFormat = undefined,

    const Self = @This();

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

    pub fn formatDetect(inStream: *ImageInStream, seekStream: *ImageSeekStream) !bool {
        var magicNumberBuffer: [8]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        return std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader);
    }

    pub fn readForImage(allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixelsOpt: *?color.ColorStorage) !ImageInfo {
        var png = PNG{};

        try png.read(allocator, inStream, seekStream, pixelsOpt);

        var imageInfo = ImageInfo{};
        imageInfo.width = png.header.width;
        imageInfo.height = png.header.height;
        imageInfo.pixel_format = png.pixel_format;

        return imageInfo;
    }

    pub fn read(self: *Self, allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        var magicNumberBuffer: [8]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        if (!std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader)) {
            return errors.ImageError.InvalidMagicHeader;
        }

        const chunkSize = try inStream.readIntBig(u32);

        if (chunkSize != @sizeOf(IHDR)) {
            return errors.PngError.InvalidChunk;
        }

        var chunkType: [4]u8 = undefined;
        _ = try inStream.read(chunkType[0..]);

        if (!std.mem.eql(u8, chunkType[0..], IHDR.ChunkType)) {
            return errors.PngError.InvalidChunk;
        }

        var headerBuffer: [@sizeOf(IHDR)]u8 = undefined;
        _ = try inStream.read(headerBuffer[0..]);

        var slice_stream = std.io.SliceInStream.init(&headerBuffer);

        self.header = try utils.readStructBig(@ptrCast(*ImageInStream, &slice_stream.stream), IHDR);

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

        const headerCrc = try inStream.readIntBig(u32);

        var crcHash = crc.Crc32.init();
        crcHash.update(chunkType[0..]);
        crcHash.update(headerBuffer[0..]);

        const computedCrc = crcHash.final();

        if (computedCrc != headerCrc) {
            return errors.PngError.InvalidCRC;
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
