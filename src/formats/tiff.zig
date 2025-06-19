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
const ccitt = @import("../compressions/ccitt.zig");
const lzw = @import("../compressions/lzw.zig");
const packbits = @import("../compressions/packbits.zig");
const zlib = std.compress.zlib;

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

        bitmap.bits_per_sample.resize(1);
        bitmap.bits_per_sample.data[0] = 1;

        var iterator = tags_map.keyIterator();

        while (iterator.next()) |key| {
            const tag: TagField = tags_map.get(key.*).?;
            switch (key.*) {
                .image_width => {
                    bitmap.image_width = tag.toLongOrShort(endianess);
                },
                .image_height => {
                    bitmap.image_height = tag.toLongOrShort(endianess);
                },
                .compression => {
                    bitmap.compression = @enumFromInt(tag.toShort(endianess));
                },
                .color_map => {
                    // get color_map data: TIFF stores components as 16-bit values
                    // and stores each component first.
                    // RRRRRRRRRR
                    // GGGGGGGGGG
                    // BBBBBBBBBB
                    const palette = try tag.readTagData(stream, allocator, endianess);
                    defer allocator.free(palette);
                    const num_colors: u16 = std.math.pow(u16, 2, bitmap.bits_per_sample.data[0]);

                    var color_map = &bitmap.color_map;
                    color_map.resize(num_colors);
                    for (0..num_colors) |color_index| {
                        // TIFF colors are stored as 16-bit components
                        color_map.data[color_index] = color.Rgba32.from.rgb(@truncate(palette[color_index] / 256), @truncate(palette[color_index + num_colors] / 256), @truncate(palette[color_index + num_colors * 2] / 256));
                    }
                },
                .strip_byte_counts => {
                    bitmap.strip_byte_counts = try tag.readTagData(stream, allocator, endianess);
                },
                .strip_offsets => {
                    bitmap.strip_offsets = try tag.readTagData(stream, allocator, endianess);
                },
                .rows_per_strip => {
                    bitmap.rows_per_strip = tag.toLongOrShort(endianess);
                },
                .photometric_interpretation => {
                    bitmap.photometric_interpretation = tag.toShort(endianess);
                },
                .samples_per_pixel => {
                    bitmap.samples_per_pixel = tag.toShort(endianess);
                },
                .resolution_unit => {
                    bitmap.resolution_unit = @enumFromInt(tag.toShort(endianess));
                },
                .new_subfile_type => {
                    bitmap.new_subfile_type = tag.toLong();
                },
                .bits_per_sample => {
                    var bits_per_sample = &bitmap.bits_per_sample;
                    bits_per_sample.resize(tag.data_count);
                    switch (tag.data_count) {
                        1 => bits_per_sample.data[0] = tag.toShort(endianess),
                        3, 4 => {
                            const components_bits_per_sample = try tag.readTagData(stream, allocator, endianess);
                            defer allocator.free(components_bits_per_sample);
                            for (0..tag.data_count) |index| {
                                bits_per_sample.data[index] = @truncate(components_bits_per_sample[index]);
                            }
                        },
                        else => return ImageError.Unsupported,
                    }
                },
                .extra_samples => {
                    var extra_samples = &bitmap.extra_samples;
                    extra_samples.resize(tag.data_count);
                    switch (tag.data_count) {
                        1 => extra_samples.data[0] = tag.toShort(endianess),
                        else => return ImageError.Unsupported,
                    }
                },
                .x_resolution => {
                    bitmap.x_resolution = try tag.readRational(stream, endianess);
                },
                .y_resolution => {
                    bitmap.y_resolution = try tag.readRational(stream, endianess);
                },
                .planar_configuration => {
                    bitmap.planar_configuration = tag.toShort(endianess);
                },
                .predictor => {
                    bitmap.predictor = tag.toShort(endianess);
                },
                else => {
                    // skip optional tags
                },
            }
        }
    }

    pub fn uncompressDeflate(_: *TIFF, read_stream: *ImageUnmanaged.Stream, dest_buffer: []u8) !void {
        var write_stream = std.io.fixedBufferStream(dest_buffer);

        zlib.decompress(read_stream.reader(), write_stream.writer()) catch {
            return ImageUnmanaged.ReadError.InvalidData;
        };
    }

    pub fn uncompressLZW(_: *TIFF, read_stream: *ImageUnmanaged.Stream, dest_buffer: []u8, allocator: std.mem.Allocator) !void {
        var write_stream = std.io.fixedBufferStream(dest_buffer);
        var lzw_decoder = try lzw.Decoder(.big).init(allocator, 8, 1);
        defer lzw_decoder.deinit();

        lzw_decoder.decode(read_stream.reader(), write_stream.writer()) catch {
            return ImageUnmanaged.ReadError.InvalidData;
        };
    }

    pub fn uncompressCCITT(self: *TIFF, read_stream: *ImageUnmanaged.Stream, dest_buffer: []u8, image_width: usize, num_rows: usize) !void {
        var write_stream = std.io.fixedBufferStream(dest_buffer);
        var ccitt_decoder = try ccitt.Decoder.init(image_width, num_rows, @truncate(self.bitmap.photometric_interpretation));
        ccitt_decoder.decode(read_stream.reader(), write_stream.writer()) catch {
            return ImageUnmanaged.ReadError.InvalidData;
        };
    }

    pub fn calRowByteSize(self: *TIFF) !usize {
        const bitmap = &self.bitmap;
        var total_bits: usize = 0;

        for (0..bitmap.samples_per_pixel) |index| {
            total_bits += bitmap.bits_per_sample.data[index];
        }

        if (total_bits == 1) {
            return bitmap.image_width >> 3;
        } else if (total_bits >= 8) {
            return bitmap.image_width * (total_bits / 8);
        }

        return ImageUnmanaged.Error.Unsupported;
    }

    pub fn readStrips(self: *TIFF, pixel_storage: *PixelStorage, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!void {
        const bitmap = &self.bitmap;
        const total_strips = (bitmap.image_height + bitmap.rows_per_strip - 1) / bitmap.rows_per_strip;
        const byte_counts_array = bitmap.strip_byte_counts.?;
        const offsets_array = bitmap.strip_offsets.?;
        const image_width = bitmap.image_width;
        const image_height = bitmap.image_height;
        const rows_per_strip = @min(bitmap.rows_per_strip, bitmap.image_height);
        const photometric_interpretation = bitmap.photometric_interpretation;
        const predictor = bitmap.predictor;
        const compression = bitmap.compression;
        const row_remainder = image_height % rows_per_strip;
        // Note: not sure why but row_per_strip may be bigger than the image_height
        const last_strip_row_count = if (image_height > rows_per_strip and row_remainder > 0) row_remainder else rows_per_strip;
        const row_byte_size = try self.calRowByteSize();

        for (0..total_strips) |index| {
            // last strip may have less rows than rows_per_strip
            const current_row_size = if (total_strips > 1 and index < total_strips - 1) rows_per_strip else last_strip_row_count;
            const byte_count = current_row_size * row_byte_size;
            const compressed_byte_count = byte_counts_array[index];
            const offset = offsets_array[index];
            // allocate buffer for the uncompressed strip_buffer
            const strip_buffer: []u8 = try allocator.alloc(u8, byte_count);
            var pixel_index = index * rows_per_strip * image_width;
            defer allocator.free(strip_buffer);
            _ = try stream.seekTo(offset);

            switch (compression) {
                .uncompressed => _ = try stream.read(strip_buffer[0..]),
                .packbits => _ = try packbits.decode(stream, strip_buffer, compressed_byte_count),
                .ccitt_rle => _ = try self.uncompressCCITT(stream, strip_buffer, image_width, current_row_size),
                .lzw => _ = try self.uncompressLZW(stream, strip_buffer, allocator),
                .deflate, .pixar_deflate => _ = try self.uncompressDeflate(stream, strip_buffer),
                else => return ImageUnmanaged.Error.Unsupported,
            }

            blk: switch (pixel_storage.*) {
                .grayscale1 => |pixels| {
                    for (0..byte_count) |strip_index| {
                        const byte = strip_buffer[strip_index];
                        for (0..8) |bit_index| {
                            const value: u1 = @truncate(byte >> @intCast(@as(u3, 7) - bit_index) & 1);
                            pixels[pixel_index].value = if (photometric_interpretation == 1) value else value ^ 1;
                            pixel_index += 1;
                            if (pixel_index >= pixels.len)
                                break :blk;
                        }
                    }
                },
                .grayscale8 => |pixels| {
                    for (0..byte_count) |strip_index| {
                        if (predictor == 1 or pixel_index % image_width == 0) {
                            pixels[pixel_index].value = strip_buffer[strip_index];
                        } else {
                            pixels[pixel_index].value = pixels[pixel_index - 1].value +% strip_buffer[strip_index];
                        }
                        pixel_index += 1;
                        if (pixel_index >= pixels.len)
                            break :blk;
                    }
                },
                .indexed8 => |*storage| {
                    const tiff_color_map = bitmap.color_map;
                    const palette = storage.palette;
                    for (0..bitmap.color_map.data.len) |color_index| {
                        palette[color_index] = tiff_color_map.data[color_index];
                    }
                    for (0..byte_count) |strip_index| {
                        if (predictor == 1 or pixel_index % image_width == 0) {
                            storage.indices[pixel_index] = strip_buffer[strip_index];
                        } else {
                            storage.indices[pixel_index] = storage.indices[pixel_index - 1] +% strip_buffer[strip_index];
                        }
                        pixel_index += 1;
                        if (pixel_index >= storage.indices.len)
                            break :blk;
                    }
                },
                .rgb24 => |storage| {
                    var strip_index: usize = 0;
                    while (strip_index < byte_count) : (strip_index += 3) {
                        if (predictor == 1 or pixel_index % image_width == 0) {
                            storage[pixel_index] = color.Rgb24.from.rgb(strip_buffer[strip_index], strip_buffer[strip_index + 1], strip_buffer[strip_index + 2]);
                        } else {
                            const previous_color = storage[pixel_index - 1];
                            storage[pixel_index] = color.Rgb24.from.rgb(previous_color.r +% strip_buffer[strip_index], previous_color.g +% strip_buffer[strip_index + 1], previous_color.b +% strip_buffer[strip_index + 2]);
                        }
                        pixel_index += 1;
                        if (pixel_index >= storage.len)
                            break :blk;
                    }
                },
                .rgba32 => |storage| {
                    var strip_index: usize = 0;
                    while (strip_index < byte_count) : (strip_index += 4) {
                        if (predictor == 1 or pixel_index % image_width == 0) {
                            storage[pixel_index] = color.Rgba32.from.rgba(strip_buffer[strip_index], strip_buffer[strip_index + 1], strip_buffer[strip_index + 2], strip_buffer[strip_index + 3]);
                        } else {
                            const previous_color = storage[pixel_index - 1];
                            storage[pixel_index] = color.Rgba32.from.rgba(previous_color.r +% strip_buffer[strip_index], previous_color.g +% strip_buffer[strip_index + 1], previous_color.b +% strip_buffer[strip_index + 2], previous_color.a +% strip_buffer[strip_index + 3]);
                        }
                        pixel_index += 1;
                        if (pixel_index >= storage.len)
                            break :blk;
                    }
                },
                else => return ImageUnmanaged.Error.Unsupported,
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

        const pixel_format = try self.bitmap.guessPixelFormat();

        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.bitmap.image_width * self.bitmap.image_height);
        errdefer pixels.deinit(allocator);

        switch (pixels) {
            .grayscale1, .grayscale8, .indexed8, .rgb24, .rgba32 => try self.readStrips(&pixels, stream, allocator),
            else => return ImageUnmanaged.Error.Unsupported,
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
