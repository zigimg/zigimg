const Image = @import("Image.zig");
const color = @import("color.zig");
const Allocator = @import("std").mem.Allocator;
const ImageReadError = Image.ReadError;
const ImageWriteError = Image.WriteError;

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
pub const FormatInterface = struct {
    format: FormatFn,
    formatDetect: FormatDetectFn,
    readImage: ReadImageFn,
    writeImage: WriteImageFn,

    pub const FormatFn = if (@import("builtin").zig_backend == .stage1)
        fn () Image.Format
    else
        *const fn () Image.Format;

    pub const FormatDetectFn = if (@import("builtin").zig_backend == .stage1)
        fn (stream: *Image.Stream) ImageReadError!bool
    else
        *const fn (stream: *Image.Stream) ImageReadError!bool;

    pub const ReadImageFn = if (@import("builtin").zig_backend == .stage1)
        fn (allocator: Allocator, stream: *Image.Stream) ImageReadError!Image
    else
        *const fn (allocator: Allocator, stream: *Image.Stream) ImageReadError!Image;

    pub const WriteImageFn = if (@import("builtin").zig_backend == .stage1)
        fn (allocator: Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) ImageWriteError!void
    else
        *const fn (allocator: Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) ImageWriteError!void;
};
