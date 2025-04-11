const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const ImageReadError = ImageUnmanaged.ReadError;
const ImageError = ImageUnmanaged.Error;
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

const Header = extern struct {
    const size = 6;

    version: u16 align(1),
    idf_offset: u32 align(1),

    const little_endian_magic = "II";
    const big_endian_magic = "MM";

    comptime {
        std.debug.assert(@sizeOf(Header) == Header.size);
    }
};

const Tag = struct {
    const size = 12;

    tag_id: u16 align(1),
    data_type: u16 align(1),
    data_count: u32 align(1),
    data_offset: u32 align(1),

    comptime {
        std.debug.assert(@sizeOf(Tag) == Tag.size);
    }
};

const IFD = struct {
    num_dir_entries: u16,
    tag_list: []Tag,
    next_idf_offset: u32,
};

pub const TIFF = struct {
    endianess: std.builtin.Endian = undefined,
    header: Header = undefined,

    pub fn width(_: *TIFF) usize {
        return 0;
    }

    pub fn height(_: *TIFF) usize {
        return 0;
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn read(self: *TIFF, stream: *ImageUnmanaged.Stream, allocator: std.mem.Allocator) ImageUnmanaged.ReadError!color.PixelStorage {
        _ = allocator;

        self.endianess = try endianessDetect(stream);

        const reader = stream.reader();

        utils.readStruct(reader, Header, self.endianess) catch return ImageReadError.InvalidData;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        _ = stream;

        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    fn endianessDetect(stream: *ImageUnmanaged.Stream) !std.builtin.Endian {
        var magic_buffer: [Header.little_endian_magic.len]u8 = undefined;

        _ = try stream.read(magic_buffer[0..]);

        if (std.mem.eql(u8, magic_buffer[0..], Header.little_endian_magic[0..])) {
            return std.builtin.Endian.little;
        } else if (std.mem.eql(u8, magic_buffer[0..], Header.big_endian_magic[0..])) {
            return std.builtin.Endian.big;
        }

        return ImageReadError.Unsupported;
    }

    pub fn formatDetect(stream: *ImageUnmanaged.Stream) !bool {
        _ = try endianessDetect(stream);

        return true;
    }
};
