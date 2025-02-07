const std = @import("std");
const color = @import("color.zig");
const ImageUnmanaged = @import("ImageUnmanaged.zig");
const PixelFormat = @import("pixel_format.zig").PixelFormat;

pub const Error = ImageUnmanaged.Error;

pub const ReadError = ImageUnmanaged.ReadError;

pub const WriteError = ImageUnmanaged.WriteError;

pub const ConvertError = ImageUnmanaged.ConvertError;

pub const Format = ImageUnmanaged.Format;

pub const Stream = ImageUnmanaged.Stream;

pub const EncoderOptions = ImageUnmanaged.EncoderOptions;

pub const AnimationLoopInfinite = ImageUnmanaged.AnimationLoopInfinite;

pub const AnimationFrame = ImageUnmanaged.AnimationFrame;

pub const Animation = ImageUnmanaged.Animation;

// This layout must match the one in ImageUnmanaged
width: usize = 0,
height: usize = 0,
pixels: color.PixelStorage = .{ .invalid = void{} },
animation: Animation = .{},
allocator: std.mem.Allocator = undefined, // Allocator needs to be last in order to be able to ptrCast to ImageUnmanaged

const Image = @This();

/// Init an empty image with no pixel data
pub fn init(allocator: std.mem.Allocator) Image {
    return Image{
        .allocator = allocator,
    };
}

/// Deinit the image
pub fn deinit(self: *Image) void {
    ImageUnmanaged.deinit(@ptrCast(self), self.allocator);
}

/// Detect which image format is used by the file path
pub fn detectFormatFromFilePath(file_path: []const u8) !Format {
    return ImageUnmanaged.detectFormatFromFilePath(file_path);
}

/// Detect which image format is used by the file
pub fn detectFormatFromFile(file: *std.fs.File) !Format {
    return ImageUnmanaged.detectFormatFromFile(file);
}

/// Detect which image format is used by the memory buffer
pub fn detectFormatFromMemory(buffer: []const u8) !Format {
    return ImageUnmanaged.detectFormatFromMemory(buffer);
}

/// Load an image from a file path
pub fn fromFilePath(allocator: std.mem.Allocator, file_path: []const u8) !Image {
    return (try ImageUnmanaged.fromFilePath(allocator, file_path)).toManaged(allocator);
}

/// Load an image from a standard library std.fs.File
pub fn fromFile(allocator: std.mem.Allocator, file: *std.fs.File) !Image {
    return (try ImageUnmanaged.fromFile(allocator, file)).toManaged(allocator);
}

/// Load an image from a memory buffer
pub fn fromMemory(allocator: std.mem.Allocator, buffer: []const u8) !Image {
    return (try ImageUnmanaged.fromMemory(allocator, buffer)).toManaged(allocator);
}

/// Create an Image from a raw memory stream and create a copy of it.
/// The resulting Image will own the pixel data.
pub fn fromRawPixels(allocator: std.mem.Allocator, width: usize, height: usize, pixels: []const u8, pixel_format: PixelFormat) !Image {
    return .{
        .allocator = allocator,
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.initRawPixels(try allocator.dupe(u8, pixels), pixel_format),
    };
}

/// Create a pixel surface from scratch
pub fn create(allocator: std.mem.Allocator, width: usize, height: usize, pixel_format: PixelFormat) !Image {
    const result = Image{
        .allocator = allocator,
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.init(allocator, pixel_format, width * height),
    };

    return result;
}

/// Return the pixel format of the image
pub fn pixelFormat(self: Image) PixelFormat {
    return std.meta.activeTag(self.pixels);
}

/// Return the pixel data as a const byte slice. In case of an animation, it return the pixel data of the first frame.
pub fn rawBytes(self: Image) []const u8 {
    return self.pixels.asBytes();
}

/// Return the byte size of a row in the image
pub fn rowByteSize(self: Image) usize {
    return self.imageByteSize() / self.height;
}

/// Return the byte size of the whole image
pub fn imageByteSize(self: Image) usize {
    return self.rawBytes().len;
}

/// Is this image is an animation?
pub fn isAnimation(self: Image) bool {
    return self.animation.frames.items.len > 0;
}

/// Write the image to an image format to the specified path
pub fn writeToFilePath(self: Image, file_path: []const u8, encoder_options: EncoderOptions) WriteError!void {
    return ImageUnmanaged.writeToFilePath(self.toUnmanaged(), self.allocator, file_path, encoder_options);
}

/// Write the image to an image format to the specified std.fs.File
pub fn writeToFile(self: Image, file: std.fs.File, encoder_options: EncoderOptions) WriteError!void {
    return ImageUnmanaged.writeToFile(self.toUnmanaged(), self.allocator, file, encoder_options);
}

/// Write the image to an image format in a memory buffer. The memory buffer is not grown
/// for you so make sure you pass a large enough buffer.
pub fn writeToMemory(self: Image, write_buffer: []u8, encoder_options: EncoderOptions) WriteError![]u8 {
    return ImageUnmanaged.writeToMemory(self.toUnmanaged(), self.allocator, write_buffer, encoder_options);
}

/// Convert the pixel format of the Image into another format.
/// It will allocate another pixel storage for the destination and free the old one
/// For the conversion to the indexed formats, no dithering is done.
pub fn convert(self: *Image, destination_format: PixelFormat) ConvertError!void {
    return ImageUnmanaged.convert(@ptrCast(self), self.allocator, destination_format);
}

/// Iterate the pixel in pixel-format agnostic way. In the case of an animation, it returns an iterator for the first frame. The iterator is read-only.
// FIXME: *const Image is a workaround for a stage2 bug because determining the pass a parameter by value or pointer depending of the size is not mature yet
// and fails. For now we are explictly requesting to access only a const pointer.
pub fn iterator(self: *const Image) color.PixelStorageIterator {
    return color.PixelStorageIterator.init(&self.pixels);
}

/// Convert to unmanaged version
pub fn toUnmanaged(self: Image) ImageUnmanaged {
    return .{
        .width = self.width,
        .height = self.height,
        .pixels = self.pixels,
        .animation = self.animation,
    };
}
