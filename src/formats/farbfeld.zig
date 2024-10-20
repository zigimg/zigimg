const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
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
    const width_size = 4;
    const height_size = 4;
    const size = 16;
    const magic_value: [8]u8 = [8]u8{ 'f', 'a', 'r', 'b', 'f', 'e', 'l', 'd' };

    width: u32 align(1),
    height: u32 align(1),

    fn encode(header: Header) [size]u8 {
        var result: [size]u8 = undefined;
        @memcpy(result[0..8], &magic_value);
        std.mem.writeInt(u32, result[8..12], header.width, .big);
        std.mem.writeInt(u32, result[12..16], header.height, .big);
        return result;
    }
    comptime {
        assert(size == 16);
    }
};

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
        mem.eql(u8, magic_buffer[0..], Header.magic_value[0..]);
}
/// consume stream and returns ImageUnmanaged as farbfeld format. pixelformat is rgba64 and does not have animation. Caller owns returned memory. https://tools.suckless.org/farbfeld/
pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ReadError!ImageUnmanaged {
    var image: ImageUnmanaged = .{};
    // read header magic value
    var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
    const reader = buffered_stream.reader();

    const magic_match: bool = reader.isBytes(&Header.magic_value) catch return ReadError.InvalidData;
    if (!magic_match)
        return ReadError.InvalidData;

    // read width and height
    const header = utils.readStruct(reader, Header, .big) catch return ReadError.InvalidData;
    image.width = header.width;
    image.height = header.height;

    image.pixels = try color.PixelStorage.init(allocator, .rgba64, @as(usize, header.width) * @as(usize, header.height));
    const pixels: *color.PixelStorage = &image.pixels;
    errdefer pixels.deinit(allocator);

    // const pixels_size: usize = header.width * header.height;

    for (pixels.rgba64) |*pixel| {
        const pixel_color = utils.readStruct(reader, color.Rgba64, .big) catch return ReadError.InvalidData;
        pixel.* = pixel_color;
    }
    return image;
}
/// write image into write_stream in farbfeld format. Will error if the width or the height of the image exceeds the limits. Does not deinitialize the image.
pub fn writeImage(_: Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, _: ImageUnmanaged.EncoderOptions) WriteError!void {
    // we don't need any extra memory and there are no encoding options
    // get header width and height
    const width = std.math.cast(u32, image.width);
    const height = std.math.cast(u32, image.height);
    if (width == null or height == null)
        return WriteError.BigDimensions;

    var header = Header{ .width = width.?, .height = height.? };

    var buffered_stream = buffered_stream_source.bufferedStreamSourceWriter(write_stream);
    const writer = buffered_stream.writer();

    // write header
    try writer.writeAll(&header.encode());
    // take advantage of platform endianess if possible
    if (builtin.cpu.arch.endian() == .big) {
        const pixels_bytes = image.pixels.asConstBytes();
        try writer.writeAll(pixels_bytes);
    } else {
        for (image.pixels.rgba64) |pixel| {
            try writer.writeStructEndian(pixel, .big);
        }
    }
    try buffered_stream.flush();
}
