const image = @import("image.zig");
const color = @import("color.zig");
const Allocator = @import("std").mem.Allocator;
const errors = @import("errors.zig");
const ImageReadError = errors.ImageReadError;
const ImageWriteError = errors.ImageWriteError;

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
pub const FormatInterface = struct {
    format: FormatFn,
    formatDetect: FormatDetectFn,
    readForImage: ReadForImageFn,
    writeForImage: WriteForImageFn,

    pub const FormatFn = fn () image.ImageFormat;
    pub const FormatDetectFn = fn (stream: *image.ImageStream) ImageReadError!bool;
    pub const ReadForImageFn = fn (allocator: Allocator, stream: *image.ImageStream, pixels: *?color.PixelStorage) ImageReadError!image.ImageInfo;
    pub const WriteForImageFn = fn (allocator: Allocator, write_stream: *image.ImageStream, pixels: color.PixelStorage, save_info: image.ImageSaveInfo) ImageWriteError!void;
};
