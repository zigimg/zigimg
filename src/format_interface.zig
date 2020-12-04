const image = @import("image.zig");
const color = @import("color.zig");
const Allocator = @import("std").mem.Allocator;

pub const FormatInterface = struct {
    format: FormatFn,
    formatDetect: FormatDetectFn,
    readForImage: ReadForImageFn,
    writeForImage: WriteForImageFn,

    pub const FormatFn = fn () image.ImageFormat;
    pub const FormatDetectFn = fn (inStream: image.ImageInStream, seekStream: image.ImageSeekStream) anyerror!bool;
    pub const ReadForImageFn = fn (allocator: *Allocator, inStream: image.ImageInStream, seekStream: image.ImageSeekStream, pixels: *?color.ColorStorage) anyerror!image.ImageInfo;
    pub const WriteForImageFn = fn (allocator: *Allocator, write_stream: image.ImageWriterStream, seek_stream: image.ImageSeekStream, pixels: color.ColorStorage, save_info: image.ImageSaveInfo) anyerror!void;
};
