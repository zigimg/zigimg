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

pub const Type = enum(u32) {
    // bgr uncompressed data
    old = 0x0,
    standard = 0x0001,
    // data is rle compressed
    byte_encoded = 0x0002,
    // (X)RGB instead of (X)BGR (and not compressed)
    rgb = 0x0003,
    // these are not supported
    tiff = 0x0004,
    iff = 0x0005,
    experimental = 0xffff,
};

pub const ColorMapType = enum(u32) {
    no_color_map = 0x0,
    rgb_color_map = 0x0001,
    raw_color_map = 0x0002,
};

const Header = extern struct {
    const size = 28;
    const ras_magic_number = [4]u8{ 0x59, 0xa6, 0x6a, 0x95 };

    width: u32 align(1),
    height: u32 align(1),
    // valid depths are: 1,8,24,32
    depth: u32 align(1),
    // very old files apparently put 0 here so we cannot rely on it
    // but need to compute the length instead
    length: u32 align(1),
    type: Type align(1),
    color_map_type: ColorMapType align(1),
    color_map_length: u32 align(1),

    pub fn debug(self: *const Header) void {
        std.debug.print("size: {}x{} (d={})\nlen={}\ntype={}\ncmap={}\ncmap_len={}\n", .{ self.width, self.height, self.depth, self.length, self.type, self.color_map_type, self.color_map_length });
    }

    comptime {
        std.debug.assert(@sizeOf(Header) == Header.size);
    }
};

pub const RAS = struct {
    header: Header = undefined,
    palette: utils.FixedStorage(color.Rgba32, 256) = .{},

    pub fn width(self: *RAS) usize {
        return self.header.width;
    }

    pub fn height(self: *RAS) usize {
        return self.header.height;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        var magic_buffer: [Header.ras_magic_number.len]u8 = undefined;

        _ = try stream.read(magic_buffer[0..]);

        return std.mem.eql(u8, magic_buffer[0..], Header.ras_magic_number[0..]);
    }

    pub fn pixelFormat(self: *RAS) ImageReadError!PixelFormat {
        switch (self.header.depth) {
            24 => return if (self.header.type == .rgb) PixelFormat.rgb24 else PixelFormat.bgr24,
            32 => return PixelFormat.rgba32,
            8 => return if (self.header.color_map_length > 0) PixelFormat.indexed8 else PixelFormat.grayscale8,
            // some apps may use (2-color) color map when storing 1-bit files
            1 => return if (self.header.color_map_length > 0) PixelFormat.indexed8 else PixelFormat.grayscale1,
            else => return ImageError.Unsupported,
        }
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var ras = RAS{};

        const pixels = try ras.read(stream, allocator);

        result.pixels = pixels;
        result.width = ras.width();
        result.height = ras.height();

        return result;
    }

    pub fn uncompressBitmap(self: *RAS, stream: *ImageUnmanaged.Stream, buffer: []u8) !void {
        const reader = stream.reader();

        switch (self.header.type) {
            // no compression for these types
            .old, .standard, .rgb => _ = try reader.readAll(buffer[0..]),
            // rle encoding with x80 trigger byte
            .byte_encoded => {
                var position: usize = 0;
                while (position < buffer.len) {
                    const flag: u8 = try reader.readByte();
                    if (flag == 0x80) {
                        const count: u16 = try reader.readByte();
                        if (count == 0) {
                            buffer[position] = flag;
                            position += 1;
                        } else {
                            const run = try reader.readByte();
                            for (0..count + 1) |_| {
                                buffer[position] = run;
                                position += 1;
                                if (position >= buffer.len)
                                    break;
                            }
                        }
                    } else {
                        buffer[position] = flag;
                        position += 1;
                    }
                }
            },
            else => return ImageError.Unsupported,
        }
    }

    pub fn readPalette(self: *RAS, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !void {
        const reader = stream.reader();
        const header = self.header;
        switch (header.color_map_type) {
            .rgb_color_map => {
                const colors = header.color_map_length / 3;
                self.palette.resize(colors);
                const palette = self.palette.data;
                const buffer: []u8 = try allocator.alloc(u8, header.color_map_length);
                defer allocator.free(buffer);
                _ = try reader.readAll(buffer);

                for (0..colors) |index| {
                    // palette components are stored in a separate plane
                    palette[index] = color.Rgba32.from.rgb(buffer[index], buffer[index + colors], buffer[index + 2 * colors]);
                }
            },
            else => return ImageError.Unsupported,
        }
    }

    pub fn read(self: *RAS, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        if (!try formatDetect(stream)) {
            return ImageReadError.InvalidData;
        }

        const reader = stream.reader();

        self.header = utils.readStruct(reader, Header, .big) catch return ImageReadError.InvalidData;

        const pixel_format = try self.pixelFormat();

        const image_width = self.width();
        const image_height = self.height();

        if (self.header.color_map_type != .no_color_map and self.header.color_map_length > 0) {
            try self.readPalette(stream, allocator);
        }

        var pixels = try color.PixelStorage.init(allocator, pixel_format, image_width * image_height);
        errdefer pixels.deinit(allocator);

        const pixel_size = @max(1, (self.header.depth / 8));
        // calc line size, adding padding byte so that scanline
        // is multiple of 16 bits
        const line_size = calc_line_width: {
            if (self.header.depth == 1) {
                const bytes_needed = (std.math.divCeil(usize, image_width, 8) catch 0);
                // add padding if needed to make line width multiple of 16
                break :calc_line_width bytes_needed + (bytes_needed & 1);
            }
            break :calc_line_width image_width;
        };
        const buffer_size = line_size * image_height * pixel_size;
        const buffer: []u8 = try allocator.alloc(u8, buffer_size);
        defer allocator.free(buffer);

        try self.uncompressBitmap(stream, buffer);

        switch (pixels) {
            .grayscale1 => |*storage| {
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        const offset: usize = y * line_size + x / 8;
                        const bit_index = (x + 8) % 8;
                        const mask: u8 = @as(u8, 1) << @intCast((@as(u8, 7) - bit_index));
                        storage.*[y * image_width + x].value = if ((buffer[offset] & mask) != 0) 0 else 1;
                    }
                }
            },
            .grayscale8 => {
                const pixel_array = pixels.asBytes();
                @memcpy(pixel_array[0..], buffer[0..]);
            },
            .indexed8 => |*storage| {
                @memcpy(storage.indices[0..], buffer[0..storage.indices.len]);
                storage.resizePalette(self.palette.data.len);
                for (0..self.palette.data.len) |index| {
                    const palette = storage.palette;
                    palette[index] = self.palette.data[index];
                }
            },
            .rgb24, .bgr24 => {
                const pixel_array = pixels.asBytes();
                @memcpy(pixel_array[0..], buffer[0..]);
            },
            .rgba32 => |*storage| {
                if (self.header.type == .rgb) {
                    for (0..image_height) |y| {
                        for (0..image_width) |x| {
                            const offset = y * image_width + x;
                            storage.*[offset] = color.Rgba32.from.rgb(buffer[offset * pixel_size + 1], buffer[offset * pixel_size + 2], buffer[offset * pixel_size + 3]);
                        }
                    }
                } else {
                    for (0..image_height) |y| {
                        for (0..image_width) |x| {
                            const offset = y * image_width + x;
                            storage.*[offset] = color.Rgba32.from.rgb(buffer[offset * pixel_size + 3], buffer[offset * pixel_size + 2], buffer[offset * pixel_size + 1]);
                        }
                    }
                }
            },
            else => return ImageError.Unsupported,
        }

        return pixels;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }
};
