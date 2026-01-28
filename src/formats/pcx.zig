// Adapted from https://github.com/MasterQ32/zig-gamedev-lib/blob/master/src/pcx.zig
// with permission from Felix Queißner
const color = @import("../color.zig");
const compressions = @import("../compressions.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const std = @import("std");

const MAGIC_HEADER: u8 = 0x0A;
const VERSION: u8 = 5;
const VGA_PALETTE_IDENTIFIER: u8 = 0x0C;

pub const Compression = enum(u8) {
    none,
    rle,
};

pub const PaletteInfo = enum(u16) {
    color = 1,
    grayscale = 2,
    _,
};

pub const PCXHeader = extern struct {
    id: u8 = MAGIC_HEADER,
    version: u8 = VERSION,
    compression: Compression = .rle,
    bpp: u8 = 0,
    xmin: u16 align(1) = 0,
    ymin: u16 align(1) = 0,
    xmax: u16 align(1) = 0,
    ymax: u16 align(1) = 0,
    horizontal_dpi: u16 align(1) = 320, // Default values found in the PCX image in the test suite
    vertical_dpi: u16 align(1) = 200, // Default values found in the PCX image in the test suite
    builtin_palette: [16]color.Rgb24 = @splat(.{ .r = 0, .g = 0, .b = 0 }),
    _reserved0: u8 = 0,
    planes: u8 = 0,
    stride: u16 align(1) = 0,
    palette_information: PaletteInfo align(1) = .color,
    screen_width: u16 align(1) = 0,
    screen_height: u16 align(1) = 0,
    padding: [54]u8 = @splat(0),

    comptime {
        std.debug.assert(@sizeOf(PCXHeader) == 128);
    }
};

const RLE_PAIR_MASK = 0xC0;
const RLE_LENGTH_MASK = 0xFF - RLE_PAIR_MASK;

const RLEDecoder = struct {
    const Run = struct {
        value: u8,
        remaining: usize,
    };

    reader: *std.Io.Reader,
    current_run: ?Run,

    fn init(reader: *std.Io.Reader) RLEDecoder {
        return RLEDecoder{
            .reader = reader,
            .current_run = null,
        };
    }

    fn readByte(self: *RLEDecoder) Image.ReadError!u8 {
        if (self.current_run) |*run| {
            const result = run.value;
            run.remaining -= 1;
            if (run.remaining == 0) {
                self.current_run = null;
            }
            return result;
        } else {
            while (true) {
                const byte = try self.reader.takeByte();
                if (byte == RLE_PAIR_MASK) { // skip over "zero length runs"
                    std.debug.print("Should not have a byte marked 0xC0\n", .{});
                    continue;
                }
                if ((byte & RLE_PAIR_MASK) == RLE_PAIR_MASK) {
                    const len = byte & RLE_LENGTH_MASK;
                    std.debug.assert(len > 0);
                    const result = try self.reader.takeByte();
                    if (len > 1) {
                        // we only need to store a run in the decoder if it is longer than 1
                        self.current_run = .{
                            .value = result,
                            .remaining = len - 1,
                        };
                    }
                    return result;
                } else {
                    return byte;
                }
            }
        }
    }

    fn finish(decoder: RLEDecoder) Image.ReadError!void {
        if (decoder.current_run != null) {
            std.debug.print("Current run: {}\n", .{decoder.current_run.?});

            return Image.ReadError.InvalidData;
        }
    }
};

const RLEPair = packed struct(u8) {
    length: u6 = 0,
    identifier: u2 = (1 << 2) - 1,
};

const RLE_MIN_LENGTH = 2;
const RLE_MAX_LENGTH = (1 << 6) - 1;

const PcxRlePacketFormatter = struct {
    pub fn flushRLE(comptime IntType: type, writer: *std.Io.Writer, value: IntType, count: usize) !void {
        const rle_packet_header = RLEPair{
            .length = @truncate(count),
        };
        try writer.writeByte(@bitCast(rle_packet_header));
        try writer.writeInt(IntType, value, .little);
    }

    pub fn flushRaw(comptime IntType: type, writer: *std.Io.Writer, slice: []const IntType) !void {
        for (slice) |entry| {
            // Byte greater than 192 needs to be encoded as a pair
            if ((entry & RLE_PAIR_MASK) == RLE_PAIR_MASK) {
                try flushRLE(IntType, writer, entry, 1);
            } else {
                try writer.writeInt(IntType, entry, .little);
            }
        }
    }
};

const RleSimdEncoder = compressions.rle.Compressor(.{
    .IntType = u8,
    .PacketFormatterType = PcxRlePacketFormatter,
    .maximum_length = RLE_MAX_LENGTH,
}).Simd;

test "PCX RLE Fast encoder" {
    const uncompressed_data = [_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 64, 64, 2, 2, 2, 2, 2, 215, 215, 215, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 200, 200, 200, 200, 210, 210 };
    const compressed_data = [_]u8{ 0xC9, 0x01, 0xC2, 0x40, 0xC5, 0x02, 0xC3, 0xD7, 0xCA, 0x03, 0xC4, 0xC8, 0xC2, 0xD2 };

    var writer_alloc = std.io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    try RleSimdEncoder.encode(uncompressed_data[0..], &writer_alloc.writer);

    try std.testing.expectEqualSlices(u8, compressed_data[0..], writer_alloc.written());
}

test "PCX RLE Fast encoder should encore more than 63 bytes similar" {
    const first_uncompressed_part: [65]u8 = @splat(0x45);
    const second_uncompresse_part = [_]u8{ 0x1, 0x1, 0x1, 0x1 };
    const uncompressed_data = first_uncompressed_part ++ second_uncompresse_part;

    const compressed_data = [_]u8{ 0xFF, 0x45, 0xC2, 0x45, 0xC4, 0x1 };

    var writer_alloc = std.io.Writer.Allocating.init(std.testing.allocator);
    defer writer_alloc.deinit();

    try RleSimdEncoder.encode(uncompressed_data[0..], &writer_alloc.writer);

    try std.testing.expectEqualSlices(u8, compressed_data[0..], writer_alloc.written());
}

const RleStreamEncoder = compressions.rle.Compressor(.{
    .IntType = u8,
    .PacketFormatterType = PcxRlePacketFormatter,
    .maximum_length = RLE_MAX_LENGTH,
}).StreamEncoder;

pub const PCX = struct {
    header: PCXHeader = .{},

    pub const EncoderOptions = struct {};

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        const reader = read_stream.reader();
        const magic_header = try reader.peek(2);

        if (magic_header[0] != MAGIC_HEADER) {
            return false;
        }

        if (magic_header[1] > VERSION) {
            return false;
        }

        return true;
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result = Image{};
        errdefer result.deinit(allocator);

        var pcx = PCX{};

        const pixels = try pcx.read(allocator, read_stream);

        result.width = pcx.width();
        result.height = pcx.height();
        result.pixels = pixels;

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        _ = allocator;
        _ = encoder_options;

        var pcx = PCX{};

        if (image.width > std.math.maxInt(u16) or image.height > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        pcx.header.xmax = @truncate(image.width - 1);
        pcx.header.ymax = @truncate(image.height - 1);

        // Fill header info based on image
        switch (image.pixels) {
            .indexed1 => |pixels| {
                pcx.header.bpp = 1;
                pcx.header.planes = 1;

                pcx.fillPalette(pixels.palette);
            },
            .indexed4 => |pixels| {
                pcx.header.bpp = 4;
                pcx.header.planes = 1;

                pcx.fillPalette(pixels.palette);
            },
            .indexed8 => {
                pcx.header.bpp = 8;
                pcx.header.planes = 1;
            },
            .rgb24 => {
                pcx.header.bpp = 8;
                pcx.header.planes = 3;
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        pcx.header.stride = @as(u16, @intFromFloat((@as(f32, @floatFromInt(image.width)) / 8.0) * @as(f32, @floatFromInt(pcx.header.bpp))));
        // Add one if the result is a odd number
        pcx.header.stride += (pcx.header.stride & 0x1);

        try pcx.write(write_stream, image.pixels);
    }

    pub fn pixelFormat(self: PCX) Image.ReadError!PixelFormat {
        if (self.header.planes == 1) {
            switch (self.header.bpp) {
                1 => return PixelFormat.indexed1,
                4 => return PixelFormat.indexed4,
                8 => return PixelFormat.indexed8,
                else => return Image.Error.Unsupported,
            }
        } else if (self.header.planes == 3) {
            switch (self.header.bpp) {
                8 => return PixelFormat.rgb24,
                else => return Image.Error.Unsupported,
            }
        } else {
            return Image.Error.Unsupported;
        }
    }

    pub fn width(self: PCX) usize {
        return self.header.xmax - self.header.xmin + 1;
    }

    pub fn height(self: PCX) usize {
        return self.header.ymax - self.header.ymin + 1;
    }

    pub fn read(self: *PCX, allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!color.PixelStorage {
        const reader = read_stream.reader();
        self.header = try reader.takeStruct(PCXHeader, .little);

        if (self.header.id != 0x0A) {
            return Image.ReadError.InvalidData;
        }

        if (self.header.version > 0x05) {
            return Image.ReadError.InvalidData;
        }

        if (self.header.planes > 3) {
            return Image.Error.Unsupported;
        }

        const pixel_format = try self.pixelFormat();

        const image_width = self.width();
        const image_height = self.height();

        const has_dummy_byte = (@as(i16, @bitCast(self.header.stride)) - @as(isize, @bitCast(image_width))) == 1;
        const actual_width = if (has_dummy_byte) image_width + 1 else image_width;

        var pixels = try color.PixelStorage.init(allocator, pixel_format, image_width * image_height);
        errdefer pixels.deinit(allocator);

        var decoder = RLEDecoder.init(reader);

        const scanline_length = (self.header.stride * self.header.planes);

        var y: usize = 0;
        while (y < image_height) : (y += 1) {
            var offset: usize = 0;
            var x: usize = 0;

            const y_stride = y * image_width;

            // read all pixels from the current row
            while (offset < scanline_length and x < image_width) : (offset += 1) {
                const byte = try decoder.readByte();
                switch (pixels) {
                    .indexed1 => |storage| {
                        var i: usize = 0;
                        while (i < 8) : (i += 1) {
                            if (x < image_width) {
                                storage.indices[y_stride + x] = @intCast((byte >> (7 - @as(u3, @intCast(i)))) & 0x01);
                                x += 1;
                            }
                        }
                    },
                    .indexed4 => |storage| {
                        storage.indices[y_stride + x] = @truncate(byte >> 4);
                        x += 1;
                        if (x < image_width) {
                            storage.indices[y_stride + x] = @truncate(byte);
                            x += 1;
                        }
                    },
                    .indexed8 => |storage| {
                        storage.indices[y_stride + x] = byte;
                        x += 1;
                    },
                    .rgb24 => |storage| {
                        if (has_dummy_byte and byte == 0x00) {
                            continue;
                        }
                        const pixel_x = offset % (actual_width);
                        const current_color = offset / (actual_width);
                        switch (current_color) {
                            0 => {
                                storage[y_stride + pixel_x].r = byte;
                            },
                            1 => {
                                storage[y_stride + pixel_x].g = byte;
                            },
                            2 => {
                                storage[y_stride + pixel_x].b = byte;
                            },
                            else => {},
                        }

                        if (pixel_x > 0 and (pixel_x % self.header.planes) == 0) {
                            x += 1;
                        }
                    },
                    else => return Image.Error.Unsupported,
                }
            }

            // discard the rest of the bytes in the current row
            while (offset < self.header.stride) : (offset += 1) {
                _ = try decoder.readByte();
            }
        }

        try decoder.finish();

        if (pixel_format == .indexed1 or pixel_format == .indexed4 or pixel_format == .indexed8) {
            var palette = switch (pixels) {
                .indexed1 => |*storage| storage.palette[0..],
                .indexed4 => |*storage| storage.palette[0..],
                .indexed8 => |*storage| storage.palette[0..],
                else => undefined,
            };

            const effective_len = @min(palette.len, self.header.builtin_palette.len);
            for (0..effective_len) |index| {
                palette[index].r = self.header.builtin_palette[index].r;
                palette[index].g = self.header.builtin_palette[index].g;
                palette[index].b = self.header.builtin_palette[index].b;
                palette[index].a = 255;
            }

            if (pixels == .indexed8) {
                const end_pos = try read_stream.getEndPos();
                try read_stream.seekTo(end_pos - 769);

                if ((try reader.takeByte()) != VGA_PALETTE_IDENTIFIER) {
                    return Image.ReadError.InvalidData;
                }

                for (palette) |*current_entry| {
                    current_entry.r = try reader.takeByte();
                    current_entry.g = try reader.takeByte();
                    current_entry.b = try reader.takeByte();
                    current_entry.a = 255;
                }
            }
        }

        return pixels;
    }

    pub fn write(self: PCX, write_stream: *io.WriteStream, pixels: color.PixelStorage) Image.WriteError!void {
        switch (pixels) {
            .indexed1,
            .indexed4,
            .indexed8,
            .rgb24,
            => {
                // Do nothing
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        const writer = write_stream.writer();

        try writer.writeStruct(self.header, .little);

        const actual_width = self.width();
        const is_even = ((actual_width & 0x1) == 0);

        switch (pixels) {
            .indexed1 => |indexed| {
                try self.writeIndexed1(writer, indexed);
            },
            .indexed4 => |indexed| {
                try self.writeIndexed4(writer, indexed);
            },
            .indexed8 => |indexed| {
                if (is_even) {
                    try writeIndexed8Even(writer, indexed);
                } else {
                    try self.writeIndexed8Odd(writer, indexed);
                }

                // Write VGA palette
                try writer.writeByte(VGA_PALETTE_IDENTIFIER);
                for (pixels.indexed8.palette) |current_entry| {
                    const rgb24_color = color.Rgb24.from.u32Rgba(current_entry.to.u32Rgba());
                    try writer.writeStruct(rgb24_color, .little);
                }
            },
            .rgb24 => |data| {
                try self.writeRgb24(writer, data);
            },
            else => {
                return Image.WriteError.Unsupported;
            },
        }

        try write_stream.flush();
    }

    fn fillPalette(self: *PCX, palette: []const color.Rgba32) void {
        const effective_len = @min(palette.len, self.header.builtin_palette.len);
        for (0..effective_len) |index| {
            self.header.builtin_palette[index].r = palette[index].r;
            self.header.builtin_palette[index].g = palette[index].g;
            self.header.builtin_palette[index].b = palette[index].b;
        }
    }

    fn writeIndexed1(self: *const PCX, writer: *std.Io.Writer, indexed: color.IndexedStorage1) Image.WriteError!void {
        var rle_encoder = RleStreamEncoder{};

        const image_width = self.width();
        const image_height = self.height();

        const is_even = ((image_width & 0x1) == 0);

        for (0..image_height) |y| {
            const stride = y * image_width;

            var current_byte: u8 = 0;

            for (0..image_width) |x| {
                const pixel = indexed.indices[stride + x];

                const bit = @as(u3, @intCast(7 - (x % 8)));

                current_byte |= @as(u8, pixel) << bit;
                if (bit == 0) {
                    try rle_encoder.encode(writer, current_byte);
                    current_byte = 0;
                }
            }

            if (!is_even) {
                try rle_encoder.encode(writer, current_byte);
            }
        }

        try rle_encoder.flush(writer);
    }

    fn writeIndexed4(self: *const PCX, writer: *std.Io.Writer, indexed: color.IndexedStorage4) Image.WriteError!void {
        var rle_encoder = RleStreamEncoder{};

        const image_width = self.width();
        const image_height = self.height();

        const is_even = ((image_width & 0x1) == 0);

        var current_byte: u8 = 0;

        for (0..image_height) |y| {
            const stride = y * image_width;

            for (0..image_width) |x| {
                const pixel = indexed.indices[stride + x];

                if ((x & 0x1) == 0x1) {
                    current_byte |= pixel;
                    try rle_encoder.encode(writer, current_byte);
                } else {
                    current_byte = @as(u8, pixel) << 4;
                }
            }

            if (!is_even) {
                try rle_encoder.encode(writer, current_byte);
            }
        }

        try rle_encoder.flush(writer);
    }

    fn writeIndexed8Even(writer: *std.Io.Writer, indexed: color.IndexedStorage8) Image.WriteError!void {
        try RleSimdEncoder.encode(indexed.indices, writer);
    }

    fn writeIndexed8Odd(self: *const PCX, writer: *std.Io.Writer, indexed: color.IndexedStorage8) Image.WriteError!void {
        var rle_encoder = RleStreamEncoder{};

        const image_width = self.width();
        const image_height = self.height();

        for (0..image_height) |y| {
            const y_stride = y * image_width;

            const pixel_stride = indexed.indices[y_stride..(y_stride + image_width)];
            try rle_encoder.encodeSlice(writer, pixel_stride);
            try rle_encoder.encode(writer, 0x00);
        }

        try rle_encoder.flush(writer);
    }

    fn writeRgb24(self: *const PCX, writer: *std.Io.Writer, pixels: []const color.Rgb24) Image.WriteError!void {
        var rle_encoder = RleStreamEncoder{};

        const image_width = self.width();
        const image_height = self.height();

        const is_even = ((image_width & 0x1) == 0);

        for (0..image_height) |y| {
            const stride = y * image_width;

            for (0..3) |plane| {
                for (0..image_width) |x| {
                    const current_color = pixels[stride + x];
                    switch (plane) {
                        0 => try rle_encoder.encode(writer, current_color.r),
                        1 => try rle_encoder.encode(writer, current_color.g),
                        2 => try rle_encoder.encode(writer, current_color.b),
                        else => {},
                    }
                }

                if (!is_even) {
                    try rle_encoder.encode(writer, 0x00);
                }
            }
        }

        try rle_encoder.flush(writer);
    }
};
