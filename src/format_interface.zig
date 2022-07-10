const image = @import("image.zig");
const color = @import("color.zig");
const Allocator = @import("std").mem.Allocator;

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
pub const FormatInterface = struct {
    format: FormatFn,
    formatDetect: FormatDetectFn,
    readForImage: ReadForImageFn,
    writeForImage: WriteForImageFn,

    pub const FormatFn = fn () image.ImageFormat;
    pub const FormatDetectFn = fn (stream: *image.ImageStream) anyerror!bool;
    pub const ReadForImageFn = fn (allocator: Allocator, stream: *image.ImageStream, pixels: *?color.PixelStorage) anyerror!image.ImageInfo;
    pub const WriteForImageFn = fn (allocator: Allocator, write_stream: *image.ImageStream, pixels: color.PixelStorage, save_info: image.ImageSaveInfo) anyerror!void;
};
