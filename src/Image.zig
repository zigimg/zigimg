const AllImageFormats = @import("formats/all.zig");
const Allocator = std.mem.Allocator;
const Colorf32 = color.Colorf32;
const PixelStorage = color.PixelStorage;
const FormatInterface = @import("format_interface.zig").FormatInterface;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const color = @import("color.zig");
const io = std.io;
const std = @import("std");
const utils = @import("utils.zig");

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
    std.io.StreamSource.GetSeekPosError;

pub const Format = enum {
    bmp,
    jpg,
    pbm,
    pcx,
    pgm,
    png,
    ppm,
    qoi,
    tga,
};

pub const Stream = io.StreamSource;

pub const EncoderOptions = AllImageFormats.ImageEncoderOptions;

pub const SaveInfo = struct {
    width: usize,
    height: usize,
    encoder_options: EncoderOptions,
};

/// Format-independant image
allocator: Allocator = undefined,
width: usize = 0,
height: usize = 0,
pixels: ?PixelStorage = null,

const Self = @This();

const FormatInteraceFnType = fn () FormatInterface;
const all_interface_funcs = blk: {
    const allFormatDecls = std.meta.declarations(AllImageFormats);
    var result: [allFormatDecls.len]FormatInteraceFnType = undefined;
    var index: usize = 0;
    for (allFormatDecls) |decl| {
        const decl_value = @field(AllImageFormats, decl.name);
        const entry_type = @TypeOf(decl_value);
        if (entry_type == type) {
            const entryTypeInfo = @typeInfo(decl_value);
            if (entryTypeInfo == .Struct) {
                for (entryTypeInfo.Struct.decls) |structEntry| {
                    if (std.mem.eql(u8, structEntry.name, "formatInterface")) {
                        result[index] = @field(decl_value, structEntry.name);
                        index += 1;
                        break;
                    }
                }
            }
        }
    }

    break :blk result[0..index];
};

/// Init an empty image with no pixel data
pub fn init(allocator: Allocator) Self {
    return Self{
        .allocator = allocator,
    };
}

/// Deinit the image
pub fn deinit(self: Self) void {
    if (self.pixels) |pixels| {
        pixels.deinit(self.allocator);
    }
}

/// Load an image from a file path
pub fn fromFilePath(allocator: Allocator, file_path: []const u8) !Self {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    return fromFile(allocator, &file);
}

/// Load an image from a standard library std.fs.File
pub fn fromFile(allocator: Allocator, file: *std.fs.File) !Self {
    var stream_source = io.StreamSource{ .file = file.* };
    return internalRead(allocator, &stream_source);
}

/// Load an image from a memory buffer
pub fn fromMemory(allocator: Allocator, buffer: []const u8) !Self {
    var stream_source = io.StreamSource{ .const_buffer = io.fixedBufferStream(buffer) };
    return internalRead(allocator, &stream_source);
}

/// Create a pixel surface from scratch
pub fn create(allocator: Allocator, width: usize, height: usize, pixel_format: PixelFormat) !Self {
    var result = Self{
        .allocator = allocator,
        .width = width,
        .height = height,
        .pixels = try PixelStorage.init(allocator, pixel_format, width * height),
    };

    return result;
}

/// Return the pixel format of the image
pub fn pixelFormat(self: Self) ?PixelFormat {
    if (self.pixels) |pixels| {
        return std.meta.activeTag(pixels);
    }

    return null;
}

/// Return the pixel data as a const byte slice
pub fn rawBytes(self: Self) []const u8 {
    return if (self.pixels) |pixels| pixels.asBytes() else &[_]u8{};
}

/// Return the byte size of a row in the image
pub fn rowByteSize(self: Self) usize {
    return self.imageByteSize() / self.height;
}

/// Return the byte size of the whole image
pub fn imageByteSize(self: Self) usize {
    return if (self.pixels) |pixels| pixels.asBytes().len else 0;
}

/// Write the image to an image format to the specified path
pub fn writeToFilePath(self: Self, file_path: []const u8, image_format: Format, encoder_options: EncoderOptions) !void {
    if (self.pixels == null) {
        return error.NoPixelData;
    }

    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try self.writeToFile(&file, image_format, encoder_options);
}

/// Write the image to an image format to the specified std.fs.File
pub fn writeToFile(self: Self, file: *std.fs.File, image_format: Format, encoder_options: EncoderOptions) !void {
    if (self.pixels == null) {
        return error.NoPixelData;
    }

    var image_save_info = SaveInfo{
        .width = self.width,
        .height = self.height,
        .encoder_options = encoder_options,
    };

    var format_interface = try findImageInterfaceFromImageFormat(image_format);

    var stream_source = io.StreamSource{ .file = file.* };

    if (self.pixels) |pixels| {
        try format_interface.writeForImage(self.allocator, &stream_source, pixels, image_save_info);
    }
}

/// Write the image to an image format in a memory buffer. The memory buffer is not grown
/// for you so make sure you pass a large enough buffer.
pub fn writeToMemory(self: Self, write_buffer: []u8, image_format: Format, encoder_options: EncoderOptions) ![]u8 {
    if (self.pixels == null) {
        return error.NoPixelData;
    }

    var image_save_info = SaveInfo{
        .width = self.width,
        .height = self.height,
        .encoder_options = encoder_options,
    };

    var format_interface = try findImageInterfaceFromImageFormat(image_format);

    var stream_source = io.StreamSource{ .buffer = std.io.fixedBufferStream(write_buffer) };

    if (self.pixels) |pixels| {
        try format_interface.writeForImage(self.allocator, &stream_source, pixels, image_save_info);
    }

    return stream_source.buffer.getWritten();
}

/// Iterate the pixel in pixel-format agnostic way. The iterator is read-only.
pub fn iterator(self: Self) color.PixelStorageIterator {
    if (self.pixels) |*pixels| {
        return color.PixelStorageIterator.init(pixels);
    }

    return color.PixelStorageIterator.initNull();
}

fn internalRead(allocator: Allocator, stream: *Stream) !Self {
    const format_interface = try findImageInterfaceFromStream(stream);

    try stream.seekTo(0);

    return try format_interface.readImage(allocator, stream);
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
    for (all_interface_funcs) |interface_fn| {
        const format_interface = interface_fn();

        if (format_interface.format() == image_format) {
            return format_interface;
        }
    }

    return Error.Unsupported;
}
