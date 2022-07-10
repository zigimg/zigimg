const AllImageFormats = @import("formats/all.zig");
const Allocator = std.mem.Allocator;
const Colorf32 = color.Colorf32;
const PixelStorage = color.PixelStorage;
const FormatInterface = @import("format_interface.zig").FormatInterface;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const color = @import("color.zig");
const errors = @import("errors.zig");
const io = std.io;
const std = @import("std");

pub const ImageFormat = enum {
    bmp,
    jpg,
    pbm,
    pcx,
    pgm,
    png,
    ppm,
    qoi,
    raw,
    tga,
};

pub const ImageStream = io.StreamSource;

pub const ImageEncoderOptions = AllImageFormats.ImageEncoderOptions;

pub const ImageSaveInfo = struct {
    width: usize,
    height: usize,
    encoder_options: ImageEncoderOptions,
};

pub const ImageInfo = struct {
    width: usize = 0,
    height: usize = 0,
};

/// Format-independant image
pub const Image = struct {
    allocator: Allocator = undefined,
    width: usize = 0,
    height: usize = 0,
    pixels: ?PixelStorage = null,
    image_format: ImageFormat = undefined,

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
        var result = init(allocator);

        var stream_source = io.StreamSource{ .file = file.* };

        try result.internalRead(allocator, &stream_source);

        return result;
    }

    /// Load an image from a memory buffer
    pub fn fromMemory(allocator: Allocator, buffer: []const u8) !Self {
        var result = init(allocator);

        var stream_source = io.StreamSource{ .const_buffer = io.fixedBufferStream(buffer) };

        try result.internalRead(allocator, &stream_source);

        return result;
    }

    /// Create a pixel surface from scratch
    pub fn create(allocator: Allocator, width: usize, height: usize, pixel_format: PixelFormat, image_format: ImageFormat) !Self {
        var result = Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .image_format = image_format,
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
    pub fn rawBytes(self: Self) ![]const u8 {
        if (self.pixels) |pixels| {
            return switch (pixels) {
                .rgb24 => |data| return std.mem.sliceAsBytes(data),
                .bgr24 => |data| return std.mem.sliceAsBytes(data),
                .rgba32 => |data| return std.mem.sliceAsBytes(data),
                .bgra32 => |data| return std.mem.sliceAsBytes(data),
                .float32 => |data| return std.mem.sliceAsBytes(data),
                else => return errors.ImageError.UnsupportedPixelFormat,
            };
        }

        return errors.ImageError.AllocationFailed;
    }

    /// Return the byte size of a row in the image
    pub fn rowByteSize(self: Self) !usize {
        if (self.pixels) |pixels| {
            return switch (pixels) {
                .rgb24 => return self.width * 3,
                .bgr24 => return self.width * 3,
                .rgba32 => return self.width * 4,
                .bgra32 => return self.width * 4,
                .float32 => return self.width * (4 * @sizeOf(f32)),
                else => return errors.ImageError.UnsupportedPixelFormat,
            };
        }

        return errors.ImageError.AllocationFailed;
    }

    /// Return the byte size of the whole image
    pub fn imageByteSize(self: Self) !usize {
        if (self.pixels) |pixels| {
            return switch (pixels) {
                .rgb24 => return self.width * self.height * 3,
                .bgr24 => return self.width * self.height * 3,
                .rgba32 => return self.width * self.height * 4,
                .bgra32 => return self.width * self.height * 4,
                .float32 => return self.width * self.height * (4 * @sizeOf(f32)),
                else => return errors.ImageError.UnsupportedPixelFormat,
            };
        }

        return errors.ImageError.AllocationFailed;
    }

    /// Write the image to an image format to the specified path
    pub fn writeToFilePath(self: Self, file_path: []const u8, image_format: ImageFormat, encoder_options: ImageEncoderOptions) !void {
        if (self.pixels == null) {
            return error.NoPixelData;
        }

        var file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();

        try self.writeToFile(&file, image_format, encoder_options);
    }

    /// Write the image to an image format to the specified std.fs.File
    pub fn writeToFile(self: Self, file: *std.fs.File, image_format: ImageFormat, encoder_options: ImageEncoderOptions) !void {
        if (self.pixels == null) {
            return error.NoPixelData;
        }

        var image_save_info = ImageSaveInfo{
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
    pub fn writeToMemory(self: Self, write_buffer: []u8, image_format: ImageFormat, encoder_options: ImageEncoderOptions) ![]u8 {
        if (self.pixels == null) {
            return error.NoPixelData;
        }

        var image_save_info = ImageSaveInfo{
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

    fn internalRead(self: *Self, allocator: Allocator, stream: *ImageStream) !void {
        var format_interface = try findImageInterfaceFromStream(stream);
        self.image_format = format_interface.format();

        try stream.seekTo(0);

        const image_info = try format_interface.readForImage(allocator, stream, &self.pixels);

        self.width = image_info.width;
        self.height = image_info.height;
    }

    fn findImageInterfaceFromStream(stream: *ImageStream) !FormatInterface {
        for (all_interface_funcs) |intefaceFn| {
            const formatInterface = intefaceFn();

            try stream.seekTo(0);
            const found = try formatInterface.formatDetect(stream);
            if (found) {
                return formatInterface;
            }
        }

        return errors.ImageFormatInvalid;
    }

    fn findImageInterfaceFromImageFormat(image_format: ImageFormat) !FormatInterface {
        for (all_interface_funcs) |interface_fn| {
            const format_interface = interface_fn();

            if (format_interface.format() == image_format) {
                return format_interface;
            }
        }

        return errors.ImageFormatInvalid;
    }
};
