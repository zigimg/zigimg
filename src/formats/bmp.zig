const Allocator = std.mem.Allocator;
const File = std.fs.File;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageReader = image.ImageReader;
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
    magic_header: [2]u8,
    size: u32,
    reserved: u32,
    pixel_offset: u32,
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
    header_size: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    color_plane: u16 = 0,
    bit_count: u16 = 0,
    compression_method: CompressionMethod = CompressionMethod.None,
    image_raw_size: u32 = 0,
    horizontal_resolution: u32 = 0,
    vertical_resolution: u32 = 0,
    palette_size: u32 = 0,
    important_colors: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeaderV4 = packed struct {
    header_size: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    color_plane: u16 = 0,
    bit_count: u16 = 0,
    compression_method: CompressionMethod = CompressionMethod.None,
    image_raw_size: u32 = 0,
    horizontal_resolution: u32 = 0,
    vertical_resolution: u32 = 0,
    palette_size: u32 = 0,
    important_colors: u32 = 0,
    red_mask: u32 = 0,
    green_mask: u32 = 0,
    blue_mask: u32 = 0,
    alpha_mask: u32 = 0,
    color_space: BitmapColorSpace = BitmapColorSpace.sRgb,
    cie_end_points: CieXyzTriple = CieXyzTriple{},
    gamma_red: u32 = 0,
    gamma_green: u32 = 0,
    gamma_blue: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeaderV5 = packed struct {
    header_size: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    color_plane: u16 = 0,
    bit_count: u16 = 0,
    compression_method: CompressionMethod = CompressionMethod.None,
    image_raw_size: u32 = 0,
    horizontal_resolution: u32 = 0,
    vertical_resolution: u32 = 0,
    palette_size: u32 = 0,
    important_colors: u32 = 0,
    red_mask: u32 = 0,
    green_mask: u32 = 0,
    blue_mask: u32 = 0,
    alpha_mask: u32 = 0,
    color_space: BitmapColorSpace = BitmapColorSpace.sRgb,
    cie_end_points: CieXyzTriple = CieXyzTriple{},
    gamma_red: u32 = 0,
    gamma_green: u32 = 0,
    gamma_blue: u32 = 0,
    intent: BitmapIntent = BitmapIntent.Graphics,
    profile_data: u32 = 0,
    profile_size: u32 = 0,
    reserved: u32 = 0,

    pub const HeaderSize = @sizeOf(@This());
};

pub const BitmapInfoHeader = union(enum) {
    Windows31: BitmapInfoHeaderWindows31,
    V4: BitmapInfoHeaderV4,
    V5: BitmapInfoHeaderV5,
};

pub const Bitmap = struct {
    file_header: BitmapFileHeader = undefined,
    info_header: BitmapInfoHeader = undefined,

    const Self = @This();

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
            .writeForImage = @ptrCast(FormatInterface.WriteForImageFn, writeForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Bmp;
    }

    pub fn formatDetect(reader: ImageReader, seek_stream: ImageSeekStream) !bool {
        _ = seek_stream;
        var magic_number_buffer: [2]u8 = undefined;
        _ = try reader.read(magic_number_buffer[0..]);
        if (std.mem.eql(u8, magic_number_buffer[0..], BitmapMagicHeader[0..])) {
            return true;
        }

        return false;
    }

    pub fn readForImage(allocator: *Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var bmp = Self{};

        try bmp.read(allocator, reader, seek_stream, pixels);

        var image_info = ImageInfo{};
        image_info.width = @intCast(usize, bmp.width());
        image_info.height = @intCast(usize, bmp.height());
        return image_info;
    }

    pub fn writeForImage(allocator: *Allocator, write_stream: image.ImageWriterStream, seek_stream: ImageSeekStream, pixels: color.ColorStorage, save_info: image.ImageSaveInfo) !void {
        _ = allocator;
        _ = write_stream;
        _ = seek_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn width(self: Self) i32 {
        return switch (self.info_header) {
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
        return switch (self.info_header) {
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

    pub fn pixelFormat(self: Self) !PixelFormat {
        return switch (self.info_header) {
            .V4 => |v4Header| try findPixelFormat(v4Header.bit_count, v4Header.compression_method),
            .V5 => |v5Header| try findPixelFormat(v5Header.bit_count, v5Header.compression_method),
            else => return errors.ImageError.UnsupportedPixelFormat,
        };
    }

    pub fn read(self: *Self, allocator: *Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels_opt: *?color.ColorStorage) !void {
        // Read file header
        self.file_header = try readStructLittle(reader, BitmapFileHeader);
        if (!mem.eql(u8, self.file_header.magic_header[0..], BitmapMagicHeader[0..])) {
            return errors.ImageError.InvalidMagicHeader;
        }

        // Read header size to figure out the header type, also TODO: Use PeekableStream when I understand how to use it
        const current_header_pos = try seek_stream.getPos();
        var header_size = try reader.readIntLittle(u32);
        try seek_stream.seekTo(current_header_pos);

        // Read info header
        self.info_header = switch (header_size) {
            BitmapInfoHeaderWindows31.HeaderSize => BitmapInfoHeader{ .Windows31 = try readStructLittle(reader, BitmapInfoHeaderWindows31) },
            BitmapInfoHeaderV4.HeaderSize => BitmapInfoHeader{ .V4 = try readStructLittle(reader, BitmapInfoHeaderV4) },
            BitmapInfoHeaderV5.HeaderSize => BitmapInfoHeader{ .V5 = try readStructLittle(reader, BitmapInfoHeaderV5) },
            else => return errors.ImageError.UnsupportedBitmapType,
        };

        // Read pixel data
        _ = switch (self.info_header) {
            .V4 => |v4Header| {
                const pixel_width = v4Header.width;
                const pixel_height = v4Header.height;
                const pixel_format = try findPixelFormat(v4Header.bit_count, v4Header.compression_method);

                pixels_opt.* = try color.ColorStorage.init(allocator, pixel_format, @intCast(usize, pixel_width * pixel_height));

                if (pixels_opt.*) |*pixels| {
                    try readPixels(reader, pixel_width, pixel_height, pixel_format, pixels);
                }
            },
            .V5 => |v5Header| {
                const pixel_width = v5Header.width;
                const pixel_height = v5Header.height;
                const pixel_format = try findPixelFormat(v5Header.bit_count, v5Header.compression_method);

                pixels_opt.* = try color.ColorStorage.init(allocator, pixel_format, @intCast(usize, pixel_width * pixel_height));

                if (pixels_opt.*) |*pixels| {
                    try readPixels(reader, pixel_width, pixel_height, pixel_format, pixels);
                }
            },
            else => return errors.ImageError.UnsupportedBitmapType,
        };
    }

    fn findPixelFormat(bit_count: u32, compression: CompressionMethod) !PixelFormat {
        if (bit_count == 32 and compression == CompressionMethod.Bitfields) {
            return PixelFormat.Bgra32;
        } else if (bit_count == 24 and compression == CompressionMethod.None) {
            return PixelFormat.Bgr24;
        } else {
            return errors.ImageError.UnsupportedPixelFormat;
        }
    }

    fn readPixels(reader: ImageReader, pixel_width: i32, pixel_height: i32, pixel_format: PixelFormat, pixels: *color.ColorStorage) !void {
        return switch (pixel_format) {
            PixelFormat.Bgr24 => {
                return readPixelsInternal(pixels.Bgr24, reader, pixel_width, pixel_height);
            },
            PixelFormat.Bgra32 => {
                return readPixelsInternal(pixels.Bgra32, reader, pixel_width, pixel_height);
            },
            else => {
                return errors.ImageError.UnsupportedPixelFormat;
            },
        };
    }

    fn readPixelsInternal(pixels: anytype, reader: ImageReader, pixel_width: i32, pixel_height: i32) !void {
        const ColorBufferType = @typeInfo(@TypeOf(pixels)).Pointer.child;

        var x: i32 = 0;
        var y: i32 = pixel_height - 1;
        while (y >= 0) : (y -= 1) {
            const scanline = y * pixel_width;

            x = 0;
            while (x < pixel_width) : (x += 1) {
                pixels[@intCast(usize, scanline + x)] = try readStructLittle(reader, ColorBufferType);
            }
        }
    }
};
