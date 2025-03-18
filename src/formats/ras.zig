const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

pub const Type = enum(u32) {
    old = 0x0,
    standard = 0x0001,
    byte_encoded = 0x0002,
    rgb = 0x0003,
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
    depth: u32 align(1),
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

    pub fn readImage(allocator: std.mem.Allocator, _: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        return result;
    }

    pub fn read(self: *RAS, stream: *ImageUnmanaged.Stream, _: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        if (!try formatDetect(stream)) {
            return ImageReadError.InvalidData;
        }

        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        self.header = utils.readStruct(reader, Header, .big) catch return ImageReadError.InvalidData;

        self.header.debug();

        return ImageUnmanaged.ReadError.InvalidData;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }
};
