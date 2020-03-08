// Adapted from https://github.com/MasterQ32/zig-gamedev-lib/blob/master/src/netbpm.zig
// with permission from Felix Queißner
const Allocator = std.mem.Allocator;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageInStream = image.ImageInStream;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const image = @import("../image.zig");
const std = @import("std");
const utils = @import("../utils.zig");

// this file implements the Portable Anymap specification provided by
// http://netpbm.sourceforge.net/doc/pbm.html // P1, P4 => Bitmap
// http://netpbm.sourceforge.net/doc/pgm.html // P2, P5 => Graymap
// http://netpbm.sourceforge.net/doc/ppm.html // P3, P6 => Pixmap

/// one of the three types a netbpm graphic could be stored in.
pub const Format = enum {
    /// the image contains black-and-white pixels.
    Bitmap,

    /// the image contains grayscale pixels.
    Grayscale,

    /// the image contains RGB pixels.
    Rgb,
};

pub const Header = struct {
    format: Format,
    binary: bool,
    width: usize,
    height: usize,
    max_value: usize,
};

fn parseHeader(stream: ImageInStream) !Header {
    var hdr: Header = undefined;

    var magic: [2]u8 = undefined;
    _ = try stream.read(magic[0..]);

    if (std.mem.eql(u8, &magic, "P1")) {
        hdr.binary = false;
        hdr.format = .Bitmap;
        hdr.max_value = 1;
    } else if (std.mem.eql(u8, &magic, "P2")) {
        hdr.binary = false;
        hdr.format = .Grayscale;
    } else if (std.mem.eql(u8, &magic, "P3")) {
        hdr.binary = false;
        hdr.format = .Rgb;
    } else if (std.mem.eql(u8, &magic, "P4")) {
        hdr.binary = true;
        hdr.format = .Bitmap;
        hdr.max_value = 1;
    } else if (std.mem.eql(u8, &magic, "P5")) {
        hdr.binary = true;
        hdr.format = .Grayscale;
    } else if (std.mem.eql(u8, &magic, "P6")) {
        hdr.binary = true;
        hdr.format = .Rgb;
    } else {
        return errors.ImageError.InvalidMagicHeader;
    }

    var readBuffer: [16]u8 = undefined;

    hdr.width = try parseNumber(stream, readBuffer[0..]);
    hdr.height = try parseNumber(stream, readBuffer[0..]);
    if (hdr.format != .Bitmap) {
        hdr.max_value = try parseNumber(stream, readBuffer[0..]);
    }

    return hdr;
}

fn isWhitespace(b: u8) bool {
    return switch (b) {
        // Whitespace (blanks, TABs, CRs, LFs).
        '\n', '\r', ' ', '\t' => true,
        else => false,
    };
}

fn readNextByte(stream: ImageInStream) !u8 {
    while (true) {
        var b = try stream.readByte();
        switch (b) {
            // Before the whitespace character that delimits the raster, any characters
            // from a "#" through the next carriage return or newline character, is a
            // comment and is ignored. Note that this is rather unconventional, because
            // a comment can actually be in the middle of what you might consider a token.
            // Note also that this means if you have a comment right before the raster,
            // the newline at the end of the comment is not sufficient to delimit the raster.
            '#' => {
                // eat up comment
                while (true) {
                    var c = try stream.readByte();
                    switch (c) {
                        '\r', '\n' => break,
                        else => {},
                    }
                }
            },
            else => return b,
        }
    }
}

/// skips whitespace and comments, then reads a number from the stream.
/// this function reads one whitespace behind the number as a terminator.
fn parseNumber(stream: ImageInStream, buffer: []u8) !usize {
    var inputLength: usize = 0;
    while (true) {
        var b = try readNextByte(stream);
        if (isWhitespace(b)) {
            if (inputLength > 0) {
                return try std.fmt.parseInt(usize, buffer[0..inputLength], 10);
            } else {
                continue;
            }
        } else {
            if (inputLength >= buffer.len)
                return error.OutOfMemory;
            buffer[inputLength] = b;
            inputLength += 1;
        }
    }
}

fn loadBinaryBitmap(header: Header, data: []color.Grayscale1, stream: ImageInStream) !void {
    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;

    while (dataIndex < dataEnd) : (dataIndex += 1) {
        var b = try stream.readByte();

        var i: usize = 0;
        while (dataIndex < dataEnd and i < 8) {
            const pixel = if ((b & (@as(u8, 1) << @truncate(u3, 7 - i))) != 0) @as(u1, 0) else @as(u1, 1);

            // set bit is black, cleared bit is white
            // bits are "left to right" (so msb to lsb)
            data[dataIndex] = color.Grayscale1{ .value = pixel };
            dataIndex += 1;
            i += 1;
        }
    }
}

fn loadAsciiBitmap(header: Header, data: []color.Grayscale1, stream: ImageInStream) !void {
    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;

    while (dataIndex < dataEnd) {
        var b = try stream.readByte();
        if (isWhitespace(b)) {
            continue;
        }

        // 1 is black, 0 is white in PBM spec.
        // we use 1=white, 0=black in u1 format
        const pixel = if (b == '0') @as(u1, 1) else @as(u1, 0);
        data[dataIndex] = color.Grayscale1{ .value = pixel };

        dataIndex += 1;
    }
}

fn readLinearizedValue(stream: ImageInStream, maxValue: usize) !u8 {
    return if (maxValue > 255)
        @truncate(u8, 255 * @as(usize, try stream.readIntBig(u16)) / maxValue)
    else
        @truncate(u8, 255 * @as(usize, try stream.readByte()) / maxValue);
}

fn loadBinaryGraymap(header: Header, data: []color.Grayscale8, stream: ImageInStream) !void {
    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;
    while (dataIndex < dataEnd) : (dataIndex += 1) {
        data[dataIndex] = color.Grayscale8{ .value = try readLinearizedValue(stream, header.max_value) };
    }
}

fn loadAsciiGraymap(header: Header, data: []color.Grayscale8, stream: ImageInStream) !void {
    var readBuffer: [16]u8 = undefined;

    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;

    while (dataIndex < dataEnd) : (dataIndex += 1) {
        var b = try parseNumber(stream, readBuffer[0..]);

        data[dataIndex] = color.Grayscale8{ .value = @truncate(u8, 255 * b / header.max_value) };
    }
}

fn loadBinaryRgbmap(header: Header, data: []color.Rgb24, stream: ImageInStream) !void {
    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;

    while (dataIndex < dataEnd) : (dataIndex += 1) {
        data[dataIndex] = color.Rgb24{
            .R = try readLinearizedValue(stream, header.max_value),
            .G = try readLinearizedValue(stream, header.max_value),
            .B = try readLinearizedValue(stream, header.max_value),
        };
    }
}

fn loadAsciiRgbmap(header: Header, data: []color.Rgb24, stream: ImageInStream) !void {
    var readBuffer: [16]u8 = undefined;

    var dataIndex: usize = 0;
    const dataEnd = header.width * header.height;

    while (dataIndex < dataEnd) : (dataIndex += 1) {
        var r = try parseNumber(stream, readBuffer[0..]);
        var g = try parseNumber(stream, readBuffer[0..]);
        var b = try parseNumber(stream, readBuffer[0..]);

        data[dataIndex] = color.Rgb24{
            .R = @truncate(u8, 255 * r / header.max_value),
            .G = @truncate(u8, 255 * g / header.max_value),
            .B = @truncate(u8, 255 * b / header.max_value),
        };
    }
}

fn Netpbm(comptime imageFormat: ImageFormat, comptime headerNumbers: []const u8) type {
    return struct {
        header: Header = undefined,
        pixel_format: PixelFormat = undefined,

        const Self = @This();

        pub fn formatInterface() FormatInterface {
            return FormatInterface{
                .format = @ptrCast(FormatInterface.FormatFn, format),
                .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
                .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
            };
        }

        pub fn format() ImageFormat {
            return imageFormat;
        }

        pub fn formatDetect(inStream: ImageInStream, seekStream: ImageSeekStream) !bool {
            var magicNumberBuffer: [2]u8 = undefined;
            _ = try inStream.read(magicNumberBuffer[0..]);

            if (magicNumberBuffer[0] != 'P') {
                return false;
            }

            var found = false;

            for (headerNumbers) |number| {
                if (magicNumberBuffer[1] == number) {
                    found = true;
                    break;
                }
            }

            return found;
        }

        pub fn readForImage(allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
            var netpbmFile = Self{};

            try netpbmFile.read(allocator, inStream, seekStream, pixels);

            var imageInfo = ImageInfo{};
            imageInfo.width = netpbmFile.header.width;
            imageInfo.height = netpbmFile.header.height;
            imageInfo.pixel_format = netpbmFile.pixel_format;

            return imageInfo;
        }

        pub fn read(self: *Self, allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
            self.header = try parseHeader(inStream);

            self.pixel_format = switch (self.header.format) {
                .Bitmap => PixelFormat.Grayscale1,
                .Grayscale => PixelFormat.Grayscale8,
                .Rgb => PixelFormat.Rgb24,
            };

            pixelsOpt.* = try color.ColorStorage.init(allocator, self.pixel_format, self.header.width * self.header.height);

            if (pixelsOpt.*) |pixels| {
                switch (self.header.format) {
                    .Bitmap => {
                        if (self.header.binary) {
                            try loadBinaryBitmap(self.header, pixels.Grayscale1, inStream);
                        } else {
                            try loadAsciiBitmap(self.header, pixels.Grayscale1, inStream);
                        }
                    },
                    .Grayscale => {
                        if (self.header.binary) {
                            try loadBinaryGraymap(self.header, pixels.Grayscale8, inStream);
                        } else {
                            try loadAsciiGraymap(self.header, pixels.Grayscale8, inStream);
                        }
                    },
                    .Rgb => {
                        if (self.header.binary) {
                            try loadBinaryRgbmap(self.header, pixels.Rgb24, inStream);
                        } else {
                            try loadAsciiRgbmap(self.header, pixels.Rgb24, inStream);
                        }
                    },
                }
            }
        }
    };
}

pub const PBM = Netpbm(ImageFormat.Pbm, &[_]u8{ '1', '4' });
pub const PGM = Netpbm(ImageFormat.Pgm, &[_]u8{ '2', '5' });
pub const PPM = Netpbm(ImageFormat.Ppm, &[_]u8{ '3', '6' });
