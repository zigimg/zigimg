const color = @import("color.zig");
const ImageUnmanaged = @import("ImageUnmanaged.zig");
const io = @import("io.zig");
const std = @import("std");

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
formatDetect: *const FormatDetectFn,
readImage: *const ReadImageFn,
writeImage: *const WriteImageFn,

pub const FormatDetectFn = fn (read_stream: *io.ReadStream) ImageUnmanaged.ReadError!bool;
pub const ReadImageFn = fn (allocator: std.mem.Allocator, read_stream: *io.ReadStream) ImageUnmanaged.ReadError!ImageUnmanaged;
pub const WriteImageFn = fn (allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void;
