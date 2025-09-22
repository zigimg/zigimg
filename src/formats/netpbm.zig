// Adapted from https://github.com/MasterQ32/zig-gamedev-lib/blob/master/src/netbpm.zig
// with permission from Felix Queißner
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const std = @import("std");
const io = @import("../io.zig");

// this file implements the Portable Anymap specification provided by
// http://netpbm.sourceforge.net/doc/pbm.html // P1, P4 => bitmap
// http://netpbm.sourceforge.net/doc/pgm.html // P2, P5 => graymap
// http://netpbm.sourceforge.net/doc/ppm.html // P3, P6 => pixmap

/// one of the three types a netbpm graphic could be stored in.
pub const Format = enum {
    /// the image contains black-and-white pixels.
    bitmap,

    /// the image contains grayscale pixels.
    grayscale,

    /// the image contains RGB pixels.
    rgb,
};

pub const Header = struct {
    format: Format,
    binary: bool,
    width: usize,
    height: usize,
    max_value: usize,
};

fn parseHeader(reader: *std.Io.Reader) Image.ReadError!Header {
    var header: Header = undefined;

    const magic = try reader.take(2);

    if (std.mem.eql(u8, magic, "P1")) {
        header.binary = false;
        header.format = .bitmap;
        header.max_value = 1;
    } else if (std.mem.eql(u8, magic, "P2")) {
        header.binary = false;
        header.format = .grayscale;
    } else if (std.mem.eql(u8, magic, "P3")) {
        header.binary = false;
        header.format = .rgb;
    } else if (std.mem.eql(u8, magic, "P4")) {
        header.binary = true;
        header.format = .bitmap;
        header.max_value = 1;
    } else if (std.mem.eql(u8, magic, "P5")) {
        header.binary = true;
        header.format = .grayscale;
    } else if (std.mem.eql(u8, magic, "P6")) {
        header.binary = true;
        header.format = .rgb;
    } else {
        return Image.ReadError.InvalidData;
    }

    var read_buffer: [16]u8 = undefined;

    header.width = try parseNumber(reader, read_buffer[0..]);
    header.height = try parseNumber(reader, read_buffer[0..]);
    if (header.format != .bitmap) {
        header.max_value = try parseNumber(reader, read_buffer[0..]);
    }

    return header;
}

fn isWhitespace(b: u8) bool {
    return switch (b) {
        // Whitespace (blanks, TABs, CRs, LFs).
        '\n', '\r', ' ', '\t' => true,
        else => false,
    };
}

fn readNextByte(reader: *std.Io.Reader) Image.ReadError!u8 {
    while (true) {
        const read_byte = try reader.takeByte();
        switch (read_byte) {
            // Before the whitespace character that delimits the raster, any characters
            // from a "#" through the next carriage return or newline character, is a
            // comment and is ignored. Note that this is rather unconventional, because
            // a comment can actually be in the middle of what you might consider a token.
            // Note also that this means if you have a comment right before the raster,
            // the newline at the end of the comment is not sufficient to delimit the raster.
            '#' => {
                // eat up comment
                while (true) {
                    const comment_byte = try reader.takeByte();
                    switch (comment_byte) {
                        '\r', '\n' => break,
                        else => {},
                    }
                }
            },
            else => return read_byte,
        }
    }
}

/// skips whitespace and comments, then reads a number from the stream.
/// this function reads one whitespace behind the number as a terminator.
fn parseNumber(reader: *std.Io.Reader, buffer: []u8) Image.ReadError!usize {
    var input_length: usize = 0;
    while (true) {
        const b = try readNextByte(reader);
        if (isWhitespace(b)) {
            if (input_length > 0) {
                return std.fmt.parseInt(usize, buffer[0..input_length], 10) catch return Image.ReadError.InvalidData;
            } else {
                continue;
            }
        } else {
            if (input_length >= buffer.len)
                return error.OutOfMemory;
            buffer[input_length] = b;
            input_length += 1;
        }
    }
}

fn loadBinaryBitmap(header: Header, data: []color.Grayscale1, reader: *std.Io.Reader) Image.ReadError!void {
    var bit_reader: io.BitReader(.big) = .{
        .reader = reader,
    };

    for (0..header.height) |row_index| {
        for (data[row_index * header.width ..][0..header.width]) |*sample| {
            sample.value = ~(try bit_reader.readBitsNoEof(u1, 1));
        }
        bit_reader.alignToByte();
    }
}

fn loadAsciiBitmap(header: Header, data: []color.Grayscale1, reader: *std.Io.Reader) Image.ReadError!void {
    var data_index: usize = 0;
    const data_end = header.width * header.height;

    while (data_index < data_end) {
        const b = try reader.takeByte();
        if (isWhitespace(b)) {
            continue;
        }

        // 1 is black, 0 is white in PBM spec.
        // we use 1=white, 0=black in u1 format
        const pixel = if (b == '0') @as(u1, 1) else @as(u1, 0);
        data[data_index] = color.Grayscale1{ .value = pixel };

        data_index += 1;
    }
}

fn readLinearizedValue(reader: *std.Io.Reader, max_value: usize) Image.ReadError!u8 {
    return if (max_value > 255)
        @truncate(255 * @as(usize, try reader.takeInt(u16, .big)) / max_value)
    else
        @truncate(255 * @as(usize, try reader.takeByte()) / max_value);
}

fn loadBinaryGraymap(header: Header, pixels: *color.PixelStorage, reader: *std.Io.Reader) Image.ReadError!void {
    var data_index: usize = 0;
    const data_end = header.width * header.height;
    if (header.max_value <= 255) {
        while (data_index < data_end) : (data_index += 1) {
            pixels.grayscale8[data_index] = color.Grayscale8{ .value = try readLinearizedValue(reader, header.max_value) };
        }
    } else {
        while (data_index < data_end) : (data_index += 1) {
            pixels.grayscale16[data_index] = color.Grayscale16{ .value = try reader.takeInt(u16, .big) };
        }
    }
}

fn loadAsciiGraymap(header: Header, pixels: *color.PixelStorage, reader: *std.Io.Reader) Image.ReadError!void {
    var read_buffer: [16]u8 = undefined;

    var data_index: usize = 0;
    const data_end = header.width * header.height;

    if (header.max_value <= 255) {
        while (data_index < data_end) : (data_index += 1) {
            pixels.grayscale8[data_index] = color.Grayscale8{ .value = @truncate(try parseNumber(reader, read_buffer[0..])) };
        }
    } else {
        while (data_index < data_end) : (data_index += 1) {
            pixels.grayscale16[data_index] = color.Grayscale16{ .value = @truncate(try parseNumber(reader, read_buffer[0..])) };
        }
    }
}

fn loadBinaryRgbmap(header: Header, data: []color.Rgb24, reader: *std.Io.Reader) Image.ReadError!void {
    var data_index: usize = 0;
    const data_end = header.width * header.height;

    while (data_index < data_end) : (data_index += 1) {
        data[data_index] = color.Rgb24{
            .r = try readLinearizedValue(reader, header.max_value),
            .g = try readLinearizedValue(reader, header.max_value),
            .b = try readLinearizedValue(reader, header.max_value),
        };
    }
}

fn loadAsciiRgbmap(header: Header, data: []color.Rgb24, reader: *std.Io.Reader) Image.ReadError!void {
    var read_buffer: [16]u8 = undefined;

    var data_index: usize = 0;
    const data_end = header.width * header.height;

    while (data_index < data_end) : (data_index += 1) {
        const r = try parseNumber(reader, read_buffer[0..]);
        const g = try parseNumber(reader, read_buffer[0..]);
        const b = try parseNumber(reader, read_buffer[0..]);

        data[data_index] = color.Rgb24{
            .r = @truncate(255 * r / header.max_value),
            .g = @truncate(255 * g / header.max_value),
            .b = @truncate(255 * b / header.max_value),
        };
    }
}

fn Netpbm(comptime header_numbers: []const u8, comptime supported_format: Format) type {
    return struct {
        header: Header = undefined,

        const Self = @This();

        pub const EncoderOptions = struct {
            binary: bool = true,
        };

        pub fn formatInterface() FormatInterface {
            return FormatInterface{
                .formatDetect = formatDetect,
                .readImage = readImage,
                .writeImage = writeImage,
            };
        }

        pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
            const reader = read_stream.reader();

            const magic_number_buffer = try reader.peek(2);
            if (magic_number_buffer[0] != 'P') {
                return false;
            }

            var found = false;

            for (header_numbers) |number| {
                if (magic_number_buffer[1] == number) {
                    found = true;
                    break;
                }
            }

            return found;
        }

        pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
            var result = Image{};
            errdefer result.deinit(allocator);

            var netpbm_file = Self{};

            const pixels = try netpbm_file.read(allocator, read_stream);

            result.width = netpbm_file.header.width;
            result.height = netpbm_file.header.height;
            result.pixels = pixels;

            return result;
        }

        pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
            _ = allocator;

            var netpbm_file = Self{};
            netpbm_file.header.binary = switch (encoder_options) {
                .pbm => |options| options.binary,
                .pgm => |options| options.binary,
                .ppm => |options| options.binary,
                else => false,
            };

            netpbm_file.header.width = image.width;
            netpbm_file.header.height = image.height;
            netpbm_file.header.format = switch (image.pixels) {
                .grayscale1 => Format.bitmap,
                .grayscale8, .grayscale16 => Format.grayscale,
                .rgb24 => Format.rgb,
                else => return Image.Error.Unsupported,
            };

            netpbm_file.header.max_value = switch (image.pixels) {
                .grayscale16 => std.math.maxInt(u16),
                .grayscale1 => 1,
                else => std.math.maxInt(u8),
            };

            try netpbm_file.write(write_stream, image.pixels);
        }

        pub fn pixelFormat(self: Self) Image.ReadError!PixelFormat {
            return switch (self.header.format) {
                .bitmap => PixelFormat.grayscale1,
                .grayscale => switch (self.header.max_value) {
                    0...255 => PixelFormat.grayscale8,
                    else => PixelFormat.grayscale16,
                },
                .rgb => PixelFormat.rgb24,
            };
        }

        pub fn read(self: *Self, allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!color.PixelStorage {
            const reader = read_stream.reader();
            self.header = try parseHeader(reader);

            const pixel_format = try self.pixelFormat();

            var pixels = try color.PixelStorage.init(allocator, pixel_format, self.header.width * self.header.height);
            errdefer pixels.deinit(allocator);

            switch (self.header.format) {
                .bitmap => {
                    if (self.header.binary) {
                        try loadBinaryBitmap(self.header, pixels.grayscale1, reader);
                    } else {
                        try loadAsciiBitmap(self.header, pixels.grayscale1, reader);
                    }
                },
                .grayscale => {
                    if (self.header.binary) {
                        try loadBinaryGraymap(self.header, &pixels, reader);
                    } else {
                        try loadAsciiGraymap(self.header, &pixels, reader);
                    }
                },
                .rgb => {
                    if (self.header.binary) {
                        try loadBinaryRgbmap(self.header, pixels.rgb24, reader);
                    } else {
                        try loadAsciiRgbmap(self.header, pixels.rgb24, reader);
                    }
                },
            }

            return pixels;
        }

        pub fn write(self: *Self, write_stream: *io.WriteStream, pixels: color.PixelStorage) Image.WriteError!void {
            if (self.header.format != supported_format) {
                return Image.Error.Unsupported;
            }

            const image_type = if (self.header.binary) header_numbers[1] else header_numbers[0];

            const writer = write_stream.writer();

            try writer.print("P{c}\n", .{image_type});
            _ = try writer.write("# Created by zigimg\n");

            try writer.print("{} {}\n", .{ self.header.width, self.header.height });

            if (self.header.format != .bitmap) {
                try writer.print("{}\n", .{self.header.max_value});
            }

            if (self.header.binary) {
                switch (self.header.format) {
                    .bitmap => {
                        switch (pixels) {
                            .grayscale1 => |samples| {
                                var bit_writer: io.BitWriter(.big) = .{
                                    .writer = writer,
                                };

                                for (0..self.header.height) |row_index| {
                                    for (samples[row_index * self.header.width ..][0..self.header.width]) |sample| {
                                        try bit_writer.writeBits(~sample.value, 1);
                                    }
                                    try bit_writer.flushBits();
                                }
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                    .grayscale => {
                        switch (pixels) {
                            .grayscale16 => {
                                for (pixels.grayscale16) |entry| {
                                    // Big due to 16-bit PGM being semi standardized as big-endian
                                    try writer.writeInt(u16, entry.value, .big);
                                }
                            },
                            .grayscale8 => {
                                for (pixels.grayscale8) |entry| {
                                    try writer.writeInt(u8, entry.value, .little);
                                }
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                    .rgb => {
                        switch (pixels) {
                            .rgb24 => {
                                for (pixels.rgb24) |entry| {
                                    try writer.writeByte(entry.r);
                                    try writer.writeByte(entry.g);
                                    try writer.writeByte(entry.b);
                                }
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                }
            } else {
                switch (self.header.format) {
                    .bitmap => {
                        switch (pixels) {
                            .grayscale1 => {
                                for (pixels.grayscale1) |entry| {
                                    try writer.print("{}", .{~entry.value});
                                }
                                _ = try writer.write("\n");
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                    .grayscale => {
                        switch (pixels) {
                            .grayscale16 => {
                                const pixels_len = pixels.len();
                                for (pixels.grayscale16, 0..) |entry, index| {
                                    try writer.print("{}", .{entry.value});

                                    if (index != (pixels_len - 1)) {
                                        _ = try writer.write(" ");
                                    }
                                }
                                _ = try writer.write("\n");
                            },
                            .grayscale8 => {
                                const pixels_len = pixels.len();
                                for (pixels.grayscale8, 0..) |entry, index| {
                                    try writer.print("{}", .{entry.value});

                                    if (index != (pixels_len - 1)) {
                                        _ = try writer.write(" ");
                                    }
                                }
                                _ = try writer.write("\n");
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                    .rgb => {
                        switch (pixels) {
                            .rgb24 => {
                                for (pixels.rgb24) |entry| {
                                    try writer.print("{} {} {}\n", .{ entry.r, entry.g, entry.b });
                                }
                            },
                            else => {
                                return Image.Error.Unsupported;
                            },
                        }
                    },
                }
            }

            try write_stream.flush();
        }
    };
}

pub const PBM = Netpbm(&[_]u8{ '1', '4' }, .bitmap);
pub const PGM = Netpbm(&[_]u8{ '2', '5' }, .grayscale);
pub const PPM = Netpbm(&[_]u8{ '3', '6' }, .rgb);
