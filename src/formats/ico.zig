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
        const largest_entry_idx = ico.largestEntryIdx() orelse return ImageUnmanaged.ReadError.Unsupported;

        result.width = ico.width();
        result.height = ico.height();
        result.pixels = pixels[largest_entry_idx];

        return result;
    }

    pub fn largestEntryIdx(self: ICO) ?usize {
        var largest_area: usize = 0;
        var largest_entry_idx: ?usize = null;
        for (0.., self.dir.entries) |i, entry| {
            const area: usize = @as(usize, @intCast(entry.image_width)) * @as(usize, @intCast(entry.image_height));
            if (area > largest_area) {
                largest_area = area;
                largest_entry_idx = i;
            }
        }
        return largest_entry_idx;
    }

    pub fn width(self: ICO) usize {
        const largest_entry_idx = self.largestEntryIdx() orelse return 0;
        return @intCast(self.dir.entries[largest_entry_idx].image_width);
    }

    pub fn height(self: ICO) usize {
        const largest_entry_idx = self.largestEntryIdx() orelse return 0;
        return @intCast(self.dir.entries[largest_entry_idx].image_height);
    }

    pub fn read(self: *ICO, allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ![]color.PixelStorage {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        const reserved = try reader.readInt(u16, .little);
        if (reserved != 0) return ImageUnmanaged.ReadError.InvalidData;

        const image_kind_int = try reader.readInt(u16, .little);
        self.dir.kind = std.meta.intToEnum(Kind, image_kind_int) catch return ImageUnmanaged.ReadError.InvalidData;

        const num_images = try reader.readInt(u16, .little);

        const entries = try allocator.alloc(IconDirEntry, num_images);
        errdefer allocator.free(entries);

        for (0..num_images) |i| {
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

            entries[i] = entry;
        }

        self.dir.entries = entries;

        var results = try std.ArrayListUnmanaged(color.PixelStorage).initCapacity(allocator, self.dir.entries.len);
        errdefer results.deinit(allocator);
        errdefer for (results.items) |inner_data| {
            inner_data.deinit(allocator);
        };

        for (self.dir.entries) |entry| {
            const inner_data = try readInnerData(allocator, stream, entry);
            results.appendAssumeCapacity(inner_data);
        }

        return results.toOwnedSlice(allocator);
    }

    pub fn readInnerData(allocator: std.mem.Allocator, stream: anytype, entry: IconDirEntry) !color.PixelStorage {
        try stream.seekTo(entry.data_offset);
        const is_png = try PNG.formatDetect(stream);
        try stream.seekTo(entry.data_offset);

        if (is_png) {
            var options = png_reader.DefaultOptions.init(.{});
            const png_header = try png_reader.loadHeader(stream);
            const png_pixels = try png_reader.loadWithHeader(stream, &png_header, allocator, options.get());

            return png_pixels;
        }

        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);

        // .ICO, .CUR modifies BMP slightly- the height in the header is always double, as the mask follows the actual data
        // normally BMP could read this fine, however the mask is always stored in grayscale, which is in contrast with the
        // actual image data. So we need to read that separately.
        var info_header = try BMP.readInfoHeader(&buffered_stream);
        switch (info_header) {
            inline .windows31, .v4, .v5 => |*inner_header| {
                inner_header.height = std.math.divExact(i32, inner_header.height, 2) catch return ImageUnmanaged.ReadError.InvalidData;

                const actual_bytes = try BMP.readPixelsFromHeader(allocator, buffered_stream.reader(), info_header);
                // TODO: read mask properly
                switch (actual_bytes) {
                    .bgra32 => |pixels| {
                        try readBmpMask(pixels, buffered_stream.reader(), inner_header.width, inner_header.height, .{ .r = 0, .g = 0, .b = 0, .a = 0 });
                    },
                    else => return ImageUnmanaged.ReadError.Unsupported,
                }
                return actual_bytes;
            },
        }
    }

    pub fn readBmpMask(
        pixels: anytype,
        reader: anytype,
        pixel_width: i32,
        pixel_height: i32,
        exclude_pixel: @typeInfo(@TypeOf(pixels)).pointer.child,
    ) !void {
        var bit_reader = std.io.bitReader(.big, reader);
        var x: i32 = 0;
        var y: i32 = pixel_height - 1;
        while (y >= 0) : (y -= 1) {
            const scanline = y * pixel_width;

            x = 0;
            while (x < pixel_width) : (x += 1) {
                const do_exclude = try bit_reader.readBitsNoEof(u1, 1) == 1;
                if (do_exclude) {
                    pixels[@intCast(scanline + x)] = exclude_pixel;
                }
            }
        }
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }
};
