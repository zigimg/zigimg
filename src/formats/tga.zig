const Allocator = std.mem.Allocator;
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageFormat = image.ImageFormat;
const ImageReader = image.ImageReader;
const ImageInfo = image.ImageInfo;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const errors = @import("../errors.zig");
const fs = std.fs;
const image = @import("../image.zig");
const io = std.io;
const mem = std.mem;
const path = std.fs.path;
const std = @import("std");
usingnamespace @import("../utils.zig");

pub const TGAImageType = packed struct {
    indexed: bool = false,
    truecolor: bool = false,
    pad0: bool = false,
    run_length: bool = false,
    pad1: u4 = 0,
};

pub const TGAColorMapSpec = packed struct {
    first_entry_index: u16 = 0,
    color_map_length: u16 = 0,
    color_map_bit_depth: u8 = 0,
};

pub const TGAImageSpec = packed struct {
    origin_x: u16 = 0,
    origin_y: u16 = 0,
    width: u16 = 0,
    height: u16 = 0,
    bit_per_pixel: u8 = 0,
    descriptor: u8 = 0,
};

pub const TGAHeader = packed struct {
    id_length: u8 = 0,
    has_color_map: u8 = 0,
    image_type: TGAImageType = .{},

    // BEGIN: TGAColorMapSpec
    first_entry_index: u16 = 0,
    color_map_length: u16 = 0,
    color_map_bit_depth: u8 = 0,
    // END TGAColorMapSpec
    // TODO: Use TGAColorMapSpec once all packed struct bugs are fixed
    // color_map_spec: TGAColorMapSpec,

    // BEGIN TGAImageSpec
    origin_x: u16 = 0,
    origin_y: u16 = 0,
    width: u16 = 0,
    height: u16 = 0,
    bit_per_pixel: u8 = 0,
    descriptor: u8 = 0,
    // END TGAImageSpec
    //TODO: Use TGAImageSpec once all packed struct bugs are fixed
    //image_spec: TGAImageSpec,
};

pub const TGAAttributeType = enum(u8) {
    NoAlpha = 0,
    UndefinedAlphaIgnore = 1,
    UndefinedAlphaRetained = 2,
    UsefulAlphaChannel = 3,
    PremultipledAlpha = 4,
};

pub const TGAExtension = packed struct {
    extension_size: u16 = 0,
    author_name: [41]u8 = undefined,
    author_comment: [324]u8 = undefined,
    timestamp: [12]u8 = undefined,
    job_id: [41]u8 = undefined,
    job_time: [6]u8 = undefined,
    software_id: [41]u8 = undefined,
    software_version: [3]u8 = undefined,
    key_color: [4]u8 = undefined,
    pixel_aspect: [4]u8 = undefined,
    gamma_value: [4]u8 = undefined,
    color_correction_offset: u32 = 0,
    postage_stamp_offset: u32 = 0,
    scanline_offset: u32 = 0,
    attributes: TGAAttributeType = .NoAlpha,
};

pub const TGAFooter = packed struct {
    extension_offset: u32,
    dev_area_offset: u32,
    signature: [16]u8,
    dot: u8,
    null_value: u8,
};

pub const TGASignature = "TRUEVISION-XFILE";

comptime {
    std.debug.assert(@sizeOf(TGAExtension) == 495);
}

const TargaRLEDecoder = struct {
    source_stream: ImageReader,
    allocator: *Allocator,
    bytes_per_pixel: usize,

    state: State = .ReadHeader,
    repeat_count: usize = 0,
    repeat_data: []u8 = undefined,
    data_stream: std.io.FixedBufferStream([]u8) = undefined,

    const Self = @This();

    pub const ReadError = error{ InputOutput, BrokenPipe } || std.io.StreamSource.ReadError;

    const State = enum {
        ReadHeader,
        Repeated,
        Raw,
    };

    const PacketType = enum(u1) {
        Raw = 0,
        Repeated = 1,
    };
    const PacketHeader = packed struct {
        pixel_count: u7,
        packet_type: PacketType,
    };

    pub fn init(allocator: *Allocator, source_stream: ImageReader, bytes_per_pixels: usize) !Self {
        var result = Self{
            .allocator = allocator,
            .source_stream = source_stream,
            .bytes_per_pixel = bytes_per_pixels,
        };

        result.repeat_data = try allocator.alloc(u8, bytes_per_pixels);
        result.data_stream = std.io.fixedBufferStream(result.repeat_data);
        return result;
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.repeat_data);
    }

    pub fn read(self: *Self, dest: []u8) ReadError!usize {
        var read_count: usize = 0;

        if (self.state == .ReadHeader) {
            const packet_header = readStructLittle(self.source_stream, PacketHeader) catch return ReadError.InputOutput;

            if (packet_header.packet_type == .Repeated) {
                self.state = .Repeated;

                self.repeat_count = @intCast(usize, packet_header.pixel_count) + 1;

                _ = try self.source_stream.read(self.repeat_data);

                self.data_stream.reset();
            } else if (packet_header.packet_type == .Raw) {
                self.state = .Raw;

                self.repeat_count = (@intCast(usize, packet_header.pixel_count) + 1) * self.bytes_per_pixel;
            }
        }

        switch (self.state) {
            .Repeated => {
                _ = try self.data_stream.read(dest);

                const end_pos = try self.data_stream.getEndPos();
                if (self.data_stream.pos >= end_pos) {
                    self.data_stream.reset();

                    self.repeat_count -= 1;
                }

                read_count = dest.len;
            },
            .Raw => {
                const read_bytes = try self.source_stream.read(dest);

                self.repeat_count -= read_bytes;

                read_count = read_bytes;
            },
            else => {
                return ReadError.BrokenPipe;
            },
        }

        if (self.repeat_count == 0) {
            self.state = .ReadHeader;
        }

        return read_count;
    }

    pub fn reader(self: *Self) Reader {
        return .{ .context = @ptrCast(*std.io.StreamSource, self) };
    }
};

pub const TargaStream = union(enum) {
    image: ImageReader,
    rle: TargaRLEDecoder,

    pub const ReadError = ImageReader.Error || TargaRLEDecoder.ReadError;
    pub const Reader = std.io.Reader(*TargaStream, ReadError, read);

    pub fn read(self: *TargaStream, dest: []u8) ReadError!usize {
        switch (self.*) {
            .image => |*x| return x.read(dest),
            .rle => |*x| return x.read(dest),
        }
    }

    pub fn reader(self: *TargaStream) Reader {
        return .{ .context = self };
    }
};

pub const TGA = struct {
    header: TGAHeader = .{},
    extension: ?TGAExtension = null,

    const Self = @This();

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = @ptrCast(FormatInterface.FormatFn, format),
            .formatDetect = @ptrCast(FormatInterface.FormatDetectFn, formatDetect),
            .readForImage = @ptrCast(FormatInterface.ReadForImageFn, readForImage),
            .writeForImage = @ptrCast(FormatInterface.WriteForImageFn, writeForImage),
        };
    }

    pub fn format() ImageFormat {
        return ImageFormat.Tga;
    }

    pub fn formatDetect(reader: ImageReader, seekStream: ImageSeekStream) !bool {
        const endPos = try seekStream.getEndPos();

        if (@sizeOf(TGAFooter) < endPos) {
            const footer_position = endPos - @sizeOf(TGAFooter);

            try seekStream.seekTo(footer_position);
            const footer: TGAFooter = try readStructLittle(reader, TGAFooter);

            if (footer.dot != '.') {
                return false;
            }

            if (footer.null_value != 0) {
                return false;
            }

            if (std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
                return true;
            }
        }

        return false;
    }

    pub fn readForImage(allocator: *Allocator, reader: ImageReader, seekStream: ImageSeekStream, pixels: *?color.ColorStorage) !ImageInfo {
        var tga = Self{};

        try tga.read(allocator, reader, seekStream, pixels);

        var imageInfo = ImageInfo{};
        imageInfo.width = tga.width();
        imageInfo.height = tga.height();
        imageInfo.pixel_format = try tga.pixelFormat();
        return imageInfo;
    }

    pub fn writeForImage(allocator: *Allocator, write_stream: image.ImageWriterStream, seek_stream: ImageSeekStream, pixels: color.ColorStorage, save_info: image.ImageSaveInfo) !void {
        _ = allocator;
        _ = write_stream;
        _ = seek_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn width(self: Self) usize {
        return self.header.width;
    }

    pub fn height(self: Self) usize {
        return self.header.height;
    }

    pub fn pixelFormat(self: Self) !PixelFormat {
        if (self.header.image_type.indexed) {
            if (self.header.image_type.truecolor) {
                return PixelFormat.Grayscale8;
            }

            return PixelFormat.Bpp8;
        } else if (self.header.image_type.truecolor) {
            switch (self.header.bit_per_pixel) {
                16 => return PixelFormat.Rgb555,
                24 => return PixelFormat.Rgb24,
                32 => return PixelFormat.Rgba32,
                else => {},
            }
        }

        return errors.ImageError.UnsupportedPixelFormat;
    }

    pub fn read(self: *Self, allocator: *Allocator, reader: ImageReader, seekStream: ImageSeekStream, pixelsOpt: *?color.ColorStorage) !void {
        // Read footage
        const endPos = try seekStream.getEndPos();

        if (@sizeOf(TGAFooter) > endPos) {
            return errors.ImageFormatInvalid;
        }

        _ = endPos - @sizeOf(TGAFooter);
        try seekStream.seekTo(endPos - @sizeOf(TGAFooter));
        const footer: TGAFooter = try readStructLittle(reader, TGAFooter);

        if (!std.mem.eql(u8, footer.signature[0..], TGASignature[0..])) {
            return errors.ImageError.InvalidMagicHeader;
        }

        // Read extension
        if (footer.extension_offset > 0) {
            const extension_pos = @intCast(u64, footer.extension_offset);
            try seekStream.seekTo(extension_pos);
            self.extension = try readStructLittle(reader, TGAExtension);
        }

        // Read header
        try seekStream.seekTo(0);
        self.header = try readStructLittle(reader, TGAHeader);

        // Read ID
        if (self.header.id_length > 0) {
            var id_buffer: [256]u8 = undefined;
            std.mem.set(u8, id_buffer[0..], 0);

            const read_id_size = try reader.read(id_buffer[0..self.header.id_length]);

            if (read_id_size != self.header.id_length) {
                return errors.ImageError.InvalidMagicHeader;
            }
        }

        const pixel_format = try self.pixelFormat();

        pixelsOpt.* = try color.ColorStorage.init(allocator, pixel_format, self.width() * self.height());

        if (pixelsOpt.*) |pixels| {
            const is_compressed = self.header.image_type.run_length;

            var targa_stream: TargaStream = TargaStream{ .image = reader };
            var rle_decoder: ?TargaRLEDecoder = null;

            defer {
                if (rle_decoder) |rle| {
                    rle.deinit();
                }
            }

            if (is_compressed) {
                const bytes_per_pixel = (self.header.bit_per_pixel + 7) / 8;

                rle_decoder = try TargaRLEDecoder.init(allocator, reader, bytes_per_pixel);
                if (rle_decoder) |rle| {
                    targa_stream = TargaStream{ .rle = rle };
                }
            }

            switch (pixel_format) {
                .Grayscale8 => {
                    try self.readGrayscale8(pixels.Grayscale8, targa_stream.reader());
                },
                .Bpp8 => {
                    // Read color map
                    switch (self.header.color_map_bit_depth) {
                        15, 16 => {
                            try self.readColorMap16(pixels.Bpp8, (TargaStream{ .image = reader }).reader());
                        },
                        else => {
                            return errors.ImageError.UnsupportedPixelFormat;
                        },
                    }

                    // Read indices
                    try self.readIndexed8(pixels.Bpp8, targa_stream.reader());
                },
                .Rgb555 => {
                    try self.readTruecolor16(pixels.Rgb555, targa_stream.reader());
                },
                .Rgb24 => {
                    try self.readTruecolor24(pixels.Rgb24, targa_stream.reader());
                },
                .Rgba32 => {
                    try self.readTruecolor32(pixels.Rgba32, targa_stream.reader());
                },
                else => {
                    return errors.ImageError.UnsupportedPixelFormat;
                },
            }
        } else {
            return errors.ImageError.AllocationFailed;
        }
    }

    fn readGrayscale8(self: *Self, data: []color.Grayscale8, stream: TargaStream.Reader) !void {
        var dataIndex: usize = 0;
        const dataEnd: usize = self.width() * self.height();

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data[dataIndex] = color.Grayscale8{ .value = try stream.readByte() };
        }
    }

    fn readIndexed8(self: *Self, data: color.IndexedStorage8, stream: TargaStream.Reader) !void {
        var dataIndex: usize = 0;
        const dataEnd: usize = self.width() * self.height();

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data.indices[dataIndex] = try stream.readByte();
        }
    }

    fn readColorMap16(self: *Self, data: color.IndexedStorage8, stream: TargaStream.Reader) !void {
        var dataIndex: usize = self.header.first_entry_index;
        const dataEnd: usize = self.header.first_entry_index + self.header.color_map_length;

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            const raw_color = try stream.readIntLittle(u16);

            data.palette[dataIndex].R = color.toColorFloat(@intCast(u5, (raw_color >> (5 * 2)) & 0x1F));
            data.palette[dataIndex].G = color.toColorFloat(@intCast(u5, (raw_color >> 5) & 0x1F));
            data.palette[dataIndex].B = color.toColorFloat(@intCast(u5, raw_color & 0x1F));
            data.palette[dataIndex].A = 1.0;
        }
    }

    fn readTruecolor16(self: *Self, data: []color.Rgb555, stream: TargaStream.Reader) !void {
        var dataIndex: usize = 0;
        const dataEnd: usize = self.width() * self.height();

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            const raw_color = try stream.readIntLittle(u16);

            data[dataIndex].R = @intCast(u5, (raw_color >> (5 * 2)) & 0x1F);
            data[dataIndex].G = @intCast(u5, (raw_color >> 5) & 0x1F);
            data[dataIndex].B = @intCast(u5, raw_color & 0x1F);
        }
    }

    fn readTruecolor24(self: *Self, data: []color.Rgb24, stream: TargaStream.Reader) !void {
        var dataIndex: usize = 0;
        const dataEnd: usize = self.width() * self.height();

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data[dataIndex].B = try stream.readByte();
            data[dataIndex].G = try stream.readByte();
            data[dataIndex].R = try stream.readByte();
        }
    }

    fn readTruecolor32(self: *Self, data: []color.Rgba32, stream: TargaStream.Reader) !void {
        var dataIndex: usize = 0;
        const dataEnd: usize = self.width() * self.height();

        while (dataIndex < dataEnd) : (dataIndex += 1) {
            data[dataIndex].B = try stream.readByte();
            data[dataIndex].G = try stream.readByte();
            data[dataIndex].R = try stream.readByte();
            data[dataIndex].A = try stream.readByte();

            if (self.extension) |extended_info| {
                if (extended_info.attributes != TGAAttributeType.UsefulAlphaChannel) {
                    data[dataIndex].A = 0xFF;
                }
            }
        }
    }
};
