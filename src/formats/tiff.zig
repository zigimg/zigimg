const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const ImageError = ImageUnmanaged.Error;
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

const CompressionType = enum(u16) {
    // Some encoders (eg. ffmpeg) use 0 for raw images
    // although it's not mentionned in the TIFF specs.
    raw = 0,
    uncompressed = 1,
    ccit_1d = 2,
    gp_3_fax = 3,
    gp_4_fax = 4,
    lzw = 5,
    jpeg = 6,
    // old tag value used only in tiff v4
    uncompressed_old = 32771,
    packbits = 32773,
};

const ResolutionUnit = enum(u16) {
    // Some encoders (eg. ffmpeg) use 0 for resolution_unit
    // although it's not mentionned in the TIFF specs.
    not_specified = 0,
    no_unit = 1,
    inch = 2,
    cm = 3,
};

const TagId = enum(u16) { new_subfile_type = 254, image_width = 256, image_height = 257, bits_per_sample = 258, compression = 259, photometric_interpretation = 262, fill_order = 266, strip_offsets = 273, orientation = 274, samples_per_pixel = 277, rows_per_strip = 278, strip_byte_counts = 279, x_resolution = 282, y_resolution = 283, planar_configuration = 284, resolution_unit = 296, software = 305, extra_samples = 338, sample_format = 339, unknown_1 = 700, unknown_2 = 34665, unknown_3 = 34675 };

// We'll store all tags required for
// grayscale, color, and rgb encoded files
const BitmapDescriptor = struct {
    // bi-level/grayscale class type required tags
    compression: CompressionType = .uncompressed,
    // can be u16 or u32
    image_width: u32 = 0,
    // can be u16 or u32
    image_height: u32 = 0,
    // - b & w images: 1 is black or 0 is black
    // rgb: 2
    photometric_interpretation: u16 = 0,
    // can be u16/u32: number of rows in each but the last strip
    rows_per_strip: u32 = 0,
    // byte offset in each strip, can be u16/u32
    strip_offsets: ?[]u8 = null,
    // for each strip, number of bytes (after compression)
    strip_byte_counts: ?[]u8 = null,
    // number of pixels per resolution unit in image_width
    x_resolution: [2]u32 = .{ 0, 0 },
    // number of pixels per resolution unit in image_height
    y_resolution: [2]u32 = .{ 0, 0 },
    resolution_unit: ResolutionUnit = .no_unit,
    // Fields required for grayscale images
    // - b & w:
    // - grayscale: 4 / 8 allowed for grayscale images (16/256 shades)
    // - rgb: 8,8,8 (count == 3)
    // TODO: should be [samples_per_pixel]u16
    bits_per_sample: u16 = 1,
    // flags describing the image type
    new_subfile_type: u32 = 0,
    // palette class needs previous tags and:
    // color_map: utils.FixedStorage(color.Rgba32, 0) = .{},
    // rgb class needs previous tags and:
    // number of components per pixel
    samples_per_pixel: u16 = 1,
    // Default fill_order: pixels are arranged within a byte such that
    // pixels with lower column values are stored in the higher-order bits of the byte.
    fill_order: u16 = 1,

    pub fn debug(self: *BitmapDescriptor) void {
        inline for (std.meta.fields(BitmapDescriptor)) |f| {
            std.debug.print(f.name ++ "={any}\n", .{@as(f.type, @field(self, f.name))});
        }
        if (self.strip_byte_counts != null) {
            const offsets: []u32 = @as(*const []u32, @ptrCast(&self.strip_byte_counts.?[0..])).*;
            // const hex = std.fmt.bytesToHex(offsets, .upper);
            // for (0..self.strip_byte_counts.?.len) |index| {
            //     std.debug.print("{x} ", .{self.strip_byte_counts.?[index]});
            // }
            // std.debug.print("\n", .{});
            std.debug.print("*** first byte count = {}\n", .{std.mem.toNative(u32, offsets[0], .little)});
        }
    }

    pub fn guessPixelFormat(self: *BitmapDescriptor) ImageReadError!PixelFormat {
        if (self.bits_per_sample == 1) {
            return PixelFormat.grayscale1;
        }

        return ImageError.Unsupported;
    }

    pub fn deinit(self: *BitmapDescriptor, allocator: std.mem.Allocator) void {
        if (self.strip_offsets != null) {
            allocator.free(self.strip_offsets.?);
        }

        if (self.strip_byte_counts != null) {
            allocator.free(self.strip_byte_counts.?);
        }
    }
};

const Header = extern struct {
    const size = 6;

    version: u16 align(1),
    idf_offset: u32 align(1),

    const little_endian_magic = "II";
    const big_endian_magic = "MM";

    comptime {
        std.debug.assert(@sizeOf(Header) == Header.size);
    }
};

// Tag as found inside the TIFF file
const PackedTag = struct {
    const size = 12;

    tag_id: u16 align(1),
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    comptime {
        std.debug.assert(@sizeOf(PackedTag) == PackedTag.size);
    }
};

const TagField = struct {
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    pub inline fn toLong(self: *const TagField) u32 {
        return self.data_offset;
    }

    // Some fields (eg. image_width) can be encoded as long or short:
    // this function either returns an u16 casted to u32, or an u32
    // based on the tag data_type
    pub inline fn toLongOrShort(self: *const TagField) u32 {
        return if (self.data_type == 3) self.toShort() else self.data_offset;
    }

    pub inline fn toShort(self: *const TagField) u16 {
        // smaller than 32-bit values are left-aligned
        return @truncate(self.data_offset >> 16);
    }

    // not sure what to do about these two values yet
    pub fn readRational(self: *const TagField, stream: *ImageUnmanaged.Stream, endianess: std.builtin.Endian) ![2]u32 {
        try stream.seekTo(self.data_offset);
        const reader = stream.reader();

        return [2]u32{
            try reader.readInt(u32, endianess),
            try reader.readInt(u32, endianess),
        };
    }

    pub fn readU16orU32Array(self: *const TagField, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ![]u8 {
        const byte_size = if (self.data_type == 3) self.data_count * 2 else self.data_count * 4;
        const data = try allocator.alloc(u8, byte_size);

        std.debug.print("++ seeking to {}\n", .{self.data_offset});

        try stream.seekTo(self.data_offset);
        _ = try stream.read(data[0..]);

        return data;
    }
};

const IFD = struct {
    num_tag_entries: u16,
    tag_map: std.AutoHashMap(TagId, TagField),
    next_idf_offset: u32,
};

pub const TIFF = struct {
    endianess: std.builtin.Endian = undefined,
    header: Header = undefined,
    // TIFF can have many images but right now
    // we handle only the first one
    first_ifd: IFD = undefined,

    pub fn width(_: *TIFF) usize {
        return 0;
    }

    pub fn height(_: *TIFF) usize {
        return 0;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn readIFD(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !void {
        std.debug.print("need to seek to {} (size = {})\n", .{ self.header.idf_offset, try stream.getEndPos() });
        var current_idf_offset = self.header.idf_offset;
        try stream.seekTo(current_idf_offset);
        const reader = stream.reader();

        while (current_idf_offset > 0) {
            std.debug.print("reading idf\n", .{});
            current_idf_offset = 0;
            const num_tag_entries = try reader.readInt(u16, self.endianess);
            const tags_array: []u8 = try allocator.alloc(u8, @sizeOf(PackedTag) * num_tag_entries);
            defer allocator.free(tags_array);
            _ = try reader.readAll(tags_array);
            const next_ifd_offset = try reader.readInt(u32, self.endianess);
            var tags_map = std.AutoHashMap(TagId, TagField).init(allocator);
            const tags_list = @as(*const []PackedTag, @ptrCast(&tags_array[0..])).*;
            // We should iterate through all IFD, but since we support
            // only one right now, we just set next offset to 0.
            current_idf_offset = 0;
            for (0..num_tag_entries) |index| {
                const tag = tags_list[index];
                std.debug.print("Adding id={}\n", .{std.mem.toNative(u16, tag.tag_id, self.endianess)});
                try tags_map.put(@enumFromInt(std.mem.toNative(u16, tag.tag_id, self.endianess)), TagField{
                    .data_type = std.mem.toNative(u16, tag.data_type, self.endianess),
                    .data_count = std.mem.toNative(u32, tag.data_count, self.endianess),
                    .data_offset = std.mem.toNative(u32, tag.data_offset, self.endianess),
                });
                // std.debug.print("tag id={} type={} count={x} offset={}\n", .{std.mem.toNative(u16, tag.tag_id, self.endianess)});
                std.debug.print("[{}] = {any}\n", .{ std.mem.toNative(u16, tag.tag_id, self.endianess), tags_map.get(@enumFromInt(std.mem.toNative(u16, tag.tag_id, self.endianess))) });
            }
            self.first_ifd = IFD{ .num_tag_entries = num_tag_entries, .next_idf_offset = next_ifd_offset, .tag_map = tags_map };
        }
    }

    pub fn decodeTags(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator, ifd: *IFD) !void {
        const endianess = self.endianess;
        var bitmap = BitmapDescriptor{};

        var iterator = ifd.tag_map.keyIterator();

        while (iterator.next()) |key| {
            const tag: TagField = ifd.tag_map.get(key.*).?;
            switch (key.*) {
                .image_width => {
                    bitmap.image_width = tag.toLongOrShort();
                },
                .image_height => {
                    bitmap.image_height = tag.toLongOrShort();
                },
                .compression => {
                    bitmap.compression = @enumFromInt(tag.toShort());
                },
                .strip_byte_counts => {
                    bitmap.strip_byte_counts = try tag.readU16orU32Array(stream, allocator);
                },
                .strip_offsets => {
                    bitmap.strip_offsets = try tag.readU16orU32Array(stream, allocator);
                },
                .rows_per_strip => {
                    bitmap.rows_per_strip = tag.toLongOrShort();
                },
                .photometric_interpretation => {
                    bitmap.photometric_interpretation = tag.toShort();
                },
                .samples_per_pixel => {
                    bitmap.samples_per_pixel = tag.toShort();
                },
                .resolution_unit => {
                    bitmap.resolution_unit = @enumFromInt(tag.toShort());
                },
                .new_subfile_type => {
                    bitmap.new_subfile_type = tag.toLong();
                },
                .bits_per_sample => {
                    switch (tag.data_count) {
                        1 => bitmap.bits_per_sample = tag.toShort(),
                        else => return ImageError.Unsupported,
                    }
                    std.debug.print("{}\n", .{tag});
                },
                .x_resolution => {
                    bitmap.x_resolution = try tag.readRational(stream, endianess);
                },
                .y_resolution => {
                    bitmap.y_resolution = try tag.readRational(stream, endianess);
                },
                else => {
                    std.debug.print("Skipping tag id={} {}\n", .{ key, tag });
                },
            }
        }

        bitmap.debug();

        bitmap.deinit(allocator);
    }

    pub fn read(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        self.endianess = try endianessDetect(stream);

        const reader = stream.reader();

        std.debug.print("reading IFD, pos={}, endianess={}\n", .{ try stream.getPos(), self.endianess });

        self.header = Header{
            .version = try reader.readInt(u16, self.endianess),
            .idf_offset = try reader.readInt(u32, self.endianess),
        };

        std.debug.print("reading IFD, pos after IFD={}\n", .{try stream.getPos()});

        try self.readIFD(stream, allocator);

        try self.decodeTags(stream, allocator, &self.first_ifd);

        self.first_ifd.tag_map.deinit();

        var pixels = try color.PixelStorage.init(allocator, PixelFormat.bgr24, 320 * 200);
        errdefer pixels.deinit(allocator);

        std.debug.print("Read IFD: num_entries = {}\n", .{self.first_ifd.num_tag_entries});

        // for (0..20) |index| {
        //     const tag = self.first_ifd.tag_map[index];
        //     std.debug.print("tag id={} type={} count={x} offset={}\n", .{ std.mem.toNative(u16, tag.tag_id, self.endianess), std.mem.toNative(u16, tag.data_type, self.endianess), std.mem.toNative(u32, tag.data_count, self.endianess), std.mem.toNative(u32, tag.data_offset, self.endianess) >> 16 });
        // }

        return pixels;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var tiff = TIFF{};

        const pixels = try tiff.read(stream, allocator);

        result.pixels = pixels;

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    fn endianessDetect(stream: *ImageUnmanaged.Stream) !std.builtin.Endian {
        var magic_buffer: [Header.little_endian_magic.len]u8 = undefined;

        _ = try stream.read(magic_buffer[0..]);

        if (std.mem.eql(u8, magic_buffer[0..], Header.little_endian_magic[0..])) {
            return std.builtin.Endian.little;
        } else if (std.mem.eql(u8, magic_buffer[0..], Header.big_endian_magic[0..])) {
            return std.builtin.Endian.big;
        }

        return ImageReadError.Unsupported;
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        _ = try endianessDetect(stream);

        return true;
    }
};
