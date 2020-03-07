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

const PNGMagicHeader = "\x89PNG";

pub const PNG = struct {
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
        return ImageFormat.Png;
    }

    pub fn formatDetect(inStream: *ImageInStream, seekStream: *ImageSeekStream) !bool {
        var magicNumberBuffer: [4]u8 = undefined;
        _ = try inStream.read(magicNumberBuffer[0..]);

        return std.mem.eql(u8, magicNumberBuffer[0..], PNGMagicHeader);
    }

    pub fn readForImage(allocator: *Allocator, inStream: *ImageInStream, seekStream: *ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        // var pcx = PCX{};

        // try pcx.read(allocator, inStream, seekStream, pixels);

        var imageInfo = ImageInfo{};
        // imageInfo.width = pcx.width;
        // imageInfo.height = pcx.height;
        // imageInfo.pixel_format = pcx.pixel_format;

        return imageInfo;
    }
};