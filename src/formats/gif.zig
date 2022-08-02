const FormatInterface = @import("../format_interface.zig").FormatInterface;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const Image = @import("../Image.zig");
const std = @import("std");
const utils = @import("../utils.zig");

const ImageReadError = Image.ReadError;
const ImageWriteError = Image.WriteError;

pub const GIFHeader = packed struct {
    magic: [3]u8,
    version: [3]u8,
    width: u16,
    height: u16,
    flags: packed struct {
        global_color_table_size: u3,
        sorted: bool,
        color_resolution: u3,
        use_global_color_table: bool,
    },
    background_color_index: u8,
    pixel_aspect_ratio: u8,
};

pub const GIF = struct {
    header: GIFHeader = undefined,
    const Self = @This();

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() Image.Format {
        return Image.Format.gif;
    }

    pub fn formatDetect(stream: *Image.Stream) !bool {
        const GIF87Header = "GIF87a";
        const GIF89Header = "GIF89a";

        var header_buffer: [6]u8 = undefined;
        const read_bytes = try stream.read(header_buffer[0..]);
        if (read_bytes < 6) {
            return false;
        }

        return std.mem.eql(u8, header_buffer[0..], GIF87Header) or std.mem.eql(u8, header_buffer[0..], GIF89Header);
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *Image.Stream) ImageReadError!Image {
        var result = Image.init(allocator);
        errdefer result.deinit();

        var gif = Self{};

        try gif.read(allocator, stream, &result.pixels);

        result.width = @intCast(usize, gif.header.width);
        result.height = @intCast(usize, gif.header.height);
        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *Image.Stream, pixels: color.PixelStorage, save_info: Image.SaveInfo) Image.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn read(self: *Self, allocator: std.mem.Allocator, stream: *Image.Stream, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        _ = allocator;
        _ = pixels_opt;

        const reader = stream.reader();

        self.header = try utils.readStructLittle(reader, GIFHeader);

        const has_global_table = self.header.flags.use_global_color_table;
        const global_table_size: usize = (@as(usize, 1) << self.header.flags.global_color_table_size) + 1;

        std.log.debug("has_global_table={}, global_table_size={},", .{ has_global_table, global_table_size });

        if (!std.mem.eql(u8, self.header.magic[0..], "GIF")) {
            return ImageReadError.InvalidData;
        }

        if (!(std.mem.eql(u8, self.header.version[0..], "87a") or std.mem.eql(u8, self.header.version[0..], "89a"))) {
            return ImageReadError.InvalidData;
        }
    }
};
