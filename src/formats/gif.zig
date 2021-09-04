const Allocator = std.mem.Allocator;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageReader = image.ImageReader;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const image = @import("../image.zig");
const std = @import("std");
const utils = @import("../utils.zig");

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
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
            .writeForImage = @ptrCast(FormatInterface.WriteForImageFn, writeForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Gif;
    }

    pub fn formatDetect(reader: ImageReader, seek_stream: ImageSeekStream) !bool {
        const GIF87Header = "GIF87a";
        const GIF89Header = "GIF89a";

        _ = seek_stream;

        var header_buffer: [6]u8 = undefined;
        const read_bytes = try reader.read(header_buffer[0..]);
        if (read_bytes < 6) {
            return false;
        }

        return std.mem.eql(u8, header_buffer[0..], GIF87Header) or std.mem.eql(u8, header_buffer[0..], GIF89Header);
    }

    pub fn readForImage(allocator: *Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels_opt: *?color.ColorStorage) !ImageInfo {
        var gif = Self{};

        try gif.read(allocator, reader, seek_stream, pixels_opt);

        var image_info = ImageInfo{};
        image_info.width = gif.header.width;
        image_info.height = gif.header.height;
        return image_info;
    }

    pub fn writeForImage(allocator: *Allocator, write_stream: image.ImageWriterStream, seek_stream: ImageSeekStream, pixels: color.ColorStorage, save_info: image.ImageSaveInfo) !void {
        _ = allocator;
        _ = write_stream;
        _ = seek_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn read(self: *Self, allocator: *Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels_opt: *?color.ColorStorage) !void {
        _ = allocator;
        _ = seek_stream;
        _ = pixels_opt;

        self.header = try utils.readStructLittle(reader, GIFHeader);

        const has_global_table = self.header.flags.use_global_color_table;
        const global_table_size: usize = (@as(usize, 1) << self.header.flags.global_color_table_size) + 1;

        std.log.debug("has_global_table={}, global_table_size={},", .{ has_global_table, global_table_size });

        if (!std.mem.eql(u8, self.header.magic[0..], "GIF")) {
            return errors.ImageError.InvalidMagicHeader;
        }

        if (!(std.mem.eql(u8, self.header.version[0..], "87a") or std.mem.eql(u8, self.header.version[0..], "89a"))) {
            return errors.ImageError.InvalidMagicHeader;
        }
    }
};
