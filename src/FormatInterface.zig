const std = @import("std");
const ImageUnmanaged = @import("ImageUnmanaged.zig");
const color = @import("color.zig");

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
format: *const FormatFn,
formatDetect: *const FormatDetectFn,
readImage: *const ReadImageFn,
writeImage: *const WriteImageFn,

pub const FormatFn = fn () ImageUnmanaged.Format;
pub const FormatDetectFn = fn (stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!bool;
pub const ReadImageFn = fn (allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged;
pub const WriteImageFn = fn (allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void;
