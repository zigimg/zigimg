const builtin = @import("builtin");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const std = @import("std");

pub const Header = extern struct {
    width: u32 align(1) = 0,
    height: u32 align(1) = 0,

    pub const SIZE = 16;

    const MAGIC_VALUE: []const u8 = "farbfeld";

    fn encode(header: Header) [SIZE]u8 {
        var result: [SIZE]u8 = undefined;
        @memcpy(result[0..MAGIC_VALUE.len], MAGIC_VALUE[0..]);
        std.mem.writeInt(u32, result[8..12], header.width, .big);
        std.mem.writeInt(u32, result[12..16], header.height, .big);
        return result;
    }

    comptime {
        std.debug.assert((@sizeOf(Header) + MAGIC_VALUE.len) == SIZE);
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
    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        const reader = read_stream.reader();

        const read_magic_header = try reader.peek(Header.MAGIC_VALUE.len);

        return read_magic_header.len == Header.MAGIC_VALUE.len and std.mem.eql(u8, read_magic_header, Header.MAGIC_VALUE[0..]);
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result: Image = .{};
        errdefer result.deinit(allocator);

        var farbfeld: Farbfeld = .{};

        result.pixels = try farbfeld.read(allocator, read_stream);
        result.width = farbfeld.header.width;
        result.height = farbfeld.header.height;
        return result;
    }

    pub fn writeImage(_: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, _: Image.EncoderOptions) Image.WriteError!void {
        const farbfeld: Farbfeld = .{
            .header = .{
                .width = @intCast(image.width),
                .height = @intCast(image.height),
            },
        };

        try farbfeld.write(write_stream, image.pixels);
    }

    pub fn read(self: *Farbfeld, allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!color.PixelStorage {
        // read header magic value
        const reader = read_stream.reader();

        const magic_header = reader.take(Header.MAGIC_VALUE.len) catch return Image.ReadError.InvalidData;
        if (!std.mem.eql(u8, magic_header, Header.MAGIC_VALUE[0..])) {
            return Image.ReadError.InvalidData;
        }

        // read width and height
        self.header = reader.takeStruct(Header, .big) catch return Image.ReadError.InvalidData;

        const pixels = try color.PixelStorage.init(allocator, .rgba64, @as(usize, self.header.width) * @as(usize, self.header.height));
        errdefer pixels.deinit(allocator);

        for (pixels.rgba64) |*pixel| {
            const pixel_color = reader.takeStruct(color.Rgba64, .big) catch return Image.ReadError.InvalidData;
            pixel.* = pixel_color;
        }

        return pixels;
    }

    pub fn write(self: Farbfeld, write_stream: *io.WriteStream, pixels: color.PixelStorage) Image.WriteError!void {
        if (pixels != .rgba64) {
            return Image.WriteError.Unsupported;
        }

        // Setup the buffered stream
        const writer = write_stream.writer();

        // Write header
        const encoded_header = self.header.encode();
        try writer.writeAll(encoded_header[0..]);

        // Take advantage of platform endianess if possible
        if (builtin.cpu.arch.endian() == .big) {
            const pixels_bytes = pixels.asConstBytes();
            try writer.writeAll(pixels_bytes);
        } else {
            for (pixels.rgba64) |pixel| {
                try writer.writeStruct(pixel, .big);
            }
        }

        try write_stream.flush();
    }
};
