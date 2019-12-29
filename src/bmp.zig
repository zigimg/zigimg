const Allocator = @import("std").mem.Allocator;
const color = @import("color.zig");
const File = @import("std").fs.File;
const errors = @import("errors.zig");
const fs = @import("std").fs;
const io = @import("std").io;
const mem = @import("std").mem;
const path = @import("std").fs.path;
usingnamespace @import("utils.zig");
usingnamespace @import("pixel_format.zig");

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
    fileHeader: BitmapFileHeader,
    infoHeader: BitmapInfoHeader,
    pixels: ?[]color.Color,
    allocator: *Allocator,

    const BitmapInStream = io.InStream(anyerror);
    const BitmapSeekStream = io.SeekableStream(anyerror, anyerror);

    pub fn init(allocator: *Allocator) Bitmap {
        return Bitmap{
            .fileHeader = undefined,
            .infoHeader = undefined,
            .pixels = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Bitmap) void {
        if (self.pixels) |pixels| {
            self.allocator.free(pixels);
            self.pixels = null;
        }
    }

    //TODO: maybe uniformize I/O once we support one that more file format
    pub fn fromFile(allocator: *Allocator, filePath: []const u8) !Bitmap {
        var result = init(allocator);

        var absolutePath = try path.resolve(allocator, &[_][]const u8{filePath});
        defer allocator.free(absolutePath);

        var file = try fs.openFileAbsolute(absolutePath, File.OpenFlags{});
        defer file.close();

        var fileInStream = file.inStream();
        var fileSeekStream = file.seekableStream();
        // TODO: Replace with something better when available
        try internalRead(@ptrCast(*BitmapInStream, &fileInStream.stream), @ptrCast(*BitmapSeekStream, &fileSeekStream.stream), &result);

        return result;
    }

    pub fn fromMemory(allocator: *Allocator, buffer: []const u8) !Bitmap {
        var result = init(allocator);

        var memoryInStream = io.SliceSeekableInStream.init(buffer);
        // TODO: Replace with something better when available
        try internalRead(@ptrCast(*BitmapInStream, &memoryInStream.stream), @ptrCast(*BitmapSeekStream, &memoryInStream.seekable_stream), &result);

        return result;
    }

    pub fn width(self: *Bitmap) i32 {
        return switch(self.infoHeader) {
            .Windows31 => |win31| {
                return win31.width;
            },
            .V4 => |v4Header| {
                return v4Header.width;
            },
            .V5 => |v5Header| {
                return v5Header.width;
            }
        };
    }

    pub fn height(self: *Bitmap) i32 {
         return switch(self.infoHeader) {
            .Windows31 => |win31| {
                return win31.height;
            },
            .V4 => |v4Header| {
                return v4Header.height;
            },
            .V5 => |v5Header| {
                return v5Header.height;
            }
        };
    }

    pub fn allocPixels(self: *Bitmap, size: usize) !void {
        self.pixels = try self.allocator.alloc(color.Color, size);
    }

    fn internalRead(inStream: *BitmapInStream, seekStream: *BitmapSeekStream, bitmap: *Bitmap) !void {
        // Read file header
        bitmap.fileHeader = try readStructLittle(inStream, BitmapFileHeader);
        if (!mem.eql(u8, bitmap.fileHeader.magicHeader[0..], BitmapMagicHeader[0..])) {
            return errors.ImageError.InvalidMagicHeader;
        }

        // Read header size to figure out the header type, also TODO: Use PeekableStream when I understand how to use it
        const currentHeaderPos = try seekStream.getPos();
        var headerSize = try inStream.readIntLittle(u32);
        try seekStream.seekTo(currentHeaderPos);

        // Read info header
        bitmap.infoHeader = switch (headerSize) {
            BitmapInfoHeaderWindows31.HeaderSize => BitmapInfoHeader{ .Windows31 = try readStructLittle(inStream, BitmapInfoHeaderWindows31) },
            BitmapInfoHeaderV4.HeaderSize => BitmapInfoHeader{ .V4 = try readStructLittle(inStream, BitmapInfoHeaderV4) },
            BitmapInfoHeaderV5.HeaderSize => BitmapInfoHeader{ .V5 = try readStructLittle(inStream, BitmapInfoHeaderV5) },
            else => return errors.ImageError.UnsupportedBitmapType,
        };

        // Read pixel data
        _ = switch (bitmap.infoHeader) {
            .V4 => |v4Header| {
                const pixelWidth = v4Header.width;
                const pixelHeight = v4Header.height;
                const pixelFormat = try getPixelFormat(v4Header.bitCount, v4Header.compressionMethod);

                try readPixels(inStream, bitmap, pixelWidth, pixelHeight, pixelFormat);
            },
            .V5 => |v5Header| {
                const pixelWidth = v5Header.width;
                const pixelHeight = v5Header.height;
                const pixelFormat = try getPixelFormat(v5Header.bitCount, v5Header.compressionMethod);

                try readPixels(inStream, bitmap, pixelWidth, pixelHeight, pixelFormat);
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

    fn readPixels(inStream: *BitmapInStream, bitmap: *Bitmap, pixelWidth: i32, pixelHeight: i32, pixelFormat: PixelFormat) !void {
        _ = switch (pixelFormat) {
            PixelFormat.Rgb24 => {
                const pixelCount = pixelWidth * pixelHeight;
                try bitmap.allocPixels(@intCast(usize, pixelCount));

                var colorBuffer: color.Rgb24 = undefined;

                if (bitmap.pixels) |pixels| {
                    var x: i32 = 0;
                    var y: i32 = pixelHeight - 1;
                    while (y >= 0) : (y -= 1) {
                        const scanline: i32 = y * pixelWidth;

                        x = 0;
                        while (x < pixelWidth) : (x += 1) {
                            colorBuffer = try readStructLittle(inStream, color.Rgb24);
                            pixels[@intCast(usize, scanline + x)] = colorBuffer.toColor();
                        }
                    }
                } else {
                    return errors.ImageError.AllocationFailed;
                }
            },
            PixelFormat.Argb32 => {
                const pixelCount = pixelWidth * pixelHeight;
                try bitmap.allocPixels(@intCast(usize, pixelCount));

                var colorBuffer: color.Argb32 = undefined;

                if (bitmap.pixels) |pixels| {
                    var x: i32 = 0;
                    var y: i32 = pixelHeight - 1;
                    while (y >= 0) : (y -= 1) {
                        const scanline = y * pixelWidth;

                        x = 0;
                        while (x < pixelWidth) : (x += 1) {
                            colorBuffer = try readStructLittle(inStream, color.Argb32);
                            pixels[@intCast(usize, scanline + x)] = colorBuffer.toColor();
                        }
                    }
                } else {
                    return errors.ImageError.AllocationFailed;
                }
            },
            else => {
                return errors.ImageError.UnsupportedPixelFormat;
            },
        };
    }
};
