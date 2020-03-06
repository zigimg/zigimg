const Allocator = std.mem.Allocator;
const File = std.fs.File;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageInStream = image.ImageInStream;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const fs = std.fs;
const image = @import("../image.zig");
const io = std.io;
const mem = std.mem;
const path = std.fs.path;
const std = @import("std");
usingnamespace @import("../utils.zig");

const BitmapMagicHeader = [_]u8{ 'B', 'M' };

pub const BitmapFileHeader = packed struct {
    magicHeader: [2]u8,
    size: u32,
    reserved: u32,
    pixelOffset: u32,
};

pub const CompressionMethod = enum(u32) {
    None = 0,
    Rle8 = 1,
    Rle4 = 2,
    Bitfields = 3,
    Jpeg = 4,
    Png = 5,
    AlphaBitFields = 6,
    Cmyk = 11,
    CmykRle8 = 12,
    CmykRle4 = 13,
};

pub const BitmapColorSpace = enum(u32) {
    CalibratedRgb = 0,
    sRgb = toMagicNumberBig("sRGB"),
    WindowsColorSpace = toMagicNumberBig("Win "),
    ProfileLinked = toMagicNumberBig("LINK"),
    ProfileEmbedded = toMagicNumberBig("MBED"),
};

pub const BitmapIntent = enum(u32) {
    Business = 1,
    Graphics = 2,
    Images = 4,
    AbsoluteColorimetric = 8,
};

pub const CieXyz = packed struct {
    x: u32 = 0, // TODO: Use FXPT2DOT30
    y: u32 = 0,
    z: u32 = 0,
};

pub const CieXyzTriple = packed struct {
    red: CieXyz = CieXyz{},
    green: CieXyz = CieXyz{},
    blue: CieXyz = CieXyz{},
};

pub const BitmapInfoHeaderWindows31 = packed struct {
    headerSize: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    colorPlane: u16 = 0,
    bitCount: u16 = 0,
    compressionMethod: CompressionMethod = CompressionMethod.None,
    imageRawSize: u32 = 0,
    horizontalResolution: u32 = 0,
    verticalResolution: u32 = 0,
    paletteSize: u32 = 0,
    importantColors: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeaderV4 = packed struct {
    headerSize: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    colorPlane: u16 = 0,
    bitCount: u16 = 0,
    compressionMethod: CompressionMethod = CompressionMethod.None,
    imageRawSize: u32 = 0,
    horizontalResolution: u32 = 0,
    verticalResolution: u32 = 0,
    paletteSize: u32 = 0,
    importantColors: u32 = 0,
    redMask: u32 = 0,
    greenMask: u32 = 0,
    blueMask: u32 = 0,
    alphaMask: u32 = 0,
    colorSpace: BitmapColorSpace = BitmapColorSpace.sRgb,
    cieEndPoints: CieXyzTriple = CieXyzTriple{},
    gammaRed: u32 = 0,
    gammaGreen: u32 = 0,
    gammaBlue: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeaderV5 = packed struct {
    headerSize: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    colorPlane: u16 = 0,
    bitCount: u16 = 0,
    compressionMethod: CompressionMethod = CompressionMethod.None,
    imageRawSize: u32 = 0,
    horizontalResolution: u32 = 0,
    verticalResolution: u32 = 0,
    paletteSize: u32 = 0,
    importantColors: u32 = 0,
    redMask: u32 = 0,
    greenMask: u32 = 0,
    blueMask: u32 = 0,
    alphaMask: u32 = 0,
    colorSpace: BitmapColorSpace = BitmapColorSpace.sRgb,
    cieEndPoints: CieXyzTriple = CieXyzTriple{},
    gammaRed: u32 = 0,
    gammaGreen: u32 = 0,
    gammaBlue: u32 = 0,
    intent: BitmapIntent = BitmapIntent.Graphics,
    profileData: u32 = 0,
    profileSize: u32 = 0,
    reserved: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeader = union(enum) {
    Windows31: BitmapInfoHeaderWindows31,
    V4: BitmapInfoHeaderV4,
    V5: BitmapInfoHeaderV5,
};

pub const Bitmap = struct {
    fileHeader: BitmapFileHeader = undefined,
    infoHeader: BitmapInfoHeader = undefined,
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
        return ImageFormat.Bmp;
    }

    pub fn formatDetect(inStream: *ImageInStream, seekStream: *ImageSeekStream) !bool {
        var magicNumberBuffer: [2]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);
        if (std.mem.eql(u8, magicNumberBuffer[0..], BitmapMagicHeader[0..])) {
            return true;
        }

        return false;
    }

    pub fn readForImage(allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var bmp = Self{};

        try bmp.read(allocator, inStream, seekStream, pixels);

        var imageInfo = ImageInfo{};
        imageInfo.width = @intCast(usize, bmp.width());
        imageInfo.height = @intCast(usize, bmp.height());
        imageInfo.pixel_format = bmp.pixel_format;
        return imageInfo;
    }

    pub fn width(self: Self) i32 {
        return switch (self.infoHeader) {
            .Windows31 => |win31| {
                return win31.width;
            },
            .V4 => |v4Header| {
                return v4Header.width;
            },
            .V5 => |v5Header| {
                return v5Header.width;
            },
        };
    }

    pub fn height(self: Self) i32 {
        return switch (self.infoHeader) {
            .Windows31 => |win31| {
                return win31.height;
            },
            .V4 => |v4Header| {
                return v4Header.height;
            },
            .V5 => |v5Header| {
                return v5Header.height;
            },
        };
    }

    pub fn read(self: *Self, allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        // Read file header
        self.fileHeader = try readStructLittle(inStream, BitmapFileHeader);
        if (!mem.eql(u8, self.fileHeader.magicHeader[0..], BitmapMagicHeader[0..])) {
            return errors.ImageError.InvalidMagicHeader;
        }

        // Read header size to figure out the header type, also TODO: Use PeekableStream when I understand how to use it
        const currentHeaderPos = try seekStream.getPos();
        var headerSize = try inStream.readIntLittle(u32);
        try seekStream.seekTo(currentHeaderPos);

        // Read info header
        self.infoHeader = switch (headerSize) {
            BitmapInfoHeaderWindows31.HeaderSize => BitmapInfoHeader{ .Windows31 = try readStructLittle(inStream, BitmapInfoHeaderWindows31) },
            BitmapInfoHeaderV4.HeaderSize => BitmapInfoHeader{ .V4 = try readStructLittle(inStream, BitmapInfoHeaderV4) },
            BitmapInfoHeaderV5.HeaderSize => BitmapInfoHeader{ .V5 = try readStructLittle(inStream, BitmapInfoHeaderV5) },
            else => return errors.ImageError.UnsupportedBitmapType,
        };

        // Read pixel data
        _ = switch (self.infoHeader) {
            .V4 => |v4Header| {
                const pixelWidth = v4Header.width;
                const pixelHeight = v4Header.height;
                self.pixel_format = try getPixelFormat(v4Header.bitCount, v4Header.compressionMethod);

                pixelsOpt.* = try color.ColorStorage.init(allocator, self.pixel_format, @intCast(usize, pixelWidth * pixelHeight));

                if (pixelsOpt.*) |*pixels| {
                    try readPixels(inStream, pixelWidth, pixelHeight, self.pixel_format, pixels);
                }
            },
            .V5 => |v5Header| {
                const pixelWidth = v5Header.width;
                const pixelHeight = v5Header.height;
                self.pixel_format = try getPixelFormat(v5Header.bitCount, v5Header.compressionMethod);

                pixelsOpt.* = try color.ColorStorage.init(allocator, self.pixel_format, @intCast(usize, pixelWidth * pixelHeight));

                if (pixelsOpt.*) |*pixels| {
                    try readPixels(inStream, pixelWidth, pixelHeight, self.pixel_format, pixels);
                }
            },
            else => return errors.ImageError.UnsupportedBitmapType,
        };
    }

    fn getPixelFormat(bitCount: u32, compression: CompressionMethod) !PixelFormat {
        if (bitCount == 32 and compression == CompressionMethod.Bitfields) {
            return PixelFormat.Argb32;
        } else if (bitCount == 24 and compression == CompressionMethod.None) {
            return PixelFormat.Rgb24;
        } else {
            return errors.ImageError.UnsupportedPixelFormat;
        }
    }

    fn readPixels(inStream: *ImageInStream, pixelWidth: i32, pixelHeight: i32, pixelFormat: PixelFormat, pixels: *color.ColorStorage) !void {
        return switch (pixelFormat) {
            PixelFormat.Rgb24 => {
                return readPixelsInternal(pixels.Rgb24, inStream, pixelWidth, pixelHeight);
            },
            PixelFormat.Argb32 => {
                return readPixelsInternal(pixels.Argb32, inStream, pixelWidth, pixelHeight);
            },
            else => {
                return errors.ImageError.UnsupportedPixelFormat;
            },
        };
    }

    fn readPixelsInternal(pixels: var, inStream: *ImageInStream, pixelWidth: i32, pixelHeight: i32) !void {
        const ColorBufferType = @typeInfo(@TypeOf(pixels)).Pointer.child;

        var x: i32 = 0;
        var y: i32 = pixelHeight - 1;
        while (y >= 0) : (y -= 1) {
            const scanline = y * pixelWidth;

            x = 0;
            while (x < pixelWidth) : (x += 1) {
                pixels[@intCast(usize, scanline + x)] = try readStructLittle(inStream, ColorBufferType);
            }
        }
    }
};
