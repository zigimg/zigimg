const AllImageFormats = @import("formats/all.zig");
const Allocator = std.mem.Allocator;
const Color = color.Color;
const ColorStorage = color.ColorStorage;
const FormatInterface = @import("format_interface.zig").FormatInterface;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const color = @import("color.zig");
const errors = @import("errors.zig");
const io = std.io;
const std = @import("std");

pub const ImageFormat = enum {
    Bmp,
    Pbm,
    Pcx,
    Pgm,
    Png,
    Ppm,
    Raw,
};

pub const ImageInStream = io.StreamSource.InStream;
pub const ImageSeekStream = io.StreamSource.SeekableStream;

pub const ImageInfo = struct {
    width: usize = 0,
    height: usize = 0,
    pixel_format: PixelFormat = undefined,
};

/// Format-independant image
pub const Image = struct {
    allocator: *Allocator = undefined,
    width: usize = 0,
    height: usize = 0,
    pixels: ?ColorStorage = null,
    pixel_format: PixelFormat = undefined,
    image_format: ImageFormat = undefined,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        if (self.pixels) |pixels| {
            pixels.deinit(self.allocator);
        }
    }

    pub fn fromFilePath(allocator: *Allocator, file_path: []const u8) !Self {
        const cwd = std.fs.cwd();

        var resolvedPath = try std.fs.path.resolve(allocator, &[_][]const u8{file_path});
        defer allocator.free(resolvedPath);

        var file = try cwd.openFile(resolvedPath, .{});
        defer file.close();

        return fromFile(allocator, &file);
    }

    pub fn fromFile(allocator: *Allocator, file: *std.fs.File) !Self {
        var result = init(allocator);

        var stream_source = io.StreamSource{ .file = file.* };

        try result.internalRead(allocator, stream_source.inStream(), stream_source.seekableStream());

        return result;
    }

    pub fn fromMemory(allocator: *Allocator, buffer: []const u8) !Image {
        var result = init(allocator);

        var stream_source = io.StreamSource{ .const_buffer = io.fixedBufferStream(buffer) };

        try result.internalRead(allocator, stream_source.inStream(), stream_source.seekableStream());

        return result;
    }

    pub fn create(allocator: *Allocator, width: usize, height: usize, pixel_format: PixelFormat) !Self {
        var result = Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .pixel_format = pixel_format,
            .image_format = .Raw,
            .pixels = try ColorStorage.init(allocator, pixel_format, width * height),
        };

        return result;
    }

    pub fn iterator(self: Self) color.ColorStorageIterator {
        if (self.pixels) |*pixels| {
            return color.ColorStorageIterator.init(pixels);
        }

        return color.ColorStorageIterator.initNull();
    }

    fn internalRead(self: *Self, allocator: *Allocator, inStream: ImageInStream, seekStream: ImageSeekStream) !void {
        var formatInterface = try findImageInterface(inStream, seekStream);
        self.image_format = formatInterface.format();

        try seekStream.seekTo(0);

        const imageInfo = try formatInterface.readForImage(allocator, inStream, seekStream, &self.pixels);

        self.width = imageInfo.width;
        self.height = imageInfo.height;
        self.pixel_format = imageInfo.pixel_format;
    }

    fn findImageInterface(inStream: ImageInStream, seekStream: ImageSeekStream) !FormatInterface {
        const FormatInteraceFnType = fn () FormatInterface;
        const allFuncs = comptime blk: {
            const allFormatDecls = std.meta.declarations(AllImageFormats);
            var result: [allFormatDecls.len]FormatInteraceFnType = undefined;
            var index: usize = 0;
            for (allFormatDecls) |decl| {
                switch (decl.data) {
                    .Type => |entryType| {
                        const entryTypeInfo = @typeInfo(entryType);
                        if (entryTypeInfo == .Struct) {
                            for (entryTypeInfo.Struct.decls) |structEntry| {
                                if (std.mem.eql(u8, structEntry.name, "formatInterface")) {
                                    result[index] = @field(entryType, structEntry.name);
                                    index += 1;
                                    break;
                                }
                            }
                        }
                    },
                    else => {},
                }
            }

            break :blk result[0..index];
        };

        for (allFuncs) |intefaceFn| {
            const formatInterface = intefaceFn();

            try seekStream.seekTo(0);
            const found = try formatInterface.formatDetect(inStream, seekStream);
            if (found) {
                return formatInterface;
            }
        }

        return errors.ImageFormatInvalid;
    }
};
