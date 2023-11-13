const FormatInterface = @import("../FormatInterface.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const Image = @import("../Image.zig");
const std = @import("std");
const utils = @import("../utils.zig");

pub const TGAImageType = packed struct(u8) {
    indexed: bool = false,
    truecolor: bool = false,
    pad0: bool = false,
    run_length: bool = false,
    pad1: u4 = 0,
};

pub const TGAColorMapSpec = extern struct {
    first_entry_index: u16 align(1) = 0,
    length: u16 align(1) = 0,
    bit_depth: u8 align(1) = 0,
};

pub const TGADescriptor = packed struct(u8) {
    num_attributes_bit: u4 = 0,
    right_to_left: bool = false,
    top_to_bottom: bool = false,
    pad: u2 = 0,
};

pub const TGAImageSpec = extern struct {
    origin_x: u16 align(1) = 0,
    origin_y: u16 align(1) = 0,
    width: u16 align(1) = 0,
    height: u16 align(1) = 0,
    bit_per_pixel: u8 align(1) = 0,
    descriptor: TGADescriptor align(1) = .{},
};

pub const TGAHeader = extern struct {
    id_length: u8 align(1) = 0,
    has_color_map: u8 align(1) = 0,
    image_type: TGAImageType align(1) = .{},
    color_map_spec: TGAColorMapSpec align(1) = .{},
    image_spec: TGAImageSpec align(1) = .{},

    pub fn isValid(self: TGAHeader) bool {
        if (self.has_color_map != 0 and self.has_color_map != 1) {
            return false;
        }

        if (self.image_type.pad0) {
            return false;
        }

        if (self.image_type.pad1 != 0) {
            return false;
        }

        switch (self.color_map_spec.bit_depth) {
            0, 15, 16, 24, 32 => {},
            else => {
                return false;
            },
        }

        return true;
    }
};

pub const TGAAttributeType = enum(u8) {
    no_alpha = 0,
    undefined_alpha_ignore = 1,
    undefined_alpha_retained = 2,
    useful_alpha_channel = 3,
    premultipled_alpha = 4,
};

pub const TGAExtension = extern struct {
    extension_size: u16 align(1) = 0,
    author_name: [41]u8 align(1) = undefined,
    author_comment: [324]u8 align(1) = undefined,
    timestamp: [12]u8 align(1) = undefined,
    job_id: [41]u8 align(1) = undefined,
    job_time: [6]u8 align(1) = undefined,
    software_id: [41]u8 align(1) = undefined,
    software_version: [3]u8 align(1) = undefined,
    key_color: [4]u8 align(1) = undefined,
    pixel_aspect: [4]u8 align(1) = undefined,
    gamma_value: [4]u8 align(1) = undefined,
    color_correction_offset: u32 align(1) = 0,
    postage_stamp_offset: u32 align(1) = 0,
    scanline_offset: u32 align(1) = 0,
    attributes: TGAAttributeType align(1) = .no_alpha,
};

pub const TGAFooter = extern struct {
    extension_offset: u32 align(1) = 0,
    dev_area_offset: u32 align(1) = 0,
    signature: [16]u8 align(1) = undefined,
    dot: u8 align(1) = '.',
    null_value: u8 align(1) = 0,
};

pub const TGASignature = "TRUEVISION-XFILE";

comptime {
    std.debug.assert(@sizeOf(TGAHeader) == 18);
    std.debug.assert(@sizeOf(TGAExtension) == 495);
}

const TargaRLEDecoder = struct {
    source_reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader,
    allocator: std.mem.Allocator,
    bytes_per_pixel: usize,

    state: State = .read_header,
    repeat_count: usize = 0,
    repeat_data: []u8 = undefined,
    data_stream: std.io.FixedBufferStream([]u8) = undefined,

    pub const Reader = std.io.Reader(*TargaRLEDecoder, Image.ReadError, read);

    const State = enum {
        read_header,
        repeated,
        raw,
    };

    const PacketType = enum(u1) {
        raw = 0,
        repeated = 1,
    };
    const PacketHeader = packed struct {
        pixel_count: u7,
        packet_type: PacketType,
    };

    pub fn init(allocator: std.mem.Allocator, source_reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader, bytes_per_pixels: usize) !TargaRLEDecoder {
        var result = TargaRLEDecoder{
            .allocator = allocator,
            .source_reader = source_reader,
            .bytes_per_pixel = bytes_per_pixels,
        };

        result.repeat_data = try allocator.alloc(u8, bytes_per_pixels);
        result.data_stream = std.io.fixedBufferStream(result.repeat_data);
        return result;
    }

    pub fn deinit(self: TargaRLEDecoder) void {
        self.allocator.free(self.repeat_data);
    }

    pub fn read(self: *TargaRLEDecoder, dest: []u8) Image.ReadError!usize {
        var read_count: usize = 0;

        if (self.state == .read_header) {
            const packet_header = try utils.readStructLittle(self.source_reader, PacketHeader);

            if (packet_header.packet_type == .repeated) {
                self.state = .repeated;

                self.repeat_count = @as(usize, @intCast(packet_header.pixel_count)) + 1;

                _ = try self.source_reader.read(self.repeat_data);

                self.data_stream.reset();
            } else if (packet_header.packet_type == .raw) {
                self.state = .raw;

                self.repeat_count = (@as(usize, @intCast(packet_header.pixel_count)) + 1) * self.bytes_per_pixel;
            }
        }

        switch (self.state) {
            .repeated => {
                _ = try self.data_stream.read(dest);

                const end_pos = try self.data_stream.getEndPos();
                if (self.data_stream.pos >= end_pos) {
                    self.data_stream.reset();

                    self.repeat_count -= 1;
                }

                read_count = dest.len;
            },
            .raw => {
                const read_bytes = try self.source_reader.read(dest);

                self.repeat_count -= read_bytes;

                read_count = read_bytes;
            },
            else => {
                return Image.ReadError.InvalidData;
            },
        }

        if (self.repeat_count == 0) {
            self.state = .read_header;
        }

        return read_count;
    }

    pub fn reader(self: *TargaRLEDecoder) Reader {
        return .{ .context = self };
    }
};

pub const TargaStream = union(enum) {
    image: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader,
    rle: TargaRLEDecoder,

    pub const Reader = std.io.Reader(*TargaStream, Image.ReadError, read);

    pub fn read(self: *TargaStream, dest: []u8) Image.ReadError!usize {
        switch (self.*) {
            .image => |*x| return x.read(dest),
            .rle => |*x| return x.read(dest),
        }
    }

    pub fn reader(self: *TargaStream) Reader {
        return .{ .context = self };
    }
};

pub const TGA = struct {
    header: TGAHeader = .{},
    extension: ?TGAExtension = null,

    pub const EncoderOptions = struct {
        rle_compressed: bool = true,
        top_to_bottom_image: bool = false,
        color_map_depth: u8 = 24,
    };

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() Image.Format {
        return Image.Format.tga;
    }

    pub fn formatDetect(stream: *Image.Stream) Image.ReadError!bool {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);

        const end_pos = try buffered_stream.getEndPos();

        const is_valid_tga_v2: bool = blk: {
            if (@sizeOf(TGAFooter) < end_pos) {
                const footer_position = end_pos - @sizeOf(TGAFooter);

                try buffered_stream.seekTo(footer_position);
                const footer = try utils.readStructLittle(buffered_stream.reader(), TGAFooter);

                if (footer.dot != '.') {
                    break :blk false;
                }

                if (footer.null_value != 0) {
                    break :blk false;
                }

                if (std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
                    break :blk true;
                }
            }

            break :blk false;
        };

        // Not a TGA 2.0 file, try to detect an TGA 1.0 image
        const is_valid_tga_v1: bool = blk: {
            if (!is_valid_tga_v2 and @sizeOf(TGAHeader) < end_pos) {
                try buffered_stream.seekTo(0);

                const header = try utils.readStructLittle(buffered_stream.reader(), TGAHeader);
                break :blk header.isValid();
            }

            break :blk false;
        };

        return is_valid_tga_v2 or is_valid_tga_v1;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *Image.Stream) Image.ReadError!Image {
        var result = Image.init(allocator);
        errdefer result.deinit();
        var tga = TGA{};

        const pixels = try tga.read(allocator, stream);

        result.width = tga.width();
        result.height = tga.height();
        result.pixels = pixels;

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        _ = allocator;

        const tga_encoder_options = encoder_options.tga;

        const image_width = image.width;
        const image_height = image.height;

        if (image_width > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        if (image_height > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        if (!(tga_encoder_options.color_map_depth == 16 or tga_encoder_options.color_map_depth == 24)) {
            return Image.WriteError.Unsupported;
        }

        var tga = TGA{};
        tga.header.image_spec.width = @truncate(image_width);
        tga.header.image_spec.height = @truncate(image_height);
        tga.extension = TGAExtension{};

        if (tga_encoder_options.rle_compressed) {
            tga.header.image_type.run_length = true;
        }
        if (tga_encoder_options.top_to_bottom_image) {
            tga.header.image_spec.descriptor.top_to_bottom = true;
        }

        switch (image.pixels) {
            .grayscale8 => {
                tga.header.image_type.indexed = true;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 8;
            },
            .indexed8 => {
                tga.header.image_type.indexed = true;

                tga.header.image_spec.bit_per_pixel = 8;

                tga.header.color_map_spec.bit_depth = tga_encoder_options.color_map_depth;

                tga.header.has_color_map = 1;
            },
            .rgb555 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;
                tga.header.image_spec.bit_per_pixel = 16;
            },
            .rgb24 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 24;
            },
            .rgba32 => {
                tga.header.image_type.indexed = false;
                tga.header.image_type.truecolor = true;

                tga.header.image_spec.bit_per_pixel = 32;

                tga.header.image_spec.descriptor.num_attributes_bit = 8;

                tga.extension.?.attributes = .useful_alpha_channel;
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        try tga.write(write_stream, image.pixels);
    }

    pub fn width(self: TGA) usize {
        return self.header.image_spec.width;
    }

    pub fn height(self: TGA) usize {
        return self.header.image_spec.height;
    }

    pub fn pixelFormat(self: TGA) Image.ReadError!PixelFormat {
        if (self.header.image_type.indexed) {
            if (self.header.image_type.truecolor) {
                return PixelFormat.grayscale8;
            }

            return PixelFormat.indexed8;
        } else if (self.header.image_type.truecolor) {
            switch (self.header.image_spec.bit_per_pixel) {
                16 => return PixelFormat.rgb555,
                24 => return PixelFormat.rgb24,
                32 => return PixelFormat.rgba32,
                else => {},
            }
        }

        return Image.Error.Unsupported;
    }

    pub fn read(self: *TGA, allocator: std.mem.Allocator, stream: *Image.Stream) !color.PixelStorage {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);

        // Read footage
        const end_pos = try buffered_stream.getEndPos();

        if (@sizeOf(TGAFooter) > end_pos) {
            return Image.ReadError.InvalidData;
        }

        const reader = buffered_stream.reader();
        try buffered_stream.seekTo(end_pos - @sizeOf(TGAFooter));
        const footer = try utils.readStructLittle(reader, TGAFooter);

        var is_tga_version2 = true;

        if (!std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
            is_tga_version2 = false;
        }

        // Read extension
        if (is_tga_version2 and footer.extension_offset > 0) {
            const extension_pos: u64 = @intCast(footer.extension_offset);
            try buffered_stream.seekTo(extension_pos);
            self.extension = try utils.readStructLittle(reader, TGAExtension);
        }

        // Read header
        try buffered_stream.seekTo(0);
        self.header = try utils.readStructLittle(reader, TGAHeader);

        if (!self.header.isValid()) {
            return Image.ReadError.InvalidData;
        }

        // Read ID
        if (self.header.id_length > 0) {
            var id_buffer: [256]u8 = undefined;
            @memset(id_buffer[0..], 0);

            const read_id_size = try buffered_stream.read(id_buffer[0..self.header.id_length]);

            if (read_id_size != self.header.id_length) {
                return Image.ReadError.InvalidData;
            }
        }

        const pixel_format = try self.pixelFormat();

        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.width() * self.height());
        errdefer pixels.deinit(allocator);

        const is_compressed = self.header.image_type.run_length;

        var targa_stream: TargaStream = TargaStream{ .image = reader };
        var rle_decoder: ?TargaRLEDecoder = null;

        defer {
            if (rle_decoder) |rle| {
                rle.deinit();
            }
        }

        if (is_compressed) {
            const bytes_per_pixel = (self.header.image_spec.bit_per_pixel + 7) / 8;

            rle_decoder = try TargaRLEDecoder.init(allocator, reader, bytes_per_pixel);
            if (rle_decoder) |rle| {
                targa_stream = TargaStream{ .rle = rle };
            }
        }

        const top_to_bottom_image = self.header.image_spec.descriptor.top_to_bottom;

        switch (pixel_format) {
            .grayscale8 => {
                if (top_to_bottom_image) {
                    try self.readGrayscale8TopToBottom(pixels.grayscale8, targa_stream.reader());
                } else {
                    try self.readGrayscale8BottomToTop(pixels.grayscale8, targa_stream.reader());
                }
            },
            .indexed8 => {
                // Read color map, it is not compressed by RLE so always use the original reader
                switch (self.header.color_map_spec.bit_depth) {
                    15, 16 => {
                        try self.readColorMap16(pixels.indexed8, reader);
                    },
                    24 => {
                        try self.readColorMap24(pixels.indexed8, reader);
                    },
                    else => {
                        return Image.Error.Unsupported;
                    },
                }

                // Read indices
                if (top_to_bottom_image) {
                    try self.readIndexed8TopToBottom(pixels.indexed8, targa_stream.reader());
                } else {
                    try self.readIndexed8BottomToTop(pixels.indexed8, targa_stream.reader());
                }
            },
            .rgb555 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor16TopToBottom(pixels.rgb555, targa_stream.reader());
                } else {
                    try self.readTruecolor16BottomToTop(pixels.rgb555, targa_stream.reader());
                }
            },
            .rgb24 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor24TopToBottom(pixels.rgb24, targa_stream.reader());
                } else {
                    try self.readTruecolor24BottomTopTop(pixels.rgb24, targa_stream.reader());
                }
            },
            .rgba32 => {
                if (top_to_bottom_image) {
                    try self.readTruecolor32TopToBottom(pixels.rgba32, targa_stream.reader());
                } else {
                    try self.readTruecolor32BottomToTop(pixels.rgba32, targa_stream.reader());
                }
            },
            else => {
                return Image.Error.Unsupported;
            },
        }

        return pixels;
    }

    fn readGrayscale8TopToBottom(self: *TGA, data: []color.Grayscale8, stream: TargaStream.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index] = color.Grayscale8{ .value = try stream.readByte() };
        }
    }

    fn readGrayscale8BottomToTop(self: *TGA, data: []color.Grayscale8, stream: TargaStream.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data[data_index] = color.Grayscale8{ .value = try stream.readByte() };
            }
        }
    }

    fn readIndexed8TopToBottom(self: *TGA, data: color.IndexedStorage8, stream: TargaStream.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data.indices[data_index] = try stream.readByte();
        }
    }

    fn readIndexed8BottomToTop(self: *TGA, data: color.IndexedStorage8, stream: TargaStream.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data.indices[data_index] = try stream.readByte();
            }
        }
    }

    fn readColorMap16(self: *TGA, data: color.IndexedStorage8, stream: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) Image.ReadError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            const raw_color = try stream.readInt(u16, .little);

            data.palette[data_index].r = color.scaleToIntColor(u8, (@as(u5, @truncate(raw_color >> (5 * 2)))));
            data.palette[data_index].g = color.scaleToIntColor(u8, (@as(u5, @truncate(raw_color >> 5))));
            data.palette[data_index].b = color.scaleToIntColor(u8, (@as(u5, @truncate(raw_color))));
            data.palette[data_index].a = 255;
        }
    }

    fn readColorMap24(self: *TGA, data: color.IndexedStorage8, stream: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) Image.ReadError!void {
        var data_index: usize = self.header.color_map_spec.first_entry_index;
        const data_end: usize = self.header.color_map_spec.first_entry_index + self.header.color_map_spec.length;

        while (data_index < data_end) : (data_index += 1) {
            data.palette[data_index].b = try stream.readByte();
            data.palette[data_index].g = try stream.readByte();
            data.palette[data_index].r = try stream.readByte();
            data.palette[data_index].a = 255;
        }
    }

    fn readTruecolor16TopToBottom(self: *TGA, data: []color.Rgb555, stream: TargaStream.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            const raw_color = try stream.readInt(u16, .little);

            data[data_index].r = @truncate(raw_color >> (5 * 2));
            data[data_index].g = @truncate(raw_color >> 5);
            data[data_index].b = @truncate(raw_color);
        }
    }

    fn readTruecolor16BottomToTop(self: *TGA, data: []color.Rgb555, stream: TargaStream.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;

                const raw_color = try stream.readInt(u16, .little);

                data[data_index].r = @truncate(raw_color >> (5 * 2));
                data[data_index].g = @truncate(raw_color >> 5);
                data[data_index].b = @truncate(raw_color);
            }
        }
    }

    fn readTruecolor24TopToBottom(self: *TGA, data: []color.Rgb24, stream: TargaStream.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index].b = try stream.readByte();
            data[data_index].g = try stream.readByte();
            data[data_index].r = try stream.readByte();
        }
    }

    fn readTruecolor24BottomTopTop(self: *TGA, data: []color.Rgb24, stream: TargaStream.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;
                data[data_index].b = try stream.readByte();
                data[data_index].g = try stream.readByte();
                data[data_index].r = try stream.readByte();
            }
        }
    }

    fn readTruecolor32TopToBottom(self: *TGA, data: []color.Rgba32, stream: TargaStream.Reader) Image.ReadError!void {
        var data_index: usize = 0;
        const data_end: usize = self.width() * self.height();

        while (data_index < data_end) : (data_index += 1) {
            data[data_index].b = try stream.readByte();
            data[data_index].g = try stream.readByte();
            data[data_index].r = try stream.readByte();
            data[data_index].a = try stream.readByte();

            if (self.extension) |extended_info| {
                if (extended_info.attributes != TGAAttributeType.useful_alpha_channel) {
                    data[data_index].a = 0xFF;
                }
            }
        }
    }

    fn readTruecolor32BottomToTop(self: *TGA, data: []color.Rgba32, stream: TargaStream.Reader) Image.ReadError!void {
        for (0..self.height()) |y| {
            const inverted_y = self.height() - y - 1;

            const stride = inverted_y * self.width();

            for (0..self.width()) |x| {
                const data_index = stride + x;

                data[data_index].b = try stream.readByte();
                data[data_index].g = try stream.readByte();
                data[data_index].r = try stream.readByte();
                data[data_index].a = try stream.readByte();

                if (self.extension) |extended_info| {
                    if (extended_info.attributes != TGAAttributeType.useful_alpha_channel) {
                        data[data_index].a = 0xFF;
                    }
                }
            }
        }
    }

    pub fn write(self: TGA, stream: *Image.Stream, pixels: color.PixelStorage) Image.WriteError!void {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceWriter(stream);
        var writer = buffered_stream.writer();

        try utils.writeStructLittle(writer, self.header);

        if (self.header.image_type.run_length) {} else {
            switch (pixels) {
                .grayscale8 => |grayscale_pixels| {
                    try self.writeUncompressedGrayscale8(writer, grayscale_pixels);
                },
                else => {
                    return Image.WriteError.Unsupported;
                },
            }
        }

        var footer = TGAFooter{};
        std.mem.copy(u8, footer.signature[0..], TGASignature[0..]);
        try utils.writeStructLittle(writer, footer);

        try buffered_stream.flush();
    }

    fn writeUncompressedGrayscale8(self: TGA, writer: buffered_stream_source.DefaultBufferedStreamSourceWriter.Writer, pixels: []const color.Grayscale8) Image.WriteError!void {
        if (self.header.image_spec.descriptor.top_to_bottom) {
            _ = try writer.write(std.mem.sliceAsBytes(pixels));
        } else {
            const bytes = std.mem.sliceAsBytes(pixels);

            const effective_height = self.height();
            const effective_width = self.width();

            for (0..effective_height) |y| {
                const flipped_y = effective_height - y - 1;
                const stride = flipped_y * effective_width;

                _ = try writer.write(bytes[stride..(stride + effective_width)]);
            }
        }
    }
};
