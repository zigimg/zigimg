const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const std = @import("std");
const utils = @import("../utils.zig");

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
    bytes_per_channel: u8 align(1),
    dimension: Dimensions align(1),
    x_size: u16 align(1),
    y_size: u16 align(1),
    z_size: u16 align(1),
    pix_min: u32 align(1),
    pix_max: u32 align(1),
    dummy1: u32 align(1),
    image_name: [80]u8 align(1),
    pixel_format: SgiPixelFormat align(1),
    dummy2: [404]u8 align(1),

    pub fn debug(self: *const Header) void {
        std.log.debug("{}", .{self});
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

    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        const reader = read_stream.reader();

        const magic_buffer = try reader.peek(Header.magic_number.len);

        return std.mem.eql(u8, magic_buffer[0..], Header.magic_number[0..]);
    }

    pub fn pixelFormat(self: *SGI) Image.Error!PixelFormat {
        switch (self.header.pixel_format) {
            .normal => {
                switch (self.header.dimension) {
                    .multi_channel => switch (self.header.z_size) {
                        3 => return if (self.header.bytes_per_channel == 1) .rgb24 else .rgb48,
                        4 => return if (self.header.bytes_per_channel == 1) .rgba32 else .rgba64,
                        else => return Image.Error.Unsupported,
                    },
                    // TODO: add support for 16-bit channel ie: grayscale16
                    .single_channel => return .grayscale8,
                    else => return Image.Error.Unsupported,
                }
            },
            else => return Image.Error.Unsupported,
        }
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result = Image{};
        errdefer result.deinit(allocator);

        var sgi = SGI{};

        const pixels = try sgi.read(allocator, read_stream);

        result.pixels = pixels;
        result.width = sgi.width();
        result.height = sgi.height();

        return result;
    }

    pub fn uncompressBitmap(
        self: *SGI,
        allocator: std.mem.Allocator,
        read_stream: *io.ReadStream,
        buffer: []u8,
    ) !void {
        const reader = read_stream.reader();

        switch (self.header.compression) {
            .uncompressed => _ = try reader.readSliceAll(buffer[0..]),
            .rle => {
                const image_width = self.width();
                const image_height = self.height();

                // read both data tables first
                const tables_buffer: []u8 = try allocator.alloc(u8, self.header.y_size * self.header.z_size * 2 * 4);
                defer allocator.free(tables_buffer);

                _ = try reader.readSliceAll(tables_buffer[0..]);

                const offsets: []u32 = @as(*const []u32, @ptrCast(&tables_buffer[0 .. self.header.y_size * self.header.z_size * 4])).*[0 .. self.header.y_size * self.header.z_size];

                const sizes: []u32 = @as(*const []u32, @ptrCast(&tables_buffer[self.header.y_size * self.header.z_size * 4 ..])).*[0 .. self.header.y_size * self.header.z_size];

                // then read compressed_data that's following the tables
                const data_buffer: []u8 = try allocator.alloc(
                    u8,
                    std.math.cast(usize, try read_stream.getEndPos() - read_stream.getPos()) orelse return Image.ReadError.StreamTooLong,
                );
                defer allocator.free(data_buffer);

                const data_start = 512 + tables_buffer.len;

                _ = try reader.readSliceAll(data_buffer[0..]);

                if (self.header.bytes_per_channel == 1) {
                    for (0..self.header.z_size) |z| {
                        for (z * image_height..(z * image_height) + image_height) |index| {
                            const offset = offsets[index];
                            var scanline_offset = std.mem.bigToNative(u32, offset) - data_start;
                            const scanline_size = std.mem.bigToNative(u32, sizes[index]);
                            const max_offset = scanline_offset + scanline_size;
                            var pixel_pos = index * image_width;
                            while (scanline_offset < max_offset) {
                                const run_count = data_buffer[scanline_offset];
                                scanline_offset += 1;
                                if (run_count & 128 == 128) {
                                    // copy run_count items from stream to output
                                    for (0..run_count & 127) |_| {
                                        buffer[pixel_pos] = data_buffer[scanline_offset];
                                        pixel_pos += 1;
                                        scanline_offset += 1;
                                    }
                                } else if (run_count > 0) {
                                    const value = data_buffer[scanline_offset];
                                    scanline_offset += 1;
                                    for (0..run_count) |_| {
                                        buffer[pixel_pos] = value;
                                        pixel_pos += 1;
                                    }
                                } else break;
                            }
                        }
                    }
                } else {
                    // 16-bit per channel
                    for (0..self.header.z_size) |z| {
                        for (z * image_height..(z * image_height) + image_height) |index| {
                            const offset = offsets[index];
                            var scanline_offset = std.mem.bigToNative(u32, offset) - data_start;
                            const scanline_size = std.mem.bigToNative(u32, sizes[index]);
                            const max_offset = scanline_offset + scanline_size;
                            var pixel_pos = index * image_width * 2;
                            while (scanline_offset < max_offset) {
                                // get low order byte: rle command is also stored as 16-bit,
                                // just like the compressed data
                                const run_count = data_buffer[scanline_offset + 1];
                                scanline_offset += 2;
                                if (run_count & 128 == 128) {
                                    // copy run_count items from stream to output
                                    for (0..run_count & 127) |_| {
                                        buffer[pixel_pos] = data_buffer[scanline_offset];
                                        buffer[pixel_pos + 1] = data_buffer[scanline_offset + 1];
                                        pixel_pos += 2;
                                        scanline_offset += 2;
                                    }
                                } else if (run_count > 0) {
                                    const hi_byte = data_buffer[scanline_offset];
                                    const low_byte = data_buffer[scanline_offset + 1];
                                    scanline_offset += 2;
                                    for (0..run_count) |_| {
                                        buffer[pixel_pos] = hi_byte;
                                        buffer[pixel_pos + 1] = low_byte;
                                        pixel_pos += 2;
                                    }
                                } else break;
                            }
                        }
                    }
                }
            },
        }
    }

    pub fn read(self: *SGI, allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!color.PixelStorage {
        if (!try formatDetect(read_stream)) {
            return Image.ReadError.InvalidData;
        }

        const reader = read_stream.reader();

        // Toss the magic number
        reader.toss(Header.magic_number.len);

        self.header = reader.takeStruct(Header, .big) catch return Image.ReadError.InvalidData;

        const pixel_format = try self.pixelFormat();

        const image_width = self.width();
        const image_height = self.height();
        const bytes_per_channel = self.header.bytes_per_channel;
        const pixel_size = self.header.z_size * bytes_per_channel;

        var pixels = try color.PixelStorage.init(allocator, pixel_format, image_width * image_height);
        errdefer pixels.deinit(allocator);

        const buffer_size = pixel_size * image_width * image_height;
        const buffer: []u8 = try allocator.alloc(u8, buffer_size);
        defer allocator.free(buffer);

        try self.uncompressBitmap(allocator, read_stream, buffer);

        // channel_size in pixels, not in bytes
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
            .rgba64 => |storage| {
                const u16_buffer: []u16 = @as(*const []u16, @ptrCast(&buffer[0..])).*;
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        const offset = (image_height - y - 1) * image_width + x;
                        storage[y * image_width + x] = color.Rgba64{ .r = std.mem.bigToNative(u16, u16_buffer[offset]), .g = std.mem.bigToNative(u16, u16_buffer[offset + channel_size]), .b = std.mem.bigToNative(u16, u16_buffer[offset + channel_size * 2]), .a = std.mem.bigToNative(u16, buffer[offset + channel_size * 3]) };
                    }
                }
            },
            .rgb48 => |storage| {
                const u16_buffer: []u16 = @as(*const []u16, @ptrCast(&buffer[0..])).*;
                for (0..image_height) |y| {
                    for (0..image_width) |x| {
                        const offset = (image_height - y - 1) * image_width + x;
                        storage[y * image_width + x] = color.Rgb48{ .r = std.mem.bigToNative(u16, u16_buffer[offset]), .g = std.mem.bigToNative(u16, u16_buffer[offset + channel_size]), .b = std.mem.bigToNative(u16, u16_buffer[offset + channel_size * 2]) };
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
            else => return Image.Error.Unsupported,
        }

        return pixels;
    }
};
