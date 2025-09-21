// Implement PNG image format according to W3C Portable Network Graphics (PNG) specification second edition (ISO/IEC 15948:2003 (E))
// Last version: https://www.w3.org/TR/PNG/

const ChunkWriter = @import("png/ChunkWriter.zig");
const color = @import("../color.zig");
const filter = @import("png/filtering.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const reader = @import("png/reader.zig");
const std = @import("std");
const types = @import("png/types.zig");
const deflate = @import("../compressions/deflate.zig");

pub const ChunkHeader = types.ChunkHeader;
pub const ChunkProcessData = reader.ChunkProcessData;
pub const Chunks = types.Chunks;
pub const ColorType = types.ColorType;
pub const CompressionMethod = types.CompressionMethod;
pub const CustomReaderOptions1 = reader.CustomReaderOptions1;
pub const CustomReaderOptions2 = reader.CustomReaderOptions2;
pub const DefaultOptions = reader.DefaultOptions;
pub const FilterMethod = types.FilterMethod;
pub const FilterType = types.FilterType;
pub const HeaderData = types.HeaderData;
pub const InfoProcessor = @import("png/InfoProcessor.zig");
pub const InterlaceMethod = types.InterlaceMethod;
pub const isChunkCritical = reader.isChunkCritical;
pub const load = reader.load;
pub const loadHeader = reader.loadHeader;
pub const loadWithHeader = reader.loadWithHeader;
pub const magic_header = types.magic_header;
pub const PaletteProcessData = reader.PaletteProcessData;
pub const PlteProcessor = reader.PlteProcessor;
pub const ReaderOptions = reader.ReaderOptions;
pub const ReaderProcessor = reader.ReaderProcessor;
pub const RowProcessData = reader.RowProcessData;
pub const TrnsProcessor = reader.TrnsProcessor;

pub const PNG = struct {
    const Self = @This();

    pub const EncoderOptions = struct {
        // For progressive rendering of big images
        interlaced: bool = false,
        // Changing this can affect performance positively or negatively
        filter_choice: filter.FilterChoice = .heuristic,
        // Compression cache buffer size that will allocated using the allocator passed to write()
        compression_buffer_size: usize = io.DEFAULT_BUFFER_SIZE,
        // Max cache size when writing a chunk, allocated using the allocator passed to write()
        chunk_writer_buffer_size: usize = 1 << 14, // 16 Kb
    };

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        const stream_reader = read_stream.reader();

        const magic_buffer = try stream_reader.peek(types.magic_header.len);

        return std.mem.eql(u8, magic_buffer[0..], types.magic_header[0..]);
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var options = DefaultOptions.init(.{});
        return load(read_stream, allocator, options.get());
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        const options = encoder_options.png;

        try ensureWritable(image);

        const header = HeaderData{
            .width = @truncate(image.width),
            .height = @truncate(image.height),
            .bit_depth = image.pixelFormat().bitsPerChannel(),
            .color_type = try types.ColorType.fromPixelFormat(image.pixelFormat()),
            .compression_method = .deflate,
            .filter_method = .adaptive,
            .interlace_method = if (options.interlaced) .adam7 else .none,
        };

        std.debug.assert(header.isValid());

        try write(allocator, write_stream, image.pixels, header, options);
    }

    pub fn write(allocator: std.mem.Allocator, write_stream: *io.WriteStream, pixels: color.PixelStorage, header: HeaderData, encoder_options: EncoderOptions) Image.WriteError!void {
        if (header.interlace_method != .none) {
            return Image.WriteError.Unsupported;
        }
        if (header.compression_method != .deflate) {
            return Image.WriteError.Unsupported;
        }
        if (header.filter_method != .adaptive) {
            return Image.WriteError.Unsupported;
        }

        var png_writer: PngWriter = try .init(allocator, write_stream.writer(), encoder_options.chunk_writer_buffer_size, encoder_options.compression_buffer_size);
        defer png_writer.deinit(allocator);

        try png_writer.writeSignature();
        try png_writer.writeHeader(header);

        if (PixelFormat.isIndexed(pixels)) {
            try png_writer.writePalette(pixels);
        }
        // Write tRNS chunk if the pixel format can support it
        try png_writer.writeTransparencyInfo(pixels);

        try png_writer.writeData(allocator, pixels, header, encoder_options.filter_choice);
        try png_writer.writeTrailer();

        try write_stream.flush();
    }

    pub fn ensureWritable(image: Image) !void {
        if (image.width > std.math.maxInt(u31))
            return error.Unsupported;
        if (image.height > std.math.maxInt(u31))
            return error.Unsupported;

        switch (image.pixels) {
            .indexed1,
            .indexed2,
            .indexed4,
            .indexed8,
            .grayscale1,
            .grayscale2,
            .grayscale4,
            .grayscale8,
            .grayscale16,
            .grayscale8Alpha,
            .grayscale16Alpha,
            .rgb24,
            .rgb48,
            .rgba32,
            .rgba64,
            => {},
            // TODO: Support other formats when the write options ask for conversion.
            else => return error.Unsupported,
        }
    }
};

const PngWriter = struct {
    chunk_buffer: []u8 = &.{},
    compression_buffer: []u8 = &.{},
    writer: *std.Io.Writer = undefined,

    pub fn init(allocator: std.mem.Allocator, writer: *std.Io.Writer, chunk_buffer_size: usize, compression_buffer_size: usize) !PngWriter {
        return .{
            .writer = writer,
            .chunk_buffer = try allocator.alloc(u8, chunk_buffer_size),
            .compression_buffer = try allocator.alloc(u8, compression_buffer_size),
        };
    }

    pub fn deinit(self: *PngWriter, allocator: std.mem.Allocator) void {
        allocator.free(self.chunk_buffer);
        allocator.free(self.compression_buffer);
    }

    pub fn writeSignature(self: *PngWriter) !void {
        try self.writer.writeAll(types.magic_header);
    }

    // IHDR chunk
    pub fn writeHeader(self: *PngWriter, header: HeaderData) Image.WriteError!void {
        var chunk_writer: ChunkWriter = .init(self.writer, self.chunk_buffer, Chunks.IHDR);
        var writer = &chunk_writer.writer;

        try writer.writeInt(u32, header.width, .big);
        try writer.writeInt(u32, header.height, .big);
        try writer.writeInt(u8, header.bit_depth, .big);
        try writer.writeInt(u8, @intFromEnum(header.color_type), .big);
        try writer.writeInt(u8, @intFromEnum(header.compression_method), .big);
        try writer.writeInt(u8, @intFromEnum(header.filter_method), .big);
        try writer.writeInt(u8, @intFromEnum(header.interlace_method), .big);

        try writer.flush();
    }

    // PLTE chunk
    pub fn writePalette(self: *PngWriter, pixels: color.PixelStorage) Image.WriteError!void {
        var chunk_writer: ChunkWriter = .init(self.writer, self.chunk_buffer, Chunks.PLTE);
        var writer = &chunk_writer.writer;

        const palette = switch (pixels) {
            .indexed1 => |d| d.palette,
            .indexed2 => |d| d.palette,
            .indexed4 => |d| d.palette,
            .indexed8 => |d| d.palette,
            .indexed16 => return Image.WriteError.Unsupported,
            else => unreachable,
        };

        for (palette) |col| {
            try writer.writeByte(col.r);
            try writer.writeByte(col.g);
            try writer.writeByte(col.b);
        }

        try writer.flush();
    }

    // tRNS (Transparency information)
    pub fn writeTransparencyInfo(self: *PngWriter, pixels: color.PixelStorage) Image.WriteError!void {
        // TODO: For pixel format with alpha, try to check if the pixel with alpha are all the same color, if yes, we can change the format to their non-alpha counterpart with a tRNS chunk
        // TODO: For pixel format without alpha, add a write option to force which color should be consider transparent

        const TrnsIndexedWriter = struct {
            pub fn write(source_writer: *std.Io.Writer, chunk_buffer: []u8, indexed: anytype) Image.WriteError!void {
                var write_trns: bool = false;

                for (indexed.palette) |entry| {
                    if (entry.a < std.math.maxInt(u8)) {
                        write_trns = true;
                        break;
                    }
                }

                if (!write_trns) {
                    return;
                }

                var chunk_writer: ChunkWriter = .init(source_writer, chunk_buffer, Chunks.tRNS);
                var writer = &chunk_writer.writer;

                for (indexed.palette) |col| {
                    try writer.writeByte(col.a);
                }

                try writer.flush();
            }
        };

        switch (pixels) {
            .indexed1 => |indexed| {
                return TrnsIndexedWriter.write(self.writer, self.chunk_buffer, indexed);
            },
            .indexed2 => |indexed| {
                return TrnsIndexedWriter.write(self.writer, self.chunk_buffer, indexed);
            },
            .indexed4 => |indexed| {
                return TrnsIndexedWriter.write(self.writer, self.chunk_buffer, indexed);
            },
            .indexed8 => |indexed| {
                return TrnsIndexedWriter.write(self.writer, self.chunk_buffer, indexed);
            },
            .indexed16 => {
                return Image.WriteError.Unsupported;
            },
            else => {
                // Do nothing
            },
        }
    }

    // IDAT chunks
    pub fn writeData(self: *PngWriter, allocator: std.mem.Allocator, pixels: color.PixelStorage, header: HeaderData, filter_choice: filter.FilterChoice) Image.WriteError!void {
        // Note: there may be more than 1 chunk
        // TODO: provide choice of how much it buffers (how much data per idat chunk)
        var chunk_writer: ChunkWriter = .init(self.writer, self.chunk_buffer, Chunks.IDAT);
        const writer = &chunk_writer.writer;

        var zlib_compressor = try deflate.compressor(.zlib, writer, self.compression_buffer, .{ .level = .default });
        try filter.filter(allocator, &zlib_compressor.writer, pixels, filter_choice, header);
        try zlib_compressor.writer.flush();

        try writer.flush();
    }

    // IEND chunk
    fn writeTrailer(self: *PngWriter) Image.WriteError!void {
        var chunk_writer = ChunkWriter.init(self.writer, self.chunk_buffer, Chunks.IEND);
        var writer = &chunk_writer.writer;
        try writer.flush();
    }
};

test {
    _ = @import("png/reader.zig");
}
