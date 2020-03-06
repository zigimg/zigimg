// Adapted from https://github.com/MasterQ32/zig-gamedev-lib/blob/master/src/pcx.zig
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

pub const PCXHeader = packed struct {
    id: u8 = 0x0A,
    version: u8,
    compression: u8,
    bpp: u8,
    xmin: u16,
    ymin: u16,
    xmax: u16,
    ymax: u16,
    horizontalDPI: u16,
    verticalDPI: u16,
    builtinPalette: [48]u8,
    _reserved0: u8 = 0,
    planes: u8,
    stride: u16,
    paletteInformation: u16,
    screenWidth: u16,
    screenHeight: u16,

    // HACK: For some reason, padding as field does not report 128 bytes for the header.
    var padding: [54]u8 = undefined;

    comptime {
        std.debug.assert(@sizeOf(@This()) == 74);
    }
};

const RLEDecoder = struct {
    const Run = struct {
        value: u8,
        remaining: usize,
    };

    stream: *ImageInStream,
    currentRun: ?Run,

    fn init(stream: *ImageInStream) RLEDecoder {
        return RLEDecoder{
            .stream = stream,
            .currentRun = null,
        };
    }

    fn readByte(self: *RLEDecoder) !u8 {
        if (self.currentRun) |*run| {
            var result = run.value;
            run.remaining -= 1;
            if (run.remaining == 0)
                self.currentRun = null;
            return result;
        } else {
            while (true) {
                var byte = try self.stream.readByte();
                if (byte == 0xC0) // skip over "zero length runs"
                    continue;
                if ((byte & 0xC0) == 0xC0) {
                    const len = byte & 0x3F;
                    std.debug.assert(len > 0);
                    const result = try self.stream.readByte();
                    if (len > 1) {
                        // we only need to store a run in the decoder if it is longer than 1
                        self.currentRun = .{
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

    fn finish(decoder: RLEDecoder) !void {
        if (decoder.currentRun != null) {
            return error.RLEStreamIncomplete;
        }
    }
};

pub const PCX = struct {
    header: PCXHeader = undefined,
    width: usize = 0,
    height: usize = 0,
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
        return ImageFormat.Pcx;
    }

    pub fn formatDetect(inStream: *ImageInStream, seekStream: *ImageSeekStream) !bool {
        var magicNumberBuffer: [2]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        if (magicNumberBuffer[0] != 0x0A) {
            return false;
        }

        if (magicNumberBuffer[1] > 0x05) {
            return false;
        }

        return true;
    }

    pub fn readForImage(allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var pcx = PCX{};

        try pcx.read(allocator, inStream, seekStream, pixels);

        var imageInfo = ImageInfo{};
        imageInfo.width = pcx.width;
        imageInfo.height = pcx.height;
        imageInfo.pixel_format = pcx.pixel_format;

        return imageInfo;
    }

    pub fn read(self: *Self, allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        self.header = try utils.readStructLittle(inStream, PCXHeader);
        _ = try inStream.read(PCXHeader.padding[0..]);

        if (self.header.id != 0x0A) {
            return errors.ImageError.InvalidMagicHeader;
        }

        if (self.header.version > 0x05) {
            return errors.ImageError.InvalidMagicHeader;
        }

        if (self.header.planes > 3) {
            return errors.ImageError.UnsupportedPixelFormat;
        }

        self.pixel_format = blk: {
            if (self.header.planes == 1) {
                switch (self.header.bpp) {
                    1 => break :blk PixelFormat.Bpp1,
                    4 => break :blk PixelFormat.Bpp4,
                    8 => break :blk PixelFormat.Bpp8,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                }
            } else if (self.header.planes == 3) {
                switch (self.header.bpp) {
                    8 => break :blk PixelFormat.Rgb24,
                    else => return errors.ImageError.UnsupportedPixelFormat,
                }
            } else {
                return errors.ImageError.UnsupportedPixelFormat;
            }
        };

        self.width = @as(usize, self.header.xmax - self.header.xmin + 1);
        self.height = @as(usize, self.header.ymax - self.header.ymin + 1);

        const hasDummyByte = (@bitCast(i16, self.header.stride) - @bitCast(isize, self.width)) == 1;
        const actualWidth = if (hasDummyByte) self.width + 1 else self.width;

        pixelsOpt.* = try color.ColorStorage.init(allocator, self.pixel_format, self.width * self.height);

        if (pixelsOpt.*) |pixels| {
            var decoder = RLEDecoder.init(inStream);

            const scanlineLength = (self.header.stride * self.header.planes);

            var y: usize = 0;
            while (y < self.height) : (y += 1) {
                var offset: usize = 0;
                var x: usize = 0;

                const yStride = y * self.width;

                // read all pixels from the current row
                while (offset < scanlineLength and x < self.width) : (offset += 1) {
                    const byte = try decoder.readByte();
                    switch (pixels) {
                        .Bpp1 => |storage| {
                            var i: usize = 0;
                            while (i < 8) : (i += 1) {
                                if (x < self.width) {
                                    storage.indices[yStride + x] = @intCast(u1, (byte >> (7 - @intCast(u3, i))) & 0x01);
                                    x += 1;
                                }
                            }
                        },
                        .Bpp4 => |storage| {
                            storage.indices[yStride + x] = @truncate(u4, byte >> 4);
                            x += 1;
                            if (x < self.width) {
                                storage.indices[yStride + x] = @truncate(u4, byte);
                                x += 1;
                            }
                        },
                        .Bpp8 => |storage| {
                            storage.indices[yStride + x] = byte;
                            x += 1;
                        },
                        .Rgb24 => |storage| {
                            if (hasDummyByte and byte == 0x00) {
                                continue;
                            }
                            const pixelX = offset % (actualWidth);
                            const currentColor = offset / (actualWidth);
                            switch (currentColor) {
                                0 => {
                                    storage[yStride + pixelX].R = byte;
                                },
                                1 => {
                                    storage[yStride + pixelX].G = byte;
                                },
                                2 => {
                                    storage[yStride + pixelX].B = byte;
                                },
                                else => {},
                            }

                            if (pixelX > 0 and (pixelX % self.header.planes) == 0) {
                                x += 1;
                            }
                        },
                        else => std.debug.panic("{} pixel format not supported yet!", .{@tagName(pixels)}),
                    }
                }

                // discard the rest of the bytes in the current row
                while (offset < self.header.stride) : (offset += 1) {
                    _ = try decoder.readByte();
                }
            }

            try decoder.finish();

            if (self.pixel_format == .Bpp1 or self.pixel_format == .Bpp4 or self.pixel_format == .Bpp8) {
                var pal = switch (pixels) {
                    .Bpp1 => |*storage| storage.palette[0..],
                    .Bpp4 => |*storage| storage.palette[0..],
                    .Bpp8 => |*storage| storage.palette[0..],
                    else => undefined,
                };

                var i: usize = 0;
                while (i < std.math.min(pal.len, self.header.builtinPalette.len / 3)) : (i += 1) {
                    pal[i].R = color.toColorFloat(self.header.builtinPalette[3 * i + 0]);
                    pal[i].G = color.toColorFloat(self.header.builtinPalette[3 * i + 1]);
                    pal[i].B = color.toColorFloat(self.header.builtinPalette[3 * i + 2]);
                    pal[i].A = 1.0;
                }

                if (pixels == .Bpp8) {
                    const endPos = try seekStream.getEndPos();
                    try seekStream.seekTo(endPos - 769);

                    if ((try inStream.readByte()) != 0x0C)
                        return error.MissingPalette;

                    for (pal) |*c| {
                        c.R = color.toColorFloat(try inStream.readByte());
                        c.G = color.toColorFloat(try inStream.readByte());
                        c.B = color.toColorFloat(try inStream.readByte());
                        c.A = 1.0;
                    }
                }
            }
        }
    }
};
