const std = @import("std");

const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");

const png = @import("./png.zig");
const PNG = png.PNG;
const bmp = @import("./bmp.zig");
const BMP = bmp.BMP;
const png_types = @import("./png/types.zig");

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

    pub fn width(self: IconDirEntry) usize {
        return if (self.image_width == 256) 0 else self.image_width;
    }

    pub fn height(self: IconDirEntry) usize {
        return if (self.image_height == 256) 0 else self.image_height;
    }
};

pub const IconDir = struct {
    kind: Kind,
    entries: []IconDirEntry,
};

pub const ICO = struct {
    dir: IconDir = undefined,

    pub const EncoderOptions = struct {
        pub const Cursor = struct {
            hotspot_x: u16,
            hotspot_y: u16,
        };

        pub const Inner = union(enum) {
            bmp: BMP.EncoderOptions,
            png: PNG.EncoderOptions,
        };

        kind: union(enum) {
            icon: void,
            cursor: Cursor,
        } = .icon,
        inner: Inner = .bmp,
    };

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

        var ico: ICO = .{};

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

    pub fn writeImage(
        allocator: std.mem.Allocator,
        write_stream: *ImageUnmanaged.Stream,
        image: ImageUnmanaged,
        encoder_options: ImageUnmanaged.EncoderOptions,
    ) ImageUnmanaged.WriteError!void {
        var ico: ICO = .{};

        ico.dir.kind = switch (encoder_options.ico.kind) {
            .icon => .icon,
            .cursor => .cursor,
        };

        const entry = try allocator.create(IconDirEntry);
        errdefer allocator.destroy(entry);

        entry.* = switch (encoder_options.ico.kind) {
            .icon => .{
                .image_width = if (image.width == 256) 0 else @intCast(image.width),
                .image_height = if (image.height == 256) 0 else @intCast(image.height),
                .color_palette_size = 0,
                .color_planes = 1,
                .bits_per_pixel = switch (encoder_options.ico.inner) {
                    .bmp => switch (image.pixels) {
                        .bgra32 => @bitSizeOf(color.Bgra32),
                        else => return ImageUnmanaged.WriteError.Unsupported,
                    },
                    .png => 0,
                },
                .hotspot_x = 0,
                .hotspot_y = 0,
                .image_data_size = 0,
                .data_offset = 0,
            },
            .cursor => |cursor_options| .{
                .image_width = if (image.width == 256) 0 else @intCast(image.width),
                .image_height = if (image.height == 256) 0 else @intCast(image.height),
                .color_palette_size = 0,
                .color_planes = 0,
                .bits_per_pixel = 0,
                .hotspot_x = cursor_options.hotspot_x,
                .hotspot_y = cursor_options.hotspot_y,
                .image_data_size = 0,
                .data_offset = 0,
            },
        };

        ico.dir.entries = entry[0..1];

        try ico.write(write_stream, &.{image.pixels}, encoder_options.ico.inner);
    }

    pub fn write(
        self: *ICO,
        stream: *ImageUnmanaged.Stream,
        entry_pixels: []const color.PixelStorage,
        inner_options: EncoderOptions.Inner,
    ) ImageUnmanaged.WriteError!void {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceWriter(stream);
        const entries_start = try self.writeHeader(&buffered_stream);

        const writer = buffered_stream.writer();

        for (0.., self.dir.entries, entry_pixels) |i, entry_info, pixels| {
            const start_pos = try buffered_stream.getPos();

            switch (inner_options) {
                .png => |png_options| {
                    const pixel_format = std.meta.activeTag(pixels);
                    const header: png.HeaderData = .{
                        .width = @intCast(entry_info.width()),
                        .height = @intCast(entry_info.height()),
                        .bit_depth = pixel_format.bitsPerChannel(),
                        .color_type = try png_types.ColorType.fromPixelFormat(pixel_format),
                        .compression_method = .deflate,
                        .filter_method = .adaptive,
                        .interlace_method = if (png_options.interlaced) .adam7 else .none,
                    };

                    try PNG.write(writer, pixels, header, png_options.filter_choice);
                },
                .bmp => {
                    try BMP.writeInfoHeader(writer, .{
                        .windows31 = .{
                            .header_size = bmp.BitmapInfoHeaderWindows31.HeaderSize,
                            .width = @intCast(entry_info.width()),
                            .height = @intCast(entry_info.height()),
                            .color_plane = 0,
                            .bit_count = 32,
                            .compression_method = .none,
                            .image_raw_size = 0,
                            .horizontal_resolution = 0,
                            .vertical_resolution = 0,
                            .palette_size = 0,
                            .important_colors = 0,
                        },
                    });
                    try BMP.writePixels(writer, pixels, @intCast(entry_info.width()), @intCast(entry_info.height()));
                },
            }

            const end_pos = try buffered_stream.getPos();
            const image_size = end_pos - start_pos;

            const entry_info_data_size_offset = entries_start + (@sizeOf(u8) * 4 + @sizeOf(u16) * 2 + @sizeOf(u32) * 2) * @as(u64, @intCast(i + 1)) - @sizeOf(u32) * 2;
            try buffered_stream.seekTo(entry_info_data_size_offset);

            try writer.writeInt(u32, @intCast(image_size), .little);
            try writer.writeInt(u32, @intCast(start_pos), .little);
        }

        try buffered_stream.flush();
    }

    pub fn writeHeader(self: *ICO, buffered_stream: anytype) !u64 {
        const writer = buffered_stream.writer();

        try writer.writeInt(u16, 0, .little); // reserved
        try writer.writeInt(u16, @intFromEnum(self.dir.kind), .little);
        try writer.writeInt(u16, @intCast(self.dir.entries.len), .little);

        const entries_start = try buffered_stream.getPos();

        for (self.dir.entries) |entry| {
            try writer.writeInt(u8, entry.image_width, .little);
            try writer.writeInt(u8, entry.image_height, .little);
            try writer.writeInt(u8, entry.color_palette_size, .little);
            try writer.writeInt(u8, 0, .little); // reserved

            switch (self.dir.kind) {
                .icon => {
                    try writer.writeInt(u16, entry.color_planes, .little);
                    try writer.writeInt(u16, entry.bits_per_pixel, .little);
                },
                .cursor => {
                    try writer.writeInt(u16, entry.hotspot_x, .little);
                    try writer.writeInt(u16, entry.hotspot_y, .little);
                },
            }

            try writer.writeInt(u32, 0, .little); // image data size
            try writer.writeInt(u32, 0, .little); // image data offset
        }

        return entries_start;
    }
};
