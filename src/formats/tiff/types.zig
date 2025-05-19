const std = @import("std");
const ImageUnmanaged = @import("../../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const ImageError = ImageUnmanaged.Error;
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const color = @import("../../color.zig");
const utils = @import("../../utils.zig");
const builtin = @import("builtin");
const native_endian = builtin.target.cpu.arch.endian();

pub const CompressionType = enum(u16) {
    uncompressed = 1,
    ccitt_rle = 2,
    gp_3_fax = 3,
    gp_4_fax = 4,
    lzw = 5,
    jpeg = 6,
    deflate = 8,
    // old tag value used only in tiff v4
    uncompressed_old = 32771,
    packbits = 32773,
    pixar_deflate = 32946,
};

pub const ResolutionUnit = enum(u16) {
    no_unit = 1,
    inch = 2,
    cm = 3,
};

pub const TagId = enum(u16) {
    new_subfile_type = 254,
    image_width = 256,
    image_height = 257,
    bits_per_sample = 258,
    compression = 259,
    photometric_interpretation = 262,
    fill_order = 266,
    document_name = 269,
    image_description = 270,
    strip_offsets = 273,
    orientation = 274,
    samples_per_pixel = 277,
    rows_per_strip = 278,
    strip_byte_counts = 279,
    x_resolution = 282,
    y_resolution = 283,
    planar_configuration = 284,
    x_position = 286,
    y_position = 287,
    t4_options = 292,
    resolution_unit = 296,
    page_number = 297,
    software = 305,
    predictor = 317,
    white_point = 318,
    primary_chromaticities = 319,
    color_map = 320,
    extra_samples = 338,
    sample_format = 339,
    unknown_1 = 700,
    unknown_2 = 34665,
    unknown_3 = 34675,
};

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
    // - b & w: [1] (default value)
    // - grayscale: [4] or [8] allowed for grayscale images (16/256 shades)
    // - rgb: [8,8,8]
    bits_per_sample: utils.FixedStorage(u16, 8) = .{},
    // flags describing the image type
    new_subfile_type: u32 = 0,
    // palette class needs previous tags and:
    color_map: utils.FixedStorage(color.Rgba32, 256) = .{},
    // rgb class needs previous tags and:
    // number of components per pixel
    samples_per_pixel: u16 = 1,
    // Default fill_order: pixels are arranged within a byte such that
    // pixels with lower column values are stored in the higher-order bits of the byte.
    fill_order: u16 = 1,
    // contains extra_samples description
    extra_samples: utils.FixedStorage(u16, 8) = .{},

    planar_configuration: u16 = 1,

    // predictor used before coding (mostly LZW)
    predictor: u16 = 1,

    pub fn debug(self: *BitmapDescriptor) void {
        std.log.debug("{}\n", .{self});
    }

    pub fn guessPixelFormat(self: *BitmapDescriptor) ImageReadError!PixelFormat {
        // only raw, packbits, lzw and ccitt_rle compression supported for now
        switch (self.compression) {
            .uncompressed,
            .packbits,
            .ccitt_rle,
            .lzw,
            .deflate,
            .pixar_deflate,
            => {},
            else => return ImageError.Unsupported,
        }

        switch (self.photometric_interpretation) {
            // bi-level/grayscale pictures
            0, 1 => {
                const bits_per_sample = self.bits_per_sample.data[0];
                switch (bits_per_sample) {
                    // lower column values are stored in lower-order bits
                    // no support for bilevel files with a predictor
                    1 => return if (self.fill_order == 1 and self.predictor == 1) PixelFormat.grayscale1 else ImageError.Unsupported,
                    // TODO
                    4 => return ImageError.Unsupported,
                    8 => return PixelFormat.grayscale8,
                    else => return ImageError.Unsupported,
                }
            },
            // pictures with color_map
            3 => {
                const bits_per_sample = self.bits_per_sample.data[0];
                switch (bits_per_sample) {
                    8 => return PixelFormat.indexed8,
                    // TODO
                    4 => return ImageError.Unsupported,
                    else => return ImageError.Unsupported,
                }
            },
            // RGB pictures
            2 => {
                const bits = self.bits_per_sample.data;
                switch (bits.len) {
                    3 => {
                        // 3 channels, 8-bit per each channel: rgb24
                        if (bits[0] == 8 and bits[1] == 8 and bits[2] == 8)
                            return PixelFormat.rgb24;

                        return ImageError.Unsupported;
                    },
                    4 => {
                        // 4 channels: RGBA or RGB/pre-multiplied
                        const extra_sample_format = self.extra_samples.data[0];

                        if (bits[0] == 8 and bits[1] == 8 and bits[2] == 8 and bits[3] == 8 and (extra_sample_format == 2 or extra_sample_format == 1))
                            return PixelFormat.rgba32;

                        return ImageError.Unsupported;
                    },
                    else => return ImageError.Unsupported,
                }
            },
            else => return ImageError.Unsupported,
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
pub const PackedTag = extern struct {
    const size = 12;

    tag_id: u16 align(1),
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    comptime {
        std.debug.assert(@sizeOf(PackedTag) == PackedTag.size);
    }
};

pub const TagField = extern struct {
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    pub inline fn toLong(self: *const TagField) u32 {
        return self.data_offset;
    }

    // Some fields (eg. image_width) can be encoded as long or short:
    // this function either returns an u16 casted to u32, or an u32
    // based on the tag data_type
    pub inline fn toLongOrShort(self: *const TagField, endianess: std.builtin.Endian) u32 {
        return if (self.data_type == @intFromEnum(TagType.short)) self.toShort(endianess) else self.data_offset;
    }

    pub inline fn toShort(self: *const TagField, endianess: std.builtin.Endian) u16 {
        return if (endianess == .big) @truncate(self.data_offset >> 16) else @truncate(self.data_offset & 0xFFFF);
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
        const long_data: []u32 = try allocator.alloc(u32, self.data_count);

        // the offset is enough to hold the data so
        // the offset already holds the data
        if (self.data_count == 1) {
            long_data[0] = self.data_offset;
            return long_data;
        }

        const data: []u8 = try allocator.alloc(u8, byte_size);
        defer allocator.free(data);

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
            const slice_to_swap = std.mem.bytesAsSlice(u16, data);
            if (native_endian != endianess) {
                for (slice_to_swap, 0..self.data_count) |value, index| {
                    long_data[index] = @byteSwap(value);
                }
            } else {
                for (slice_to_swap, 0..self.data_count) |value, index| {
                    long_data[index] = value;
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
