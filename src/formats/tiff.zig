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
const types = @import("tiff/types.zig");

pub const Header = types.Header;
pub const IFD = types.IFD;
pub const BitmapDescriptor = types.BitmapDescriptor;
pub const TagField = types.TagField;

pub const TIFF = struct {
    endianess: std.builtin.Endian = undefined,
    header: Header = undefined,
    // TIFF can have many images but right now
    // we handle only the first one
    ifd: IFD = undefined,
    bitmap: BitmapDescriptor = undefined,

    pub fn width(self: *TIFF) usize {
        return self.bitmap.image_width;
    }

    pub fn height(self: *TIFF) usize {
        return self.bitmap.image_height;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn decodeBitmap(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) !void {
        const endianess = self.endianess;
        const ifd = self.ifd;
        const tags_map = ifd.tags_map;
        const bitmap = &self.bitmap;

        var iterator = tags_map.keyIterator();

        while (iterator.next()) |key| {
            const tag: TagField = tags_map.get(key.*).?;
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
                    bitmap.strip_byte_counts = try tag.readTagData(stream, allocator, endianess);
                },
                .strip_offsets => {
                    bitmap.strip_offsets = try tag.readTagData(stream, allocator, endianess);
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
                },
                .x_resolution => {
                    bitmap.x_resolution = try tag.readRational(stream, endianess);
                },
                .y_resolution => {
                    bitmap.y_resolution = try tag.readRational(stream, endianess);
                },
                else => {
                    // skip optional tags
                },
            }
        }
    }

    pub fn readMono(self: *TIFF, pixels: []color.Grayscale1, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!void {
        const bitmap = &self.bitmap;
        const total_strips = (bitmap.image_height + bitmap.rows_per_strip - 1) / bitmap.rows_per_strip;
        const byte_counts_array = bitmap.strip_byte_counts.?;
        const offsets_array = bitmap.strip_offsets.?;
        const image_width = bitmap.image_width;
        const row_per_strips = bitmap.rows_per_strip;
        const photometric_interpretation = bitmap.photometric_interpretation;

        for (0..total_strips) |index| {
            const byte_count = byte_counts_array[index];
            const offset = offsets_array[index];
            const strip_buffer: []u8 = try allocator.alloc(u8, byte_count);
            var pixel_index = index * row_per_strips * image_width;
            defer allocator.free(strip_buffer);
            _ = try stream.seekTo(offset);
            _ = try stream.read(strip_buffer[0..]);
            for (0..byte_count) |strip_index| {
                const byte = strip_buffer[strip_index];
                for (0..8) |bit_index| {
                    const value: u1 = @truncate(byte >> @intCast(@as(u3, 7) - bit_index) & 1);
                    pixels[pixel_index + bit_index].value = if (photometric_interpretation == 0) value else value ^ 1;
                }
                pixel_index += 8;
            }
        }
    }

    pub fn read(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        self.endianess = try endianessDetect(stream);

        const reader = stream.reader();

        self.header = Header{
            .version = try reader.readInt(u16, self.endianess),
            .idf_offset = try reader.readInt(u32, self.endianess),
        };

        self.bitmap = BitmapDescriptor{};
        defer self.bitmap.deinit(allocator);

        self.ifd = try IFD.init(stream, allocator, self.header.idf_offset);
        defer self.ifd.deinit();

        try self.ifd.readTags(self.endianess);

        try self.decodeBitmap(stream, allocator);

        self.bitmap.debug();

        const pixel_format = try self.bitmap.guessPixelFormat();

        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.bitmap.image_width * self.bitmap.image_height);
        errdefer pixels.deinit(allocator);

        switch (pixels) {
            .grayscale1 => |data| {
                if (self.bitmap.fill_order == 1) {
                    try self.readMono(data, stream, allocator);
                } else {
                    // lower column values are stored in lower-order bits
                    return ImageUnmanaged.Error.Unsupported;
                }
            },
            else => {
                return ImageUnmanaged.Error.Unsupported;
            },
        }

        return pixels;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var tiff = TIFF{};

        const pixels = try tiff.read(stream, allocator);

        result.pixels = pixels;
        result.width = tiff.width();
        result.height = tiff.height();

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

        return ImageReadError.InvalidData;
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        _ = endianessDetect(stream) catch return false;

        return true;
    }
};
