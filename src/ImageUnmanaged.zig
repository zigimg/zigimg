const color = @import("color.zig");
const FormatInterface = @import("FormatInterface.zig");
const formats = @import("formats.zig");
const Image = @import("Image.zig");
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const PixelFormatConverter = @import("PixelFormatConverter.zig");
const std = @import("std");
const utils = @import("utils.zig");

const SupportedFormats = struct {
    pub const bmp = formats.bmp.BMP;
    pub const farbfeld = formats.farbfeld.Farbfeld;
    pub const gif = formats.gif.GIF;
    pub const ilbm = formats.ilbm.ILBM;
    pub const jpeg = formats.jpeg.JPEG;
    pub const pam = formats.pam.PAM;
    pub const pbm = formats.netpbm.PBM;
    pub const pcx = formats.pcx.PCX;
    pub const pgm = formats.netpbm.PGM;
    pub const png = formats.png.PNG;
    pub const ppm = formats.netpbm.PPM;
    pub const qoi = formats.qoi.QOI;
    pub const tga = formats.tga.TGA;
};

pub const Format = std.meta.DeclEnum(SupportedFormats);

pub const EncoderOptions = union(Format) {
    bmp: SupportedFormats.bmp.EncoderOptions,
    farbfeld: void,
    gif: void,
    ilbm: void,
    jpeg: void,
    pam: SupportedFormats.pam.EncoderOptions,
    pbm: SupportedFormats.pbm.EncoderOptions,
    pcx: SupportedFormats.pcx.EncoderOptions,
    pgm: SupportedFormats.pgm.EncoderOptions,
    png: SupportedFormats.png.EncoderOptions,
    ppm: SupportedFormats.ppm.EncoderOptions,
    qoi: SupportedFormats.qoi.EncoderOptions,
    tga: SupportedFormats.tga.EncoderOptions,
};

pub const Error = error{
    Unsupported,
};

pub const ReadError = Error ||
    std.mem.Allocator.Error ||
    utils.StructReadError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError ||
    error{ EndOfStream, StreamTooLong, InvalidData };

pub const WriteError = Error ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.WriteError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError ||
    std.fs.File.OpenError ||
    error{ EndOfStream, InvalidData, UnfinishedBits };

pub const ConvertError = Error ||
    std.mem.Allocator.Error ||
    error{ NoConversionAvailable, NoConversionNeeded, QuantizeError };

pub const Stream = std.io.StreamSource;

pub const AnimationLoopInfinite = -1;

pub const AnimationFrame = struct {
    pixels: color.PixelStorage,
    duration: f32,

    pub fn deinit(self: AnimationFrame, allocator: std.mem.Allocator) void {
        self.pixels.deinit(allocator);
    }
};

pub const Animation = struct {
    frames: FrameList = .{},
    loop_count: i32 = AnimationLoopInfinite,

    pub const FrameList = std.ArrayListUnmanaged(AnimationFrame);

    pub fn deinit(self: *Animation, allocator: std.mem.Allocator) void {
        // Animation share its first frame with the pixels in Image, we don't want to free it twice
        if (self.frames.items.len >= 2) {
            for (self.frames.items[1..]) |frame| {
                frame.pixels.deinit(allocator);
            }
        }

        self.frames.deinit(allocator);
    }
};

width: usize = 0,
height: usize = 0,
pixels: color.PixelStorage = .{ .invalid = void{} },
animation: Animation = .{},

const ImageUnmanaged = @This();

const FormatInteraceFnType = *const fn () FormatInterface;

const all_interface_funcs = blk: {
    const all_formats_delcs = std.meta.declarations(SupportedFormats);
    var result: []const FormatInteraceFnType = &[0]FormatInteraceFnType{};
    for (all_formats_delcs) |decl| {
        const decl_value = @field(SupportedFormats, decl.name);
        const entry_type = @TypeOf(decl_value);
        if (entry_type == type) {
            const entry_type_info = @typeInfo(decl_value);
            if (entry_type_info == .@"struct") {
                for (entry_type_info.@"struct".decls) |struct_entry| {
                    if (std.mem.eql(u8, struct_entry.name, "formatInterface")) {
                        result = result ++ [_]FormatInteraceFnType{
                            @field(decl_value, struct_entry.name),
                        };
                        break;
                    }
                }
            }
        }
    }
    break :blk result[0..];
};

/// Deinit the image
pub fn deinit(self: *ImageUnmanaged, allocator: std.mem.Allocator) void {
    self.pixels.deinit(allocator);
    self.animation.deinit(allocator);
}

/// Detect which image format is used by the file path
pub fn detectFormatFromFilePath(file_path: []const u8) !Format {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return detectFormatFromFile(&file);
}

/// Detect which image format is used by the file
pub fn detectFormatFromFile(file: *std.fs.File) !Format {
    var stream_source = std.io.StreamSource{ .file = file.* };
    return internalDetectFormat(&stream_source);
}

/// Detect which image format is used by the memory buffer
pub fn detectFormatFromMemory(buffer: []const u8) !Format {
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(buffer) };
    return internalDetectFormat(&stream_source);
}

/// Load an image from a file path
pub fn fromFilePath(allocator: std.mem.Allocator, file_path: []const u8) !ImageUnmanaged {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return fromFile(allocator, &file);
}

/// Load an image from a standard library std.fs.File
pub fn fromFile(allocator: std.mem.Allocator, file: *std.fs.File) !ImageUnmanaged {
    var stream_source = std.io.StreamSource{ .file = file.* };
    return internalRead(allocator, &stream_source);
}

/// Load an image from a memory buffer
pub fn fromMemory(allocator: std.mem.Allocator, buffer: []const u8) !ImageUnmanaged {
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(buffer) };
    return internalRead(allocator, &stream_source);
}

/// Create an ImageUnmanaged from a raw memory stream.
/// The resulting ImageUnmanaged will take ownership of the pixel data because it will be a wrapper
/// around the raw bytes.
///
/// Use fromRawPixels() to take a copy of the pixel data.
pub fn fromRawPixelsOwned(width: usize, height: usize, pixels: []const u8, pixel_format: PixelFormat) !ImageUnmanaged {
    return .{
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.initRawPixels(pixels, pixel_format),
    };
}

/// Create an ImageUnmanaged from a raw memory stream and create a copy of it.
/// The resulting ImageUnmanaged will own the pixel data.
pub fn fromRawPixels(allocator: std.mem.Allocator, width: usize, height: usize, pixels: []const u8, pixel_format: PixelFormat) !ImageUnmanaged {
    return .{
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.initRawPixels(try allocator.dupe(u8, pixels), pixel_format),
    };
}

/// Create a pixel surface from scratch
pub fn create(allocator: std.mem.Allocator, width: usize, height: usize, pixel_format: PixelFormat) !ImageUnmanaged {
    const result = ImageUnmanaged{
        .width = width,
        .height = height,
        .pixels = try color.PixelStorage.init(allocator, pixel_format, width * height),
    };

    return result;
}

/// Return the pixel format of the image
pub fn pixelFormat(self: ImageUnmanaged) PixelFormat {
    return std.meta.activeTag(self.pixels);
}

/// Return the pixel data as a const byte slice. In case of an animation, it return the pixel data of the first frame.
pub fn rawBytes(self: ImageUnmanaged) []const u8 {
    return self.pixels.asBytes();
}

/// Return the byte size of a row in the image
pub fn rowByteSize(self: ImageUnmanaged) usize {
    return self.imageByteSize() / self.height;
}

/// Return the byte size of the whole image
pub fn imageByteSize(self: ImageUnmanaged) usize {
    return self.rawBytes().len;
}

/// Is this image is an animation?
pub fn isAnimation(self: ImageUnmanaged) bool {
    return self.animation.frames.items.len > 0;
}

/// Convert to managed Image
pub fn toManaged(self: ImageUnmanaged, allocator: std.mem.Allocator) Image {
    return .{
        .allocator = allocator,
        .width = self.width,
        .height = self.height,
        .pixels = self.pixels,
        .animation = self.animation,
    };
}

/// Write the image to an image format to the specified path
pub fn writeToFilePath(self: ImageUnmanaged, allocator: std.mem.Allocator, file_path: []const u8, encoder_options: EncoderOptions) WriteError!void {
    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try self.writeToFile(allocator, file, encoder_options);
}

/// Write the image to an image format to the specified std.fs.File
pub fn writeToFile(self: ImageUnmanaged, allocator: std.mem.Allocator, file: std.fs.File, encoder_options: EncoderOptions) WriteError!void {
    var stream_source = std.io.StreamSource{ .file = file };

    try self.internalWrite(allocator, &stream_source, encoder_options);
}

/// Write the image to an image format in a memory buffer. The memory buffer is not grown
/// for you so make sure you pass a large enough buffer.
pub fn writeToMemory(self: ImageUnmanaged, allocator: std.mem.Allocator, write_buffer: []u8, encoder_options: EncoderOptions) WriteError![]u8 {
    var stream_source = std.io.StreamSource{ .buffer = std.io.fixedBufferStream(write_buffer) };

    try self.internalWrite(allocator, &stream_source, encoder_options);

    return stream_source.buffer.getWritten();
}

/// Convert the pixel format of the Image into another format.
/// It will allocate another pixel storage for the destination and free the old one
///
/// For the conversion to the indexed formats, no dithering is done.
pub fn convert(self: *ImageUnmanaged, allocator: std.mem.Allocator, destination_format: PixelFormat) ConvertError!void {
    // Do nothing if the format is the same
    if (std.meta.activeTag(self.pixels) == destination_format) {
        return;
    }

    const new_pixels = try PixelFormatConverter.convert(allocator, &self.pixels, destination_format);
    errdefer new_pixels.deinit(allocator);

    self.pixels.deinit(allocator);

    self.pixels = new_pixels;
}

/// Convert the pixel format of the Image into another format.
/// It will allocate another pixel storage for the destination and not free the old one.
/// Ths is in the case the image doess not own the pixel data.
///
/// For the conversion to the indexed formats, no dithering is done.
pub fn convertNoFree(self: *ImageUnmanaged, allocator: std.mem.Allocator, destination_format: PixelFormat) ConvertError!void {
    // Do nothing if the format is the same
    if (std.meta.activeTag(self.pixels) == destination_format) {
        return;
    }

    const new_pixels = try PixelFormatConverter.convert(allocator, &self.pixels, destination_format);
    errdefer new_pixels.deinit(allocator);

    self.pixels = new_pixels;
}

/// Iterate the pixel in pixel-format agnostic way. In the case of an animation, it returns an iterator for the first frame. The iterator is read-only.
pub fn iterator(self: *const ImageUnmanaged) color.PixelStorageIterator {
    return color.PixelStorageIterator.init(&self.pixels);
}

fn internalDetectFormat(stream: *Stream) !Format {
    for (all_interface_funcs, 0..) |intefaceFn, format_index| {
        const formatInterface = intefaceFn();

        try stream.seekTo(0);
        const found = try formatInterface.formatDetect(stream);
        if (found) {
            return @enumFromInt(format_index);
        }
    }

    return Error.Unsupported;
}

fn internalRead(allocator: std.mem.Allocator, stream: *Stream) !ImageUnmanaged {
    const format_interface = try findImageInterfaceFromStream(stream);

    try stream.seekTo(0);

    return try format_interface.readImage(allocator, stream);
}

fn internalWrite(self: ImageUnmanaged, allocator: std.mem.Allocator, stream: *Stream, encoder_options: EncoderOptions) WriteError!void {
    const image_format = std.meta.activeTag(encoder_options);

    var format_interface = try findImageInterfaceFromImageFormat(image_format);

    try format_interface.writeImage(allocator, stream, self, encoder_options);
}

fn findImageInterfaceFromStream(stream: *Stream) !FormatInterface {
    for (all_interface_funcs) |intefaceFn| {
        const formatInterface = intefaceFn();

        try stream.seekTo(0);
        const found = try formatInterface.formatDetect(stream);
        if (found) {
            return formatInterface;
        }
    }

    return Error.Unsupported;
}

fn findImageInterfaceFromImageFormat(image_format: Format) !FormatInterface {
    return all_interface_funcs[@intFromEnum(image_format)]();
}
