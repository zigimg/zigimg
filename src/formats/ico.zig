const std = @import("std");

const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");

const PNG = @import("./png.zig").PNG;
const BMP = @import("./bmp.zig").BMP;

const png_reader = @import("./png/reader.zig");

pub const Kind = enum(u16) {
    icon = 1, // .ico
    cursor = 2, // .cur
};

pub const ColorPlanes = u1; // '0' or '1' are only valid options

pub const IconDirEntry = struct {
    image_width: u8, // '0' means 256
    image_height: u8, // '0' means 256
    color_palette_size: u8,
    color_planes: ColorPlanes, // in .ICO format
    bits_per_pixel: u16, // in .ICO format
    hotspot_x: u16, // in .CUR format
    hotspot_y: u16, // in .CUR format
    image_data_size: u32,
    data_offset: u32,
};

pub const IconDir = struct {
    kind: Kind,
    entries: []IconDirEntry,
};

pub const ICO = struct {
    dir: IconDir = undefined,

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!bool {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);

        const reserved = try buffered_stream.reader().readInt(u16, .little);
        if (reserved != 0) return false;

        const image_kind_int = try buffered_stream.reader().readInt(u16, .little);
        _ = std.meta.intToEnum(Kind, image_kind_int) catch return false;

        // todo: more checks
        return true;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var ico = ICO{};

        const pixels = try ico.read(allocator, stream);

        result.width = ico.width();
        result.height = ico.height();
        result.pixels = pixels;

        return result;
    }

    pub fn width(self: ICO) usize {
        // todo: support more frames
        return @intCast(self.dir.entries[0].image_width);
    }

    pub fn height(self: ICO) usize {
        // todo: support more frames
        return @intCast(self.dir.entries[0].image_height);
    }

    pub fn read(self: *ICO, allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) !color.PixelStorage {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        const reserved = try reader.readInt(u16, .little);
        if (reserved != 0) return ImageUnmanaged.ReadError.InvalidData;

        const image_kind_int = try reader.readInt(u16, .little);
        self.dir.kind = std.meta.intToEnum(Kind, image_kind_int) catch return ImageUnmanaged.ReadError.InvalidData;

        const num_images = try reader.readInt(u16, .little);
        // todo: support more frames
        if (num_images != 1) return ImageUnmanaged.ReadError.Unsupported;

        var entries_list = try std.ArrayListUnmanaged(IconDirEntry).initCapacity(allocator, num_images);
        errdefer entries_list.deinit(allocator);

        for (0..num_images) |_| {
            var entry: IconDirEntry = undefined;

            entry.image_width = try reader.readInt(u8, .little);
            entry.image_height = try reader.readInt(u8, .little);

            entry.color_palette_size = try reader.readInt(u8, .little);
            const reserved2 = try reader.readInt(u8, .little);
            if (reserved2 != 0) return ImageUnmanaged.ReadError.InvalidData;

            switch (self.dir.kind) {
                .icon => {
                    const color_planes_int = try reader.readInt(u16, .little);
                    if (color_planes_int != 0 and color_planes_int != 1) return ImageUnmanaged.ReadError.InvalidData;
                    entry.color_planes = @intCast(color_planes_int);
                    entry.bits_per_pixel = try reader.readInt(u16, .little);
                    entry.hotspot_x = 0;
                    entry.hotspot_y = 0;
                },
                .cursor => {
                    entry.hotspot_x = try reader.readInt(u16, .little);
                    entry.hotspot_y = try reader.readInt(u16, .little);
                    entry.color_planes = 0;
                    entry.bits_per_pixel = 0;
                },
            }

            entry.image_data_size = try reader.readInt(u32, .little);
            entry.data_offset = try reader.readInt(u32, .little);

            entries_list.appendAssumeCapacity(entry);
        }

        self.dir.entries = try entries_list.toOwnedSlice(allocator);
        errdefer allocator.free(self.dir.entries);
        const only_entry = self.dir.entries[0]; // todo: support more frames

        try stream.seekTo(only_entry.data_offset);
        const is_png = try PNG.formatDetect(stream);
        try stream.seekTo(only_entry.data_offset);

        if (is_png) {
            var options = png_reader.DefaultOptions.init(.{});
            const png_header = try png_reader.loadHeader(stream);
            const png_pixels = try png_reader.loadWithHeader(stream, &png_header, allocator, options.get());

            return png_pixels;
        }

        var bmp: BMP = .{};
        return try bmp.readInfoHeader(allocator, stream);
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }
};
