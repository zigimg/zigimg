const color = @import("color.zig");
const Image = @import("Image.zig");
const io = @import("io.zig");
const std = @import("std");

// mlarouche: Because this is a interface, I use Zig function naming convention instead of the variable naming convention
formatDetect: *const FormatDetectFn,
readImage: *const ReadImageFn,
writeImage: *const WriteImageFn,

pub const FormatDetectFn = fn (read_stream: *io.ReadStream) Image.ReadError!bool;
pub const ReadImageFn = fn (allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image;
pub const WriteImageFn = fn (allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void;
