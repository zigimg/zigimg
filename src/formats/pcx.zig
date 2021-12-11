// Adapted from https://github.com/MasterQ32/zig-gamedev-lib/blob/master/src/pcx.zig
// with permission from Felix Queißner
const Allocator = std.mem.Allocator;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageReader = image.ImageReader;
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
    horizontal_dpi: u16,
    vertical_dpi: u16,
    builtin_palette: [48]u8,
    _reserved0: u8 = 0,
    planes: u8,
    stride: u16,
    palette_information: u16,
    screen_width: u16,
    screen_height: u16,

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

    stream: ImageReader,
    current_run: ?Run,

    fn init(stream: ImageReader) RLEDecoder {
        return RLEDecoder{
            .stream = stream,
            .current_run = null,
        };
    }

    fn readByte(self: *RLEDecoder) !u8 {
        if (self.current_run) |*run| {
            var result = run.value;
            run.remaining -= 1;
            if (run.remaining == 0) {
                self.current_run = null;
            }
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

    fn finish(decoder: RLEDecoder) !void {
        if (decoder.current_run != null) {
            return error.RLEStreamIncomplete;
        }
    }
};

pub const PCX = struct {
    header: PCXHeader = undefined,
    width: usize = 0,
    height: usize = 0,

    const Self = @This();

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
            .writeForImage = @ptrCast(FormatInterface.WriteForImageFn, writeForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Pcx;
    }

    pub fn formatDetect(reader: ImageReader, seek_stream: ImageSeekStream) !bool {
        _ = seek_stream;
        var magic_number_bufffer: [2]u8 = undefined;
        _ = try reader.read(magic_number_bufffer[0..]);

        if (magic_number_bufffer[0] != 0x0A) {
            return false;
        }

        if (magic_number_bufffer[1] > 0x05) {
            return false;
        }

        return true;
    }

    pub fn readForImage(allocator: Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var pcx = PCX{};

        try pcx.read(allocator, reader, seek_stream, pixels);

        var image_info = ImageInfo{};
        image_info.width = pcx.width;
        image_info.height = pcx.height;

        return image_info;
    }

    pub fn writeForImage(allocator: Allocator, write_stream: image.ImageWriterStream, seek_stream: ImageSeekStream, pixels: color.ColorStorage, save_info: image.ImageSaveInfo) !void {
        _ = allocator;
        _ = write_stream;
        _ = seek_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn pixelFormat(self: Self) !PixelFormat {
        if (self.header.planes == 1) {
            switch (self.header.bpp) {
                1 => return PixelFormat.Bpp1,
                4 => return PixelFormat.Bpp4,
                8 => return PixelFormat.Bpp8,
                else => return errors.ImageError.UnsupportedPixelFormat,
            }
        } else if (self.header.planes == 3) {
            switch (self.header.bpp) {
                8 => return PixelFormat.Rgb24,
                else => return errors.ImageError.UnsupportedPixelFormat,
            }
        } else {
            return errors.ImageError.UnsupportedPixelFormat;
        }
    }

    pub fn read(self: *Self, allocator: Allocator, reader: ImageReader, seek_stream: ImageSeekStream, pixels_opt: *?color.ColorStorage) !void {
        self.header = try utils.readStructLittle(reader, PCXHeader);
        _ = try reader.read(PCXHeader.padding[0..]);

        if (self.header.id != 0x0A) {
            return errors.ImageError.InvalidMagicHeader;
        }

        if (self.header.version > 0x05) {
            return errors.ImageError.InvalidMagicHeader;
        }

        if (self.header.planes > 3) {
            return errors.ImageError.UnsupportedPixelFormat;
        }

        const pixel_format = try self.pixelFormat();

        self.width = @as(usize, self.header.xmax - self.header.xmin + 1);
        self.height = @as(usize, self.header.ymax - self.header.ymin + 1);

        const has_dummy_byte = (@bitCast(i16, self.header.stride) - @bitCast(isize, self.width)) == 1;
        const actual_width = if (has_dummy_byte) self.width + 1 else self.width;

        pixels_opt.* = try color.ColorStorage.init(allocator, pixel_format, self.width * self.height);

        if (pixels_opt.*) |pixels| {
            var decoder = RLEDecoder.init(reader);

            const scanline_length = (self.header.stride * self.header.planes);

            var y: usize = 0;
            while (y < self.height) : (y += 1) {
                var offset: usize = 0;
                var x: usize = 0;

                const y_stride = y * self.width;

                // read all pixels from the current row
                while (offset < scanline_length and x < self.width) : (offset += 1) {
                    const byte = try decoder.readByte();
                    switch (pixels) {
                        .Bpp1 => |storage| {
                            var i: usize = 0;
                            while (i < 8) : (i += 1) {
                                if (x < self.width) {
                                    storage.indices[y_stride + x] = @intCast(u1, (byte >> (7 - @intCast(u3, i))) & 0x01);
                                    x += 1;
                                }
                            }
                        },
                        .Bpp4 => |storage| {
                            storage.indices[y_stride + x] = @truncate(u4, byte >> 4);
                            x += 1;
                            if (x < self.width) {
                                storage.indices[y_stride + x] = @truncate(u4, byte);
                                x += 1;
                            }
                        },
                        .Bpp8 => |storage| {
                            storage.indices[y_stride + x] = byte;
                            x += 1;
                        },
                        .Rgb24 => |storage| {
                            if (has_dummy_byte and byte == 0x00) {
                                continue;
                            }
                            const pixel_x = offset % (actual_width);
                            const current_color = offset / (actual_width);
                            switch (current_color) {
                                0 => {
                                    storage[y_stride + pixel_x].R = byte;
                                },
                                1 => {
                                    storage[y_stride + pixel_x].G = byte;
                                },
                                2 => {
                                    storage[y_stride + pixel_x].B = byte;
                                },
                                else => {},
                            }

                            if (pixel_x > 0 and (pixel_x % self.header.planes) == 0) {
                                x += 1;
                            }
                        },
                        else => return error.UnsupportedPixelFormat,
                    }
                }

                // discard the rest of the bytes in the current row
                while (offset < self.header.stride) : (offset += 1) {
                    _ = try decoder.readByte();
                }
            }

            try decoder.finish();

            if (pixel_format == .Bpp1 or pixel_format == .Bpp4 or pixel_format == .Bpp8) {
                var pal = switch (pixels) {
                    .Bpp1 => |*storage| storage.palette[0..],
                    .Bpp4 => |*storage| storage.palette[0..],
                    .Bpp8 => |*storage| storage.palette[0..],
                    else => undefined,
                };

                var i: usize = 0;
                while (i < std.math.min(pal.len, self.header.builtin_palette.len / 3)) : (i += 1) {
                    pal[i].R = color.toColorFloat(self.header.builtin_palette[3 * i + 0]);
                    pal[i].G = color.toColorFloat(self.header.builtin_palette[3 * i + 1]);
                    pal[i].B = color.toColorFloat(self.header.builtin_palette[3 * i + 2]);
                    pal[i].A = 1.0;
                }

                if (pixels == .Bpp8) {
                    const end_pos = try seek_stream.getEndPos();
                    try seek_stream.seekTo(end_pos - 769);

                    if ((try reader.readByte()) != 0x0C)
                        return error.MissingPalette;

                    for (pal) |*c| {
                        c.R = color.toColorFloat(try reader.readByte());
                        c.G = color.toColorFloat(try reader.readByte());
                        c.B = color.toColorFloat(try reader.readByte());
                        c.A = 1.0;
                    }
                }
            }
        }
    }
};
