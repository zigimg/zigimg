const std = @import("std");
const ImageUnmanaged = @import("../../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const ImageError = ImageUnmanaged.Error;
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const builtin = @import("builtin");
const native_endian = builtin.target.cpu.arch.endian();

pub const CompressionType = enum(u16) {
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

pub const ResolutionUnit = enum(u16) {
    // Some encoders (eg. ffmpeg) use 0 for resolution_unit
    // although it's not mentionned in the TIFF specs.
    not_specified = 0,
    no_unit = 1,
    inch = 2,
    cm = 3,
};

pub const TagId = enum(u16) { new_subfile_type = 254, image_width = 256, image_height = 257, bits_per_sample = 258, compression = 259, photometric_interpretation = 262, fill_order = 266, strip_offsets = 273, orientation = 274, samples_per_pixel = 277, rows_per_strip = 278, strip_byte_counts = 279, x_resolution = 282, y_resolution = 283, planar_configuration = 284, resolution_unit = 296, software = 305, extra_samples = 338, sample_format = 339, unknown_1 = 700, unknown_2 = 34665, unknown_3 = 34675 };

// We'll store all tags required for
// grayscale, color, and rgb encoded files
pub const BitmapDescriptor = struct {
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
    strip_offsets: ?[]u32 = null,
    // for each strip, number of bytes (after compression)
    strip_byte_counts: ?[]u32 = null,
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
        std.log.debug("{}\n", .{self});
    }

    pub fn guessPixelFormat(self: *BitmapDescriptor) ImageReadError!PixelFormat {
        if (self.bits_per_sample == 0) {
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

pub const Header = extern struct {
    const size = 6;

    version: u16 align(1),
    idf_offset: u32 align(1),

    pub const little_endian_magic = "II";
    pub const big_endian_magic = "MM";

    comptime {
        std.debug.assert(@sizeOf(Header) == Header.size);
    }
};

pub const TagType = enum(u16) {
    short = 3,
    long = 4,
};

// Tag as found inside the TIFF file
pub const PackedTag = struct {
    const size = 12;

    tag_id: u16 align(1),
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    comptime {
        std.debug.assert(@sizeOf(PackedTag) == PackedTag.size);
    }
};

pub const TagField = struct {
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
        return if (self.data_type == @intFromEnum(TagType.short)) self.toShort() else self.data_offset;
    }

    pub inline fn toShort(self: *const TagField) u16 {
        // Smaller than 32-bit values are left-aligned
        return @truncate(self.data_offset >> 16);
    }

    pub fn readRational(self: *const TagField, stream: *ImageUnmanaged.Stream, endianess: std.builtin.Endian) ![2]u32 {
        try stream.seekTo(self.data_offset);
        const reader = stream.reader();

        return [2]u32{
            try reader.readInt(u32, endianess),
            try reader.readInt(u32, endianess),
        };
    }

    pub fn readTagData(self: *const TagField, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator, endianess: std.builtin.Endian) ![]u32 {
        const byte_size = if (self.data_type == @intFromEnum(TagType.short)) self.data_count * 2 else self.data_count * 4;
        const data: []u8 = try allocator.alloc(u8, byte_size);
        defer allocator.free(data);

        const long_data: []u32 = try allocator.alloc(u32, self.data_count);

        try stream.seekTo(self.data_offset);
        _ = try stream.read(data[0..]);

        if (self.data_type == @intFromEnum(TagType.long)) {
            if (endianess == native_endian) {
                @memcpy(std.mem.sliceAsBytes(long_data)[0..], std.mem.sliceAsBytes(data)[0..]);
            } else {
                const slice_to_swap = std.mem.bytesAsSlice(u32, data);
                for (slice_to_swap, 0..self.data_count) |value, index| {
                    long_data[index] = @byteSwap(value);
                }
            }
        } else {
            if (endianess == native_endian) {
                @memcpy(std.mem.sliceAsBytes(long_data)[0..], std.mem.sliceAsBytes(data)[0..]);
            } else {
                const slice_to_swap = std.mem.bytesAsSlice(u16, data);
                for (slice_to_swap, 0..self.data_count) |value, index| {
                    long_data[index] = @byteSwap(value);
                }
            }
        }

        return long_data;
    }
};

pub const IFD = struct {
    ifd_offset: u32 = 0,
    num_tag_entries: u16 = 0,
    tags_map: std.AutoHashMap(TagId, TagField),
    next_ifd_offset: u32 = 0,
    stream: *ImageUnmanaged.Stream,
    allocator: std.mem.Allocator,

    pub fn init(stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator, ifd_offset: u32) !IFD {
        return .{
            .stream = stream,
            .allocator = allocator,
            .ifd_offset = ifd_offset,
            .tags_map = std.AutoHashMap(TagId, TagField).init(allocator),
        };
    }

    pub fn readTags(self: *IFD, endianess: std.builtin.Endian) !void {
        const stream = self.stream;

        try stream.seekTo(self.ifd_offset);
        const reader = stream.reader();

        const num_tag_entries = try reader.readInt(u16, endianess);
        const tags_array: []u8 = try self.allocator.alloc(u8, @sizeOf(PackedTag) * num_tag_entries);
        defer self.allocator.free(tags_array);
        _ = try reader.readAll(tags_array);
        const next_ifd_offset = try reader.readInt(u32, endianess);
        const tags_list = @as(*const []PackedTag, @ptrCast(&tags_array[0..])).*;
        // We should iterate through all IFD, but since we support
        // only one right now, we just set next offset to 0.

        for (0..num_tag_entries) |index| {
            const tag = tags_list[index];
            try self.tags_map.put(@enumFromInt(std.mem.toNative(u16, tag.tag_id, endianess)), TagField{
                .data_type = std.mem.toNative(u16, tag.data_type, endianess),
                .data_count = std.mem.toNative(u32, tag.data_count, endianess),
                .data_offset = std.mem.toNative(u32, tag.data_offset, endianess),
            });
        }

        self.num_tag_entries = num_tag_entries;
        self.next_ifd_offset = next_ifd_offset;
    }

    pub fn deinit(self: *IFD) void {
        self.tags_map.deinit();
    }
};
