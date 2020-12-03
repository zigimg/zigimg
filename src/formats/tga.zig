const Allocator = std.mem.Allocator;
const File = std.fs.File;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageInStream = image.ImageInStream;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const fs = std.fs;
const image = @import("../image.zig");
const io = std.io;
const mem = std.mem;
const path = std.fs.path;
const std = @import("std");
usingnamespace @import("../utils.zig");

pub const TGAImageType = packed struct {
    indexed: bool,
    truecolor: bool,
    pad0: bool,
    run_length: bool,
    pad1: u4,
};

pub const TGAColorMapSpec = packed struct {
    first_entry_index: u16,
    color_map_length: u16,
    color_map_bit_depth: u8,
};

pub const TGAImageSpec = packed struct {
    origin_x: u16,
    origin_y: u16,
    width: u16,
    height: u16,
    bit_per_pixel: u8,
    descriptor: u8, // This field seems to not be used anymore
};

pub const TGAHeader = packed struct {
    id_length: u8,
    has_color_map: u8,
    image_type: TGAImageType,

    // BEGIN: TGAColorMapSpec
    first_entry_index: u16,
    color_map_length: u16,
    color_map_bit_depth: u8,
    // END TGAColorMapSpec
    // TODO: Use TGAColorMapSpec once all packed struct bugs are fixed
    // color_map_spec: TGAColorMapSpec,

    // BEGIN TGAImageSpec
    origin_x: u16,
    origin_y: u16,
    width: u16,
    height: u16,
    bit_per_pixel: u8,
    descriptor: u8,
    // END TGAImageSpec
    //TODO: Use TGAImageSpec once all packed struct bugs are fixed
    //image_spec: TGAImageSpec,
};

pub const TGAExtension = packed struct {
    extension_size: u16,
    author_name: [41]u8,
    author_comment: [324]u8,
    timestamp: [12]u8,
    job_id: [41]u8,
    job_time: [6]u8,
    software_id: [41]u8,
    software_version: [3]u8,
    key_color: [4]u8,
    pixel_aspect: [4]u8,
    gamma_value: [4]u8,
    color_correction_offset: u32,
    postage_stamp_offset: u32,
    scanline_offset: u32,
    attributes: u8,
};

pub const TGAFooter = packed struct {
    extension_offset: u32,
    dev_area_offset: u32,
    signature: [16]u8,
    dot: u8,
    null_value: u8,
};

pub const TGASignature = "TRUEVISION-XFILE";

comptime {
    std.debug.assert(@sizeOf(TGAExtension) == 495);
}

pub const TGA = struct {
    header: TGAHeader = undefined,
    extension: TGAExtension = undefined,

    const Self = @This();

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Tga;
    }

    pub fn formatDetect(inStream: ImageInStream, seekStream: ImageSeekStream) !bool {
        const endPos = try seekStream.getEndPos();

        if (@sizeOf(TGAFooter) < endPos) {
            const footer_position = endPos - @sizeOf(TGAFooter);

            try seekStream.seekTo(footer_position);
            const footer: TGAFooter = try readStructLittle(inStream, TGAFooter);

            if (footer.dot != '.') {
                return false;
            }

            if (footer.null_value != 0) {
                return false;
            }

            if (std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
                return true;
            }
        }

        return false;
    }

    pub fn readForImage(allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var tga = Self{};

        try tga.read(allocator, inStream, seekStream, pixels);

        var imageInfo = ImageInfo{};
        imageInfo.width = tga.width();
        imageInfo.height = tga.height();
        imageInfo.pixel_format = try tga.pixelFormat();
        return imageInfo;
    }

    pub fn width(self: Self) usize {
        return self.header.width;
    }

    pub fn height(self: Self) usize {
        return self.header.height;
    }

    pub fn pixelFormat(self: Self) !PixelFormat {
        if (self.header.image_type.indexed) {
            if (self.header.image_type.truecolor) {
                return PixelFormat.Grayscale8;
            }

            return PixelFormat.Bpp8;
        } else if (self.header.image_type.truecolor) {
            switch (self.header.bit_per_pixel) {
                16 => return PixelFormat.Rgb555,
                24 => return PixelFormat.Rgb24,
                32 => return PixelFormat.Rgba32,
                else => {},
            }
        }

        return errors.ImageError.UnsupportedPixelFormat;
    }

    pub fn read(self: *Self, allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        // Read footage
        const endPos = try seekStream.getEndPos();

        if (@sizeOf(TGAFooter) > endPos) {
            return errors.ImageFormatInvalid;
        }

        const footer_position = endPos - @sizeOf(TGAFooter);
        try seekStream.seekTo(endPos - @sizeOf(TGAFooter));
        const footer: TGAFooter = try readStructLittle(inStream, TGAFooter);

        // Read extension
        if (footer.extension_offset > 0) {
            const extension_pos = @intCast(u64, footer.extension_offset);
            try seekStream.seekTo(extension_pos);
            self.extension = try readStructLittle(inStream, TGAExtension);
        }

        // Read header
        try seekStream.seekTo(0);
        self.header = try readStructLittle(inStream, TGAHeader);

        // Read ID
        if (self.header.id_length > 0) {
            var id_buffer: [256]u8 = undefined;
            std.mem.set(u8, id_buffer[0..], 0);

            const read_id_size = try inStream.read(id_buffer[0..self.header.id_length]);

            if (read_id_size != self.header.id_length) {
                return errors.ImageError.InvalidMagicHeader;
            }
        }

        const pixel_format = try self.pixelFormat();

        pixelsOpt.* = try color.ColorStorage.init(allocator, pixel_format, self.header.width * self.header.height);

        if (pixelsOpt.*) |pixels| {
            switch (pixel_format) {
                .Grayscale8 => {
                    try self.readGrayscale8(pixels.Grayscale8, inStream);
                },
                .Bpp8 => {
                    // Read color map
                    switch (self.header.color_map_bit_depth) {
                        15, 16 => {
                            try self.readColorMap16(pixels.Bpp8, inStream);
                        },
                        else => {
                            return errors.ImageError.UnsupportedPixelFormat;
                        },
                    }
                    // Read indices
                    try self.readIndexed8(pixels.Bpp8, inStream);
                },
                .Rgb555 => {
                    try self.readTruecolor16(pixels.Rgb555, inStream);
                },
                .Rgb24 => {
                    try self.readTruecolor24(pixels.Rgb24, inStream);
                },
                else => {
                    // Do nothing for now
                },
            }
        } else {
            return errors.ImageError.AllocationFailed;
        }
    }

    fn readGrayscale8(self: *Self, data: []color.Grayscale8, stream: ImageInStream) !void {
        var dataIndex: usize = 0;
        const dataEnd = self.header.width * self.header.height;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data[dataIndex] = color.Grayscale8{ .value = try stream.readByte() };
        }
    }

    fn readIndexed8(self: *Self, data: color.IndexedStorage8, stream: ImageInStream) !void {
        var dataIndex: usize = 0;
        const dataEnd = self.header.width * self.header.height;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data.indices[dataIndex] = try stream.readByte();
        }
    }

    fn readColorMap16(self: *Self, data: color.IndexedStorage8, stream: ImageInStream) !void {
        var dataIndex: usize = self.header.first_entry_index;
        const dataEnd = self.header.first_entry_index + self.header.color_map_length;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            const raw_color = try stream.readIntLittle(u16);

            data.palette[dataIndex].R = color.toColorFloat(@intCast(u5, (raw_color >> (5 * 2)) & 0x1F));
            data.palette[dataIndex].G = color.toColorFloat(@intCast(u5, (raw_color >> 5) & 0x1F));
            data.palette[dataIndex].B = color.toColorFloat(@intCast(u5, raw_color & 0x1F));
            data.palette[dataIndex].A = 1.0;
        }
    }

    fn readTruecolor16(self: *Self, data: []color.Rgb555, stream: ImageInStream) !void {
        var dataIndex: usize = 0;
        const dataEnd = self.header.width * self.header.height;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            const raw_color = try stream.readIntLittle(u16);

            data[dataIndex].R = @intCast(u5, (raw_color >> (5 * 2)) & 0x1F);
            data[dataIndex].G = @intCast(u5, (raw_color >> 5) & 0x1F);
            data[dataIndex].B = @intCast(u5, raw_color & 0x1F);
        }
    }

    fn readTruecolor24(self: *Self, data: []color.Rgb24, stream: ImageInStream) !void {
        var dataIndex: usize = 0;
        const dataEnd = self.header.width * self.header.height;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data[dataIndex].B = try stream.readByte();
            data[dataIndex].G = try stream.readByte();
            data[dataIndex].R = try stream.readByte();
        }
    }
};
