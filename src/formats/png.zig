// Implement PNG image format according to W3C Portable Network Graphics (PNG) specification second edition (ISO/IEC 15948:2003 (E))
// Last version: https://www.w3.org/TR/PNG/

const std = @import("std");
const types = @import("png/types.zig");
const reader = @import("png/reader.zig");
const crc = @import("png/crc.zig");
const chunk_writer = @import("png/chunk_writer.zig");
const filter = @import("png/filtering.zig");
const color = @import("../color.zig");
const ZlibCompressor = @import("png/zlib_compressor.zig").ZlibCompressor;
const Image = @import("../Image.zig");
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const ImageReadError = Image.ReadError;
const ImageWriteError = Image.WriteError;
const Allocator = std.mem.Allocator;

pub const HeaderData = types.HeaderData;
pub const ColorType = types.ColorType;
pub const CompressionMethod = types.CompressionMethod;
pub const FilterMethod = types.FilterMethod;
pub const FilterType = types.FilterType;
pub const InterlaceMethod = types.InterlaceMethod;
pub const Chunks = types.Chunks;
pub const isChunkCritical = reader.isChunkCritical;
pub const load = reader.load;
pub const loadHeader = reader.loadHeader;
pub const loadWithHeader = reader.loadWithHeader;
pub const ChunkProcessData = reader.ChunkProcessData;
pub const PaletteProcessData = reader.PaletteProcessData;
pub const RowProcessData = reader.RowProcessData;
pub const ReaderProcessor = reader.ReaderProcessor;
pub const TrnsProcessor = reader.TrnsProcessor;
pub const PlteProcessor = reader.PlteProcessor;
pub const ReaderOptions = reader.ReaderOptions;
pub const DefaultProcessors = reader.DefaultProcessors;
pub const DefaultOptions = reader.DefaultOptions;
pub const required_temp_bytes = reader.required_temp_bytes;

pub const PNG = struct {
    const Self = @This();

    pub const EncoderOptions = struct {
        // For progressive rendering of big images
        interlaced: bool = false,
        // Changing this can affect performance positively or negatively 
        filter_choice: filter.FilterChoice = .Heuristic,
    };

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() Image.Format {
        return Image.Format.png;
    }

    pub fn formatDetect(stream: *Image.Stream) ImageReadError!bool {
        var magic_buffer: [types.magic_header.len]u8 = undefined;

        _ = try stream.reader().readAll(magic_buffer[0..]);

        return std.mem.eql(u8, magic_buffer[0..], types.magic_header[0..]);
    }

    pub fn readImage(allocator: Allocator, stream: *Image.Stream) ImageReadError!Image {
        var default_options = DefaultOptions{};
        return load(stream, allocator, default_options.get());
    }

    pub fn writeImage(allocator: Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) ImageWriteError!void {
        const options = encoder_options.png;
        
        var writer = write_stream.writer();

        try writeSignature(writer);
        try writeHeader(writer, image, options);
        if (image.pixelFormat().isIndex()) {
            try writePalette(writer, image);
            try writeTransparencyInfo(writer, image); // TODO: pixel format where there is no transparency
        }
        try writeData(allocator, writer, image, options);
        try writeTrailer(writer);
    }

    fn writeSignature(writer: anytype) !void {
        try writer.writeAll("\x89\x50\x4E\x47\x0D\x0A\x1A\x0A");
    }

    // IHDR
    fn writeHeader(writer: anytype, image: Image, encoder_options: EncoderOptions) ImageWriteError!void {
        // TODO: interlaced png files
        if (encoder_options.interlaced)
            return ImageWriteError.Unsupported;

        // Color type byte
        const color_type: u8 = switch (image.pixels) {
            .rgb24,
            .rgb48 => 2,

            .rgba32,
            .rgba64 => 6,

            .grayscale1,
            .grayscale2,
            .grayscale4,
            .grayscale8,
            .grayscale16 => 0,

            .grayscale8Alpha,
            .grayscale16Alpha =>  4,

            .indexed1,
            .indexed2,
            .indexed4,
            .indexed8 => 3,
            // TODO: indexed without alpha
            else => return ImageWriteError.Unsupported,
        };

        // Bits per sample layer
        const bps: u8 = image.pixelFormat().bitsPerChannel();

        var chunk = chunk_writer.chunkWriter(writer, "IHDR");
        var chunk_wr = chunk.writer();

        try chunk_wr.writeIntBig(u32, @truncate(u32, image.width));
        try chunk_wr.writeIntBig(u32, @truncate(u32, image.height));
        try chunk_wr.writeIntBig(u8, bps);
        try chunk_wr.writeIntBig(u8, color_type);
        try chunk_wr.writeIntBig(u8, 0); // default compression (only standard)
        try chunk_wr.writeIntBig(u8, 0); // default filter (only standard)
        try chunk_wr.writeIntBig(u8, @boolToInt(encoder_options.interlaced));

        try chunk.flush();
    }

    // IDAT (multiple maybe)
    fn writeData(allocator: Allocator, writer: anytype, image: Image, encoder_options: EncoderOptions) ImageWriteError!void {
        // Note: there may be more than 1 chunk
        // TODO: provide choice of how much it buffers (how much data per idat chunk)
        var chunks = chunk_writer.chunkWriter(writer, "IDAT");
        var chunk_wr = chunks.writer();

        var zlib: ZlibCompressor(@TypeOf(chunk_wr)) = undefined;
        try zlib.init(allocator, chunk_wr);

        try zlib.begin();
        try filter.filter(allocator, zlib.writer(), image, encoder_options.filter_choice);
        try zlib.end();

        try chunks.flush();
    }

    // IEND chunk
    fn writeTrailer(writer: anytype) ImageWriteError!void {
        var chunk = chunk_writer.chunkWriter(writer, "IEND");
        try chunk.flush();
    }

    // PLTE (if indexed storage)
    fn writePalette(writer: anytype, image: Image) ImageWriteError!void {
        var chunk = chunk_writer.chunkWriter(writer, "PLTE");
        var chunk_wr = chunk.writer();

        const palette = switch (image.pixels) {
            .indexed1 => |d| d.palette,
            .indexed2 => |d| d.palette,
            .indexed4 => |d| d.palette,
            .indexed8 => |d| d.palette,
            .indexed16 => return ImageWriteError.Unsupported,
            else => unreachable,
        };

        for (palette) |col| {
            try chunk_wr.writeByte(col.r);
            try chunk_wr.writeByte(col.g);
            try chunk_wr.writeByte(col.b);
        }

        try chunk.flush();
    }

    // tRNS (if indexed storage with transparency (there may be other uses later))
    fn writeTransparencyInfo(writer: anytype, image: Image) ImageWriteError!void {
        var chunk = chunk_writer.chunkWriter(writer, "tRNS");
        var chunk_wr = chunk.writer();

        const palette = switch (image.pixels) {
            .indexed1 => |d| d.palette,
            .indexed2 => |d| d.palette,
            .indexed4 => |d| d.palette,
            .indexed8 => |d| d.palette,
            .indexed16 => return ImageWriteError.Unsupported,
            // TODO: png support transparency info for other formats?
            else => unreachable,
        };

        for (palette) |col| {
            try chunk_wr.writeByte(col.a);
        }

        try chunk.flush();
    }
};
