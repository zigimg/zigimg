const std = @import("std");
const color = @import("../color.zig");
const Image = @import("../Image.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

pub const Error = Image.Error;
pub const ReadError = Image.ReadError;
pub const WriteError = Image.WriteError;
pub const ConvertError = Image.ConvertError;
pub const Format = Image.Format;
pub const Stream = Image.Stream;
pub const EncoderOptions = Image.EncoderOptions;
pub const AnimationLoopInfinite = Image.AnimationLoopInfinite;
pub const AnimationFrame = Image.AnimationFrame;
pub const Animation = Image.Animation;
pub const Editor = Image.Editor;

// This layout must match the one in Image
width: usize = 0,
height: usize = 0,
pixels: color.PixelStorage = .{ .invalid = void{} },
animation: Animation = .{},
allocator: std.mem.Allocator = undefined, // Allocator needs to be last in order to be able to ptrCast to Image

const Managed = @This();

/// Init an empty image with no pixel data
pub fn init(allocator: std.mem.Allocator) Managed {
    return Managed{
        .allocator = allocator,
    };
}

/// Deinit the image
pub fn deinit(self: *Managed) void {
    Image.deinit(@ptrCast(self), self.allocator);
}

/// Detect which image format is used by the file path
pub fn detectFormatFromFilePath(file_path: []const u8, read_buffer: []u8) !Format {
    return Image.detectFormatFromFilePath(file_path, read_buffer);
}

/// Detect which image format is used by the file
pub fn detectFormatFromFile(file: std.fs.File, read_buffer: []u8) !Format {
    return Image.detectFormatFromFile(file, read_buffer);
}

/// Detect which image format is used by the memory buffer
pub fn detectFormatFromMemory(buffer: []const u8) !Format {
    return Image.detectFormatFromMemory(buffer);
}

/// Load an image from a file path
pub fn fromFilePath(allocator: std.mem.Allocator, file_path: []const u8, read_buffer: []u8) !Managed {
    return (try Image.fromFilePath(allocator, file_path, read_buffer)).toManaged(allocator);
}

/// Load an image from a standard library std.fs.File
pub fn fromFile(allocator: std.mem.Allocator, file: std.fs.File, read_buffer: []u8) !Managed {
    return (try Image.fromFile(allocator, file, read_buffer)).toManaged(allocator);
}

/// Load an image from a memory buffer
pub fn fromMemory(allocator: std.mem.Allocator, buffer: []const u8) !Managed {
    return (try Image.fromMemory(allocator, buffer)).toManaged(allocator);
}

/// Create an Image from a raw memory stream and create a copy of it.
/// The resulting Image will own the pixel data.
pub fn fromRawPixels(allocator: std.mem.Allocator, width: usize, height: usize, pixels: []const u8, pixel_format: PixelFormat) !Managed {
    return .{
        .allocator = allocator,
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.initRawPixels(try allocator.dupe(u8, pixels), pixel_format),
    };
}

/// Create a pixel surface from scratch
pub fn create(allocator: std.mem.Allocator, width: usize, height: usize, pixel_format: PixelFormat) !Managed {
    const result = Managed{
        .allocator = allocator,
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.init(allocator, pixel_format, width * height),
    };

    return result;
}

/// Return the pixel format of the image
pub fn pixelFormat(self: Managed) PixelFormat {
    return std.meta.activeTag(self.pixels);
}

/// Return the pixel data as a const byte slice. In case of an animation, it return the pixel data of the first frame.
pub fn rawBytes(self: Managed) []const u8 {
    return self.pixels.asBytes();
}

/// Return the byte size of a row in the image
pub fn rowByteSize(self: Managed) usize {
    return self.imageByteSize() / self.height;
}

/// Return the byte size of the whole image
pub fn imageByteSize(self: Managed) usize {
    return self.rawBytes().len;
}

/// Is this image is an animation?
pub fn isAnimation(self: Managed) bool {
    return self.animation.frames.items.len > 0;
}

/// Write the image to an image format to the specified path
pub fn writeToFilePath(self: Managed, file_path: []const u8, write_buffer: []u8, encoder_options: EncoderOptions) WriteError!void {
    return Image.writeToFilePath(self.toUnmanaged(), self.allocator, file_path, write_buffer, encoder_options);
}

/// Write the image to an image format to the specified std.fs.File
pub fn writeToFile(self: Managed, file: std.fs.File, write_buffer: []u8, encoder_options: EncoderOptions) WriteError!void {
    return Image.writeToFile(self.toUnmanaged(), self.allocator, file, write_buffer, encoder_options);
}

/// Write the image to an image format in a memory buffer. The memory buffer is not grown
/// for you so make sure you pass a large enough buffer.
pub fn writeToMemory(self: Managed, write_buffer: []u8, encoder_options: EncoderOptions) WriteError![]u8 {
    return Image.writeToMemory(self.toUnmanaged(), self.allocator, write_buffer, encoder_options);
}

/// Convert the pixel format of the Image into another format.
/// It will allocate another pixel storage for the destination and free the old one
/// For the conversion to the indexed formats, no dithering is done.
pub fn convert(self: *Managed, destination_format: PixelFormat) ConvertError!void {
    return Image.convert(@ptrCast(self), self.allocator, destination_format);
}

/// Flip the image vertically, along the X axis.
pub fn flipVertically(self: *const Managed) Image.Editor.Error!void {
    try Image.flipVertically(@ptrCast(self), self.allocator);
}

/// Return a cropped copy of an image.
pub fn crop(self: *const Managed, allocator: std.mem.Allocator, area: Image.Editor.Box) Image.Editor.Error!Managed {
    return (try Image.crop(@ptrCast(self), allocator, area)).toManaged(allocator);
}

/// Iterate the pixel in pixel-format agnostic way. In the case of an animation, it returns an iterator for the first frame. The iterator is read-only.
pub fn iterator(self: *const Managed) color.PixelStorageIterator {
    return color.PixelStorageIterator.init(&self.pixels);
}

/// Convert to unmanaged version
pub fn toUnmanaged(self: Managed) Image {
    return .{
        .width = self.width,
        .height = self.height,
        .pixels = self.pixels,
        .animation = self.animation,
    };
}
