const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const color = @import("../color.zig");
const utils = @import("../utils.zig");
const buffered_stream_source = @import("../buffered_stream_source.zig");

pub const ReadError = ImageUnmanaged.ReadError;
pub const WriteError = ImageUnmanaged.WriteError || error{BigDimensions};

pub const Header = extern struct {
    width: u32 align(1),
    height: u32 align(1),

    pub const size = 16;
    const width_size = 4;
    const height_size = 4;
    const magic_value: [8]u8 = "farbfeld".*;

    fn encode(header: Header) [size]u8 {
        var result: [size]u8 = undefined;
        @memcpy(result[0..8], &magic_value);
        std.mem.writeInt(u32, result[8..12], header.width, .big);
        std.mem.writeInt(u32, result[12..16], header.height, .big);
        return result;
    }
    comptime {
        assert(@sizeOf(Header) + @sizeOf(@TypeOf(magic_value)) == size);
    }
};

pub const Farbfeld = struct {
    header: Header,
    pixels: []color.Rgba64,

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() ImageUnmanaged.Format {
        return ImageUnmanaged.format.farbfeld;
    }
    /// Taken a stream, Returns true if and only if the stream contains the magic value "fabfeld"
    pub fn formatDetect(stream: *ImageUnmanaged.Stream) ReadError!bool {
        var magic_buffer: [Header.magic_value.len]u8 = undefined;
        const bytes_read = try stream.read(magic_buffer[0..]);
        return bytes_read == Header.magic_value.len and
            std.mem.eql(u8, magic_buffer[0..], Header.magic_value[0..]);
    }
    pub fn read(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ReadError!Farbfeld {
        var farbfeld: Farbfeld = undefined;
        // read header magic value
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        const magic_match: bool = reader.isBytes(&Header.magic_value) catch return ReadError.InvalidData;
        if (!magic_match)
            return ReadError.InvalidData;

        // read width and height
        const header = utils.readStruct(reader, Header, .big) catch return ReadError.InvalidData;
        farbfeld.header = header;

        farbfeld.pixels = try allocator.alloc(color.Rgba64, @as(usize, header.width) * @as(usize, header.height));
        errdefer allocator.free(farbfeld.pixels);

        for (farbfeld.pixels) |*pixel| {
            const pixel_color = utils.readStruct(reader, color.Rgba64, .big) catch return ReadError.InvalidData;
            pixel.* = pixel_color;
        }
        return farbfeld;
    }
    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ReadError!ImageUnmanaged {
        var image: ImageUnmanaged = .{};
        const farbfeld = try read(allocator, stream);
        image.width = farbfeld.header.width;
        image.height = farbfeld.header.height;
        image.pixels = .{ .rgba64 = farbfeld.pixels };
        return image;
    }
    pub fn write(self: Farbfeld, write_stream: *ImageUnmanaged.Stream) WriteError!void {
        // get header width and height
        const width: u32 = @intCast(self.header.width);
        const height: u32 = @intCast(self.header.height);

        var header = Header{ .width = width, .height = height };

        var buffered_stream = buffered_stream_source.bufferedStreamSourceWriter(write_stream);
        const writer = buffered_stream.writer();

        // write header
        try writer.writeAll(&header.encode());
        // take advantage of platform endianess if possible
        if (builtin.cpu.arch.endian() == .big) {
            const pixels_bytes = std.mem.sliceAsBytes(self.pixels);
            try writer.writeAll(pixels_bytes);
        } else {
            for (self.pixels) |pixel| {
                try writer.writeStructEndian(pixel, .big);
            }
        }
        try buffered_stream.flush();
    }
    pub fn writeImage(_: Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, _: ImageUnmanaged.EncoderOptions) WriteError!void {
        const farbfeld: Farbfeld = .{
            .header = .{ .width = @intCast(image.width), .height = @intCast(image.height) },
            .pixels = image.pixels.rgba64,
        };
        try write(farbfeld, write_stream);
    }
};
