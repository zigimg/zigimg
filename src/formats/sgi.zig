const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const ImageError = ImageUnmanaged.Error;
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

pub const CompressionFlag = enum(u8) {
    uncompressed = 0x0,
    rle = 0x1,
};

pub const Dimensions = enum(u16) {
    // one long scanline
    scanline = 0x1,
    // single channel bitmap, size = x_size * y_size
    single_channel = 0x2,
    // multi channel bitmap, size = z_size
    multi_channel = 0x3,
};

pub const SgiPixelFormat = enum(u32) {
    // normal: black&white = 1 chan, color = 3 chans, color + alpha = 4 chans
    normal = 0x0,
    // obsolete
    dithered = 0x1,
    // obsolete
    need_cmap = 0x2,
    // image is cmap-only
    cmap_only = 0x3,
};

const Header = extern struct {
    const size = 510;
    const magic_number = [2]u8{ 0x1, 0xda };

    compression: CompressionFlag align(1),
    bpc: u8 align(1),
    dimension: Dimensions align(1),
    x_size: u16 align(1),
    y_size: u16 align(1),
    z_size: u16 align(1),
    pix_min: u32 align(1),
    pix_max: u32 align(1),
    dwnmy1: u32 align(1),
    image_name: [80]u8 align(1),
    pixel_format: SgiPixelFormat align(1),
    dummy2: [404]u8 align(1),

    pub fn debug(self: *const Header) void {
        std.debug.print("size: {}x{} (bpc={})\nlen={}\ntype={}\ndimension={}\ncompression={}\n", .{ self.x_size, self.y_size, self.bpc, self.z_size, self.pixel_format, self.dimension, self.compression });
    }

    comptime {
        std.debug.assert(@sizeOf(Header) == Header.size);
    }
};

pub const SGI = struct {
    header: Header = undefined,
    palette: utils.FixedStorage(color.Rgba32, 256) = .{},

    pub fn width(self: *SGI) usize {
        return self.header.x_size;
    }

    pub fn height(self: *SGI) usize {
        return self.header.y_size;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        var magic_buffer: [Header.magic_number.len]u8 = undefined;

        _ = try stream.read(magic_buffer[0..]);

        return std.mem.eql(u8, magic_buffer[0..], Header.magic_number[0..]);
    }

    pub fn pixelFormat(self: *SGI) ImageReadError!PixelFormat {
        switch (self.header.pixel_format) {
            .normal => {
                switch (self.header.dimension) {
                    .multi_channel => return if (self.header.z_size == 4) PixelFormat.rgba32 else PixelFormat.rgb24,
                    .single_channel => return PixelFormat.grayscale8,
                    else => return ImageError.Unsupported,
                }
            },
            else => return ImageError.Unsupported,
        }
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var sgi = SGI{};

        const pixels = try sgi.read(stream, allocator);

        result.pixels = pixels;
        result.width = sgi.width();
        result.height = sgi.height();

        return result;
    }

    pub fn uncompressBitmap(self: *SGI, stream: *ImageUnmanaged.Stream, buffer: []u8) !void {
        const reader = stream.reader();

        switch (self.header.compression) {
            .uncompressed => _ = try reader.readAll(buffer[0..]),
            else => return ImageError.Unsupported,
        }
    }

    pub fn read(self: *SGI, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        if (!try formatDetect(stream)) {
            return ImageReadError.InvalidData;
        }

        const reader = stream.reader();

        self.header = utils.readStruct(reader, Header, .big) catch return ImageReadError.InvalidData;

        self.header.debug();

        const pixel_format = try self.pixelFormat();

        const image_width = self.width();
        const image_height = self.height();
        const pixel_size = self.header.z_size * self.header.bpc;

        var pixels = try color.PixelStorage.init(allocator, pixel_format, image_width * image_height);
        errdefer pixels.deinit(allocator);

        const buffer_size = pixel_size * image_width * image_height;
        const buffer: []u8 = try allocator.alloc(u8, buffer_size);
        defer allocator.free(buffer);

        try self.uncompressBitmap(stream, buffer);

        const channel_size = image_height * image_width;

        switch (pixels) {
            .rgba32 => |storage| {
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        // scanlines are stored bottom-up in sgi files
                        const offset = (image_height - y - 1) * image_width + x;
                        storage[y * image_width + x] = color.Rgba32{ .r = buffer[offset], .g = buffer[offset + channel_size], .b = buffer[offset + channel_size * 2], .a = buffer[offset + channel_size * 3] };
                    }
                }
            },
            .rgb24 => |storage| {
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        // scanlines are stored bottom-up in sgi files
                        const offset = (image_height - y - 1) * image_width + x;
                        storage[y * image_width + x] = color.Rgb24{ .r = buffer[offset], .g = buffer[offset + channel_size], .b = buffer[offset + channel_size * 2] };
                    }
                }
            },
            .grayscale8 => |storage| {
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        // scanlines are stored bottom-up in sgi files
                        const offset = (image_height - y - 1) * image_width + x;
                        storage[y * image_width + x].value = buffer[offset];
                    }
                }
            },
            else => return ImageError.Unsupported,
        }

        return pixels;
    }
};
