const std = @import("std");
const builtin = @import("builtin");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const color = @import("../color.zig");
const utils = @import("../utils.zig");
const buffered_stream_source = @import("../buffered_stream_source.zig");

pub const Header = extern struct {
    width: u32 align(1) = 0,
    height: u32 align(1) = 0,

    pub const size = 16;
    const width_size = 4;
    const height_size = 4;
    const magic_value: []const u8 = "farbfeld";

    fn encode(header: Header) [size]u8 {
        var result: [size]u8 = undefined;
        @memcpy(result[0..magic_value.len], magic_value[0..]);
        std.mem.writeInt(u32, result[8..12], header.width, .big);
        std.mem.writeInt(u32, result[12..16], header.height, .big);
        return result;
    }

    comptime {
        std.debug.assert((@sizeOf(Header) + magic_value.len) == size);
    }
};

pub const Farbfeld = struct {
    header: Header = .{},

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    /// Taken a stream, Returns true if and only if the stream contains the magic value "fabfeld"
    pub fn formatDetect(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!bool {
        var magic_buffer: [Header.magic_value.len]u8 = undefined;
        const bytes_read = try stream.read(magic_buffer[0..]);
        return bytes_read == Header.magic_value.len and std.mem.eql(u8, magic_buffer[0..], Header.magic_value[0..]);
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result: ImageUnmanaged = .{};
        errdefer result.deinit(allocator);

        var farbfeld: Farbfeld = .{};

        result.pixels = try farbfeld.read(allocator, stream);
        result.width = farbfeld.header.width;
        result.height = farbfeld.header.height;
        return result;
    }

    pub fn writeImage(_: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, _: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void {
        const farbfeld: Farbfeld = .{
            .header = .{ .width = @intCast(image.width), .height = @intCast(image.height) },
        };

        try farbfeld.write(write_stream, image.pixels);
    }

    pub fn read(self: *Farbfeld, allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!color.PixelStorage {
        // read header magic value
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        const magic_match: bool = reader.isBytes(Header.magic_value[0..]) catch return ImageUnmanaged.ReadError.InvalidData;
        if (!magic_match) {
            return ImageUnmanaged.ReadError.InvalidData;
        }

        // read width and height
        self.header = utils.readStruct(reader, Header, .big) catch return ImageUnmanaged.ReadError.InvalidData;

        const pixels = try color.PixelStorage.init(allocator, .rgba64, @as(usize, self.header.width) * @as(usize, self.header.height));
        errdefer pixels.deinit(allocator);

        for (pixels.rgba64) |*pixel| {
            const pixel_color = utils.readStruct(reader, color.Rgba64, .big) catch return ImageUnmanaged.ReadError.InvalidData;
            pixel.* = pixel_color;
        }

        return pixels;
    }

    pub fn write(self: Farbfeld, write_stream: *ImageUnmanaged.Stream, pixels: color.PixelStorage) ImageUnmanaged.WriteError!void {
        if (pixels != .rgba64) {
            return ImageUnmanaged.WriteError.Unsupported;
        }

        // Setup the buffered stream
        var buffered_stream = buffered_stream_source.bufferedStreamSourceWriter(write_stream);
        const writer = buffered_stream.writer();

        // Write header
        const encoded_header = self.header.encode();
        try writer.writeAll(encoded_header[0..]);

        // Take advantage of platform endianess if possible
        if (builtin.cpu.arch.endian() == .big) {
            const pixels_bytes = pixels.asConstBytes();
            try writer.writeAll(pixels_bytes);
        } else {
            for (pixels.rgba64) |pixel| {
                try writer.writeStructEndian(pixel, .big);
            }
        }

        try buffered_stream.flush();
    }
};
