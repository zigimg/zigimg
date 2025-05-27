const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../../buffered_stream_source.zig");
const color = @import("../../color.zig");
const Crc32 = std.hash.Crc32;
const File = std.fs.File;
const ImageUnmanaged = @import("../../ImageUnmanaged.zig");
const mem = std.mem;
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const PixelStorage = color.PixelStorage;
const png = @import("types.zig");
const std = @import("std");
const utils = @import("../../utils.zig");

// Png specification: http://www.libpng.org/pub/png/spec/iso/index-object.html

// mlarouche: Enable this to step into the processors with a debugger
const PNG_DEBUG = false;

pub fn isChunkCritical(id: u32) bool {
    return (id & 0x20000000) == 0;
}

fn callChunkProcessors(processors: []ReaderProcessor, chunk_process_data: *ChunkProcessData) ImageUnmanaged.ReadError!void {
    const id = chunk_process_data.chunk_id;
    // Critical chunks are already processed but we can still notify any number of processors about them
    var processed = isChunkCritical(id);
    for (processors) |*processor| {
        if (processor.id == id or processor.id == png.Chunks.Any.id) {
            const new_format = try processor.processChunk(chunk_process_data);
            std.debug.assert(new_format.pixelStride() >= chunk_process_data.current_format.pixelStride());
            chunk_process_data.current_format = new_format;
            if (!processed) {
                // For non critical chunks we only allow one processor so we break after the first one
                processed = true;
                break;
            }
        }
    }

    // If noone loaded this chunk we need to skip over it
    if (!processed) {
        try chunk_process_data.stream.seekBy(@intCast(chunk_process_data.chunk_length + 4));
    }
}

// Provides reader interface for Zlib stream that knows to read consecutive IDAT chunks.
// The way Zlib is currently implemented it very often reads a byte at a time which is
// slow so we also provide buffering here. We can't used BufferedReader because we need
// more control than it currently provides.
const IDatChunksReader = struct {
    stream: *buffered_stream_source.DefaultBufferedStreamSourceReader,
    buffer: [4096]u8 = undefined,
    data: []u8,
    processors: []ReaderProcessor,
    chunk_process_data: *ChunkProcessData,
    remaining_chunk_length: u32,
    crc: Crc32,

    const Self = @This();

    fn init(
        stream: *buffered_stream_source.DefaultBufferedStreamSourceReader,
        processors: []ReaderProcessor,
        chunk_process_data: *ChunkProcessData,
    ) Self {
        var crc = Crc32.init();
        crc.update(png.Chunks.IDAT.name);
        return .{
            .stream = stream,
            .data = &[_]u8{},
            .processors = processors,
            .chunk_process_data = chunk_process_data,
            .remaining_chunk_length = chunk_process_data.chunk_length,
            .crc = crc,
        };
    }

    fn fillBuffer(self: *Self, to_read: usize) ImageUnmanaged.ReadError!usize {
        mem.copyForwards(u8, self.buffer[0..self.data.len], self.data);
        const new_start = self.data.len;
        var max = self.buffer.len;
        if (max > self.remaining_chunk_length) {
            max = self.remaining_chunk_length;
        }
        const len = try self.stream.read(self.buffer[new_start..max]);
        self.data = self.buffer[0 .. new_start + len];
        self.crc.update(self.data[new_start..]);
        return if (len < to_read) len else to_read;
    }

    fn read(self: *Self, dest: []u8) ImageUnmanaged.ReadError!usize {
        if (self.remaining_chunk_length == 0) return 0;
        const new_dest = dest;

        var reader = self.stream.reader();
        var to_read = new_dest.len;
        if (to_read > self.remaining_chunk_length) {
            to_read = self.remaining_chunk_length;
        }
        if (to_read > self.data.len) {
            to_read = try self.fillBuffer(to_read);
        }
        @memcpy(new_dest[0..to_read], self.data[0..to_read]);
        self.remaining_chunk_length -= @intCast(to_read);
        self.data = self.data[to_read..];

        if (self.remaining_chunk_length == 0) {
            // First read and check CRC of just finished chunk
            const expected_crc = try reader.readInt(u32, .big);
            const actual_crc = self.crc.final();
            if (actual_crc != expected_crc) {
                return ImageUnmanaged.ReadError.InvalidData;
            }

            try callChunkProcessors(self.processors, self.chunk_process_data);

            self.crc = Crc32.init();
            self.crc.update(png.Chunks.IDAT.name);

            // Try to load the next IDAT chunk
            const chunk = try utils.readStruct(reader, png.ChunkHeader, .big);
            if (chunk.type == png.Chunks.IDAT.id) {
                self.remaining_chunk_length = chunk.length;
            } else {
                // Return to the start of the next chunk so code in main struct can read it
                try self.stream.seekBy(-@sizeOf(png.ChunkHeader));
            }
        }

        return to_read;
    }
};

const IDATReader = std.io.Reader(*IDatChunksReader, ImageUnmanaged.ReadError, IDatChunksReader.read);

/// Loads only the png header from the stream. Useful when you only metadata.
pub fn loadHeader(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!png.HeaderData {
    var reader = stream.reader();
    var signature: [png.magic_header.len]u8 = undefined;
    try reader.readNoEof(signature[0..]);
    if (!mem.eql(u8, signature[0..], png.magic_header)) {
        return ImageUnmanaged.ReadError.InvalidData;
    }

    const chunk = try utils.readStruct(reader, png.ChunkHeader, .big);
    if (chunk.type != png.Chunks.IHDR.id) return ImageUnmanaged.ReadError.InvalidData;
    if (chunk.length != @sizeOf(png.HeaderData)) return ImageUnmanaged.ReadError.InvalidData;

    var header_data: [@sizeOf(png.HeaderData)]u8 = undefined;
    try reader.readNoEof(&header_data);

    var struct_stream = std.io.fixedBufferStream(&header_data);

    const header = try utils.readStruct(struct_stream.reader(), png.HeaderData, .big);
    if (!header.isValid()) return ImageUnmanaged.ReadError.InvalidData;

    const expected_crc = try reader.readInt(u32, .big);
    var crc = Crc32.init();
    crc.update(png.Chunks.IHDR.name);
    crc.update(&header_data);
    const actual_crc = crc.final();
    if (expected_crc != actual_crc) return ImageUnmanaged.ReadError.InvalidData;

    return header;
}

/// Loads the png image using the given allocator and options.
/// The options allow you to pass in a custom allocator for temporary allocations.
/// By default it will also use the main allocator for temporary allocations.
/// You can also pass in an optional array of chunk processors. Provided processors are:
/// 1. tRNS processor that decodes the tRNS chunk if it exists into an alpha channel
/// 2. PLTE processor that decodes the indexed image with a palette into a RGB image.
/// If you pass DefaultOptions.init(.{}) it will only use the tRNS processor.
pub fn load(stream: *ImageUnmanaged.Stream, allocator: Allocator, options: ReaderOptions) ImageUnmanaged.ReadError!ImageUnmanaged {
    const header = try loadHeader(stream);
    var result = ImageUnmanaged{};
    errdefer result.deinit(allocator);

    result.width = header.width;
    result.height = header.height;
    result.pixels = try loadWithHeader(stream, &header, allocator, options);

    return result;
}

/// Loads the png image for which the header has already been loaded.
/// For options param description look at the load method docs.
pub fn loadWithHeader(
    stream: *ImageUnmanaged.Stream,
    header: *const png.HeaderData,
    allocator: Allocator,
    in_options: ReaderOptions,
) ImageUnmanaged.ReadError!PixelStorage {
    var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
    var options = in_options;
    var temp_allocator = options.temp_allocator;
    if (temp_allocator.vtable == &NoopAllocator) {
        temp_allocator = allocator;
    }

    var arena_allocator = std.heap.ArenaAllocator.init(temp_allocator);
    defer arena_allocator.deinit();
    options.temp_allocator = arena_allocator.allocator();

    var palette: []color.Rgb24 = &[_]color.Rgb24{};
    var data_found = false;
    var result: PixelStorage = undefined;

    var chunk_process_data = ChunkProcessData{
        .stream = &buffered_stream,
        .chunk_id = png.Chunks.IHDR.id,
        .chunk_length = @sizeOf(png.HeaderData),
        .current_format = header.getPixelFormat(),
        .header = header,
        .temp_allocator = options.temp_allocator,
    };
    try callChunkProcessors(options.processors, &chunk_process_data);

    var reader = buffered_stream.reader();

    while (true) {
        const chunk = (try utils.readStruct(reader, png.ChunkHeader, .big));
        chunk_process_data.chunk_id = chunk.type;
        chunk_process_data.chunk_length = chunk.length;

        switch (chunk.type) {
            png.Chunks.IHDR.id => {
                return ImageUnmanaged.ReadError.InvalidData; // We already processed IHDR so another one is an error
            },
            png.Chunks.IEND.id => {
                if (!data_found) return ImageUnmanaged.ReadError.InvalidData;
                _ = try reader.readInt(u32, .big); // Read and ignore the crc
                try callChunkProcessors(options.processors, &chunk_process_data);
                return result;
            },
            png.Chunks.IDAT.id => {
                if (data_found) return ImageUnmanaged.ReadError.InvalidData;
                if (header.color_type == .indexed and palette.len == 0) {
                    return ImageUnmanaged.ReadError.InvalidData;
                }
                result = try readAllData(&buffered_stream, header, palette, allocator, &options, &chunk_process_data);
                data_found = true;
            },
            png.Chunks.PLTE.id => {
                if (!header.allowsPalette()) return ImageUnmanaged.ReadError.InvalidData;
                if (palette.len > 0) return ImageUnmanaged.ReadError.InvalidData;
                // We ignore if tRNS is already found
                if (data_found) {
                    // If IDAT was already processed we skip and ignore this palette
                    try buffered_stream.seekBy(chunk.length + @sizeOf(u32));
                } else {
                    if (chunk.length % 3 != 0) return ImageUnmanaged.ReadError.InvalidData;
                    const palette_entries = chunk.length / 3;
                    if (palette_entries > header.maxPaletteSize()) {
                        return ImageUnmanaged.ReadError.InvalidData;
                    }
                    palette = try options.temp_allocator.alloc(color.Rgb24, palette_entries);
                    const palette_bytes = mem.sliceAsBytes(palette);
                    try reader.readNoEof(palette_bytes);

                    const expected_crc = try reader.readInt(u32, .big);
                    var crc = Crc32.init();
                    crc.update(png.Chunks.PLTE.name);
                    crc.update(palette_bytes);
                    const actual_crc = crc.final();
                    if (expected_crc != actual_crc) return ImageUnmanaged.ReadError.InvalidData;
                    try callChunkProcessors(options.processors, &chunk_process_data);
                }
            },
            else => {
                try callChunkProcessors(options.processors, &chunk_process_data);
            },
        }
    }
}

fn readAllData(
    buffered_stream: *buffered_stream_source.DefaultBufferedStreamSourceReader,
    header: *const png.HeaderData,
    palette: []color.Rgb24,
    allocator: Allocator,
    options: *const ReaderOptions,
    chunk_process_data: *ChunkProcessData,
) ImageUnmanaged.ReadError!PixelStorage {
    const native_endian = comptime @import("builtin").cpu.arch.endian();
    const is_little_endian = native_endian == .little;
    const width = header.width;
    const height = header.height;
    const channel_count = header.channelCount();
    const dest_format = chunk_process_data.current_format;
    var result = try PixelStorage.init(allocator, dest_format, width * height);
    errdefer result.deinit(allocator);
    var idat_chunks_reader = IDatChunksReader.init(buffered_stream, options.processors, chunk_process_data);
    const idat_reader: IDATReader = .{ .context = &idat_chunks_reader };
    var decompress_stream = std.compress.zlib.decompressor(idat_reader);

    if (palette.len > 0) {
        var destination_palette = blk: {
            if (result.isIndexed()) {
                result.resizePalette(palette.len);

                if (result.getPalette()) |result_palette| {
                    break :blk result_palette;
                }
            }

            break :blk try options.temp_allocator.alloc(color.Rgba32, palette.len);
        };

        for (palette, 0..) |entry, n| {
            destination_palette[n] = color.Rgba32.initRgb(entry.r, entry.g, entry.b);
        }

        try callPaletteProcessors(options, destination_palette);
    }

    var destination = result.asBytes();

    // For defiltering we need to keep two rows in memory so we allocate space for that
    const filter_stride = (header.bit_depth + 7) / 8 * channel_count; // 1 to 8 bytes
    const line_bytes = header.lineBytes();
    const virtual_line_bytes = line_bytes + filter_stride;
    const result_line_bytes: u32 = @intCast(destination.len / height);
    var tmpbytes = 2 * virtual_line_bytes;
    // For deinterlacing we also need one additional temporary row of resulting pixels
    if (header.interlace_method == .adam7) {
        tmpbytes += result_line_bytes;
    }
    var temp_allocator = if (tmpbytes < 128 * 1024) options.temp_allocator else allocator;
    var tmp_buffer = try temp_allocator.alloc(u8, tmpbytes);
    defer temp_allocator.free(tmp_buffer);
    @memset(tmp_buffer, 0);
    var prev_row = tmp_buffer[0..virtual_line_bytes];
    var current_row = tmp_buffer[virtual_line_bytes .. 2 * virtual_line_bytes];
    const pixel_stride: u8 = @intCast(result_line_bytes / width);
    std.debug.assert(pixel_stride == dest_format.pixelStride());

    var process_row_data = RowProcessData{
        .dest_row = undefined,
        .src_format = header.getPixelFormat(),
        .dest_format = dest_format,
        .header = header,
        .temp_allocator = options.temp_allocator,
    };

    var decompress_reader = decompress_stream.reader();

    if (header.interlace_method == .none) {
        var i: u32 = 0;
        while (i < height) : (i += 1) {
            decompress_reader.readNoEof(current_row[filter_stride - 1 ..]) catch |err| switch (err) {
                error.BadGzipHeader, error.BadZlibHeader, error.WrongGzipChecksum, error.WrongGzipSize, error.WrongZlibChecksum, error.InvalidCode, error.IncompleteHuffmanTree, error.MissingEndOfBlockCode, error.InvalidMatch, error.InvalidBlockType, error.OversubscribedHuffmanTree, error.WrongStoredBlockNlen, error.InvalidDynamicBlockHeader => return ImageUnmanaged.ReadError.InvalidData,
                else => |leftover_err| return leftover_err,
            };
            try defilter(current_row, prev_row, filter_stride);

            process_row_data.dest_row = destination[0..result_line_bytes];
            destination = destination[result_line_bytes..];

            // Spreads the data into a destination format pixel stride so that all callRowProcessors methods can work in place
            spreadRowData(
                process_row_data.dest_row,
                current_row[filter_stride..],
                header.bit_depth,
                channel_count,
                pixel_stride,
                is_little_endian,
            );

            const result_format = try callRowProcessors(options.processors, &process_row_data);
            if (result_format != dest_format) return ImageUnmanaged.ReadError.InvalidData;

            const tmp = prev_row;
            prev_row = current_row;
            current_row = tmp;
        }
    } else {
        const start_x = [7]u8{ 0, 4, 0, 2, 0, 1, 0 };
        const start_y = [7]u8{ 0, 0, 4, 0, 2, 0, 1 };
        const xinc = [7]u8{ 8, 8, 4, 4, 2, 2, 1 };
        const yinc = [7]u8{ 8, 8, 8, 4, 4, 2, 2 };
        const pass_width = [7]u32{
            (width + 7) / 8,
            (width + 3) / 8,
            (width + 3) / 4,
            (width + 1) / 4,
            (width + 1) / 2,
            width / 2,
            width,
        };
        const pass_height = [7]u32{
            (height + 7) / 8,
            (height + 7) / 8,
            (height + 3) / 8,
            (height + 3) / 4,
            (height + 1) / 4,
            (height + 1) / 2,
            height / 2,
        };
        const pixel_bits = header.pixelBits();
        const deinterlace_bit_depth: u8 = if (header.bit_depth <= 8) 8 else 16;
        var dest_row = tmp_buffer[virtual_line_bytes * 2 ..];

        var pass: u32 = 0;
        while (pass < 7) : (pass += 1) {
            if (pass_width[pass] == 0 or pass_height[pass] == 0) {
                continue;
            }
            const pass_bytes = (pixel_bits * pass_width[pass] + 7) / 8;
            const pass_length = pass_bytes + filter_stride;
            const result_pass_line_bytes = pixel_stride * pass_width[pass];
            const deinterlace_stride = xinc[pass] * pixel_stride;
            @memset(prev_row, 0);
            const destx = start_x[pass] * pixel_stride;
            var desty = start_y[pass];
            var y: u32 = 0;
            while (y < pass_height[pass]) : (y += 1) {
                decompress_reader.readNoEof(current_row[filter_stride - 1 .. pass_length]) catch |err| switch (err) {
                    error.BadGzipHeader, error.BadZlibHeader, error.WrongGzipChecksum, error.WrongGzipSize, error.WrongZlibChecksum, error.InvalidCode, error.IncompleteHuffmanTree, error.MissingEndOfBlockCode, error.InvalidMatch, error.InvalidBlockType, error.OversubscribedHuffmanTree, error.WrongStoredBlockNlen, error.InvalidDynamicBlockHeader => return ImageUnmanaged.ReadError.InvalidData,
                    else => |leftover_err| return leftover_err,
                };
                try defilter(current_row[0..pass_length], prev_row[0..pass_length], filter_stride);

                process_row_data.dest_row = dest_row[0..result_pass_line_bytes];

                // Spreads the data into a destination format pixel stride so that all callRowProcessors methods can work in place
                spreadRowData(
                    process_row_data.dest_row,
                    current_row[filter_stride..],
                    header.bit_depth,
                    channel_count,
                    pixel_stride,
                    is_little_endian,
                );

                const result_format = try callRowProcessors(options.processors, &process_row_data);
                if (result_format != dest_format) return ImageUnmanaged.ReadError.InvalidData;

                const line_start_index = desty * result_line_bytes;
                const start_byte = line_start_index + destx;
                const end_byte = line_start_index + result_line_bytes;
                // This spread does the actual deinterlacing of the row
                spreadRowData(
                    destination[start_byte..end_byte],
                    process_row_data.dest_row,
                    deinterlace_bit_depth,
                    result_format.channelCount(),
                    deinterlace_stride,
                    false,
                );

                desty += yinc[pass];

                const tmp = prev_row;
                prev_row = current_row;
                current_row = tmp;
            }
        }
    }

    // Just make sure zip stream gets to its end
    var buf: [8]u8 = undefined;
    const shouldBeZero = decompress_stream.read(buf[0..]) catch |err| switch (err) {
        error.BadGzipHeader,
        error.BadZlibHeader,
        error.WrongGzipChecksum,
        error.WrongGzipSize,
        error.WrongZlibChecksum,
        error.InvalidCode,
        error.IncompleteHuffmanTree,
        error.MissingEndOfBlockCode,
        error.InvalidMatch,
        error.InvalidBlockType,
        error.OversubscribedHuffmanTree,
        error.WrongStoredBlockNlen,
        error.InvalidDynamicBlockHeader,
        error.EndOfStream,
        => return ImageUnmanaged.ReadError.InvalidData,
        else => |leftover_err| return leftover_err,
    };

    std.debug.assert(shouldBeZero == 0);

    return result;
}

fn callPaletteProcessors(options: *const ReaderOptions, palette: []color.Rgba32) ImageUnmanaged.ReadError!void {
    var process_data = PaletteProcessData{ .palette = palette, .temp_allocator = options.temp_allocator };
    for (options.processors) |*processor| {
        try processor.processPalette(&process_data);
    }
}

fn defilter(current_row: []u8, prev_row: []u8, filter_stride: u8) ImageUnmanaged.ReadError!void {
    const filter_byte = current_row[filter_stride - 1];
    if (filter_byte > @intFromEnum(png.FilterType.paeth)) {
        return ImageUnmanaged.ReadError.InvalidData;
    }
    const filter: png.FilterType = @enumFromInt(filter_byte);
    current_row[filter_stride - 1] = 0;

    var x: u32 = filter_stride;
    switch (filter) {
        .none => {},
        .sub => while (x < current_row.len) : (x += 1) {
            current_row[x] +%= current_row[x - filter_stride];
        },
        .up => while (x < current_row.len) : (x += 1) {
            current_row[x] +%= prev_row[x];
        },
        .average => while (x < current_row.len) : (x += 1) {
            current_row[x] +%= @truncate((@as(u32, @intCast(current_row[x - filter_stride])) + @as(u32, @intCast(prev_row[x]))) / 2);
        },
        .paeth => while (x < current_row.len) : (x += 1) {
            const a = current_row[x - filter_stride];
            const b = prev_row[x];
            const c = prev_row[x - filter_stride];
            var pa: i32 = @as(i32, @intCast(b)) - c;
            var pb: i32 = @as(i32, @intCast(a)) - c;
            var pc: i32 = pa + pb;
            if (pa < 0) pa = -pa;
            if (pb < 0) pb = -pb;
            if (pc < 0) pc = -pc;
            // zig fmt: off
            current_row[x] +%= if (pa <= pb and pa <= pc) a
                                else if (pb <= pc) b
                                else c;
            // zig fmt: on
        },
    }
}

fn spreadRowData(
    dest_row: []u8,
    current_row: []u8,
    bit_depth: u8,
    channel_count: u8,
    pixel_stride: u8,
    comptime byteswap: bool,
) void {
    var dest_index: u32 = 0;
    var source_index: u32 = 0;
    const result_line_bytes = dest_row.len;
    switch (bit_depth) {
        1, 2, 4 => {
            while (dest_index < result_line_bytes) {
                // color_type must be Grayscale or Indexed
                var shift: i4 = @intCast(8 - bit_depth);
                var mask = @as(u8, 0xff) << @intCast(shift);
                while (shift >= 0 and dest_index < result_line_bytes) : (shift -= @as(i4, @intCast(bit_depth))) {
                    dest_row[dest_index] = (current_row[source_index] & mask) >> @as(u3, @intCast(shift));
                    dest_index += pixel_stride;
                    mask >>= @intCast(bit_depth);
                }
                source_index += 1;
            }
        },
        8 => {
            while (dest_index < result_line_bytes) : (dest_index += pixel_stride) {
                var c: u32 = 0;
                while (c < channel_count) : (c += 1) {
                    dest_row[dest_index + c] = current_row[source_index + c];
                }
                source_index += channel_count;
            }
        },
        16 => {
            const current_row16 = mem.bytesAsSlice(u16, current_row);
            var dest_row16 = mem.bytesAsSlice(u16, dest_row);
            const pixel_stride16 = pixel_stride / 2;
            source_index /= 2;
            while (dest_index < dest_row16.len) : (dest_index += pixel_stride16) {
                var c: u32 = 0;
                while (c < channel_count) : (c += 1) {
                    // This is a comptime if so it is not executed in every loop
                    dest_row16[dest_index + c] = if (byteswap) @byteSwap(current_row16[source_index + c]) else current_row16[source_index + c];
                }
                source_index += channel_count;
            }
        },
        else => unreachable,
    }
}

fn callRowProcessors(processors: []ReaderProcessor, process_data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
    const starting_format = process_data.src_format;
    var result_format = starting_format;
    for (processors) |*processor| {
        result_format = try processor.processDataRow(process_data);
        process_data.src_format = result_format;
    }
    process_data.src_format = starting_format;
    return result_format;
}

pub const ChunkProcessData = struct {
    stream: *buffered_stream_source.DefaultBufferedStreamSourceReader,
    chunk_id: u32,
    chunk_length: u32,
    current_format: PixelFormat,
    header: *const png.HeaderData,
    temp_allocator: Allocator,
};

pub const PaletteProcessData = struct {
    palette: []color.Rgba32,
    temp_allocator: Allocator,
};

pub const RowProcessData = struct {
    dest_row: []u8,
    src_format: PixelFormat,
    dest_format: PixelFormat,
    header: *const png.HeaderData,
    temp_allocator: Allocator,
};

/// This is the interface that custom processors must implement to be able to process chunks.
pub const ReaderProcessor = struct {
    id: u32,
    context: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        chunk_processor: ?*const fn (context: *anyopaque, data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat,
        palette_processor: ?*const fn (context: *anyopaque, data: *PaletteProcessData) ImageUnmanaged.ReadError!void,
        data_row_processor: ?*const fn (context: *anyopaque, data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat,
    };

    const Self = @This();

    pub inline fn processChunk(self: *Self, data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat {
        return if (self.vtable.chunk_processor) |cp| cp(self.context, data) else data.current_format;
    }

    pub inline fn processPalette(self: *Self, data: *PaletteProcessData) ImageUnmanaged.ReadError!void {
        if (self.vtable.palette_processor) |pp| try pp(self.context, data);
    }

    pub inline fn processDataRow(self: *Self, data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
        return if (self.vtable.data_row_processor) |drp| drp(self.context, data) else data.dest_format;
    }

    pub fn init(
        id: u32,
        context: anytype,
        comptime chunkProcessorFn: ?fn (ptr: @TypeOf(context), data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat,
        comptime paletteProcessorFn: ?fn (ptr: @TypeOf(context), data: *PaletteProcessData) ImageUnmanaged.ReadError!void,
        comptime dataRowProcessorFn: ?fn (ptr: @TypeOf(context), data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat,
    ) Self {
        const Ptr = @TypeOf(context);
        const ptr_info = @typeInfo(Ptr);

        std.debug.assert(ptr_info == .pointer); // Must be a pointer
        std.debug.assert(ptr_info.pointer.size == .one); // Must be a single-item pointer

        const gen = struct {
            fn chunkProcessor(ptr: *anyopaque, data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return @call(if (PNG_DEBUG) .auto else .always_inline, chunkProcessorFn.?, .{ self, data });
            }
            fn paletteProcessor(ptr: *anyopaque, data: *PaletteProcessData) ImageUnmanaged.ReadError!void {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return @call(if (PNG_DEBUG) .auto else .always_inline, paletteProcessorFn.?, .{ self, data });
            }
            fn dataRowProcessor(ptr: *anyopaque, data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return @call(if (PNG_DEBUG) .auto else .always_inline, dataRowProcessorFn.?, .{ self, data });
            }

            const vtable = VTable{
                .chunk_processor = if (chunkProcessorFn == null) null else chunkProcessor,
                .palette_processor = if (paletteProcessorFn == null) null else paletteProcessor,
                .data_row_processor = if (dataRowProcessorFn == null) null else dataRowProcessor,
            };
        };

        return .{
            .id = id,
            .context = context,
            .vtable = &gen.vtable,
        };
    }
};

/// This processor is used to process the tRNS chunk and add alpha channel to grayscale, indexed or RGB images from it.
pub const TrnsProcessor = struct {
    const Self = @This();
    const TRNSData = union(enum) {
        unset: void,
        gray: u16,
        rgb: color.Rgb48,
        index_alpha: []u8,
    };

    trns_data: TRNSData = .unset,
    processed: bool = false,

    pub fn processor(self: *Self) ReaderProcessor {
        return ReaderProcessor.init(
            png.Chunks.tRNS.id,
            self,
            processChunk,
            processPalette,
            processDataRow,
        );
    }

    pub fn processChunk(self: *Self, data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat {
        // We will allow multiple tRNS chunks and load the first one
        // We ignore if we encounter this chunk with color_type that already has alpha
        var result_format = data.current_format;
        if (self.processed) {
            try data.stream.seekBy(data.chunk_length + @sizeOf(u32)); // Skip invalid
            return result_format;
        }
        var reader = data.stream.reader();
        switch (data.header.getPixelFormat()) {
            .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16 => {
                if (data.chunk_length == 2) {
                    self.trns_data = .{ .gray = try reader.readInt(u16, .big) };
                    result_format = if (result_format == .grayscale16) .grayscale16Alpha else .grayscale8Alpha;
                } else {
                    try data.stream.seekBy(data.chunk_length); // Skip invalid
                }
            },
            .indexed1, .indexed2, .indexed4, .indexed8, .indexed16 => {
                if (data.chunk_length <= data.header.maxPaletteSize()) {
                    self.trns_data = .{ .index_alpha = try data.temp_allocator.alloc(u8, data.chunk_length) };
                    try reader.readNoEof(self.trns_data.index_alpha);
                } else {
                    try data.stream.seekBy(data.chunk_length); // Skip invalid
                }
            },
            .rgb24, .rgb48 => {
                if (data.chunk_length == @sizeOf(color.Rgb48)) {
                    self.trns_data = .{ .rgb = try utils.readStruct(reader, color.Rgb48, .big) };
                    result_format = if (result_format == .rgb48) .rgba64 else .rgba32;
                } else {
                    try data.stream.seekBy(data.chunk_length); // Skip invalid
                }
            },
            else => try data.stream.seekBy(data.chunk_length), // Skip invalid
        }
        // Skip the Crc since this is not critical chunk
        try data.stream.seekBy(@sizeOf(u32));
        return result_format;
    }

    pub fn processPalette(self: *Self, data: *PaletteProcessData) ImageUnmanaged.ReadError!void {
        self.processed = true;
        switch (self.trns_data) {
            .index_alpha => |index_alpha| {
                for (index_alpha, 0..) |alpha, i| {
                    data.palette[i].a = alpha;
                }
            },
            .unset => return,
            else => return ImageUnmanaged.ReadError.InvalidData,
        }
    }

    pub fn processDataRow(self: *Self, data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
        self.processed = true;
        if (data.src_format.isIndexed() or self.trns_data == .unset) {
            return data.src_format;
        }
        var pixel_stride: u8 = switch (data.dest_format) {
            .grayscale8Alpha, .grayscale16Alpha => 2,
            .rgba32, .bgra32 => 4,
            .rgba64 => 8,
            else => return data.src_format,
        };
        var pixel_pos: u32 = 0;
        // work around broken saturating arithmetic on wasm https://github.com/llvm/llvm-project/issues/58557
        const isWasm = comptime @import("builtin").target.cpu.arch.isWasm();
        switch (self.trns_data) {
            .gray => |gray_alpha| {
                switch (data.src_format) {
                    .grayscale1, .grayscale2, .grayscale4, .grayscale8 => {
                        while (pixel_pos + 1 < data.dest_row.len) : (pixel_pos += pixel_stride) {
                            if (!isWasm) {
                                data.dest_row[pixel_pos + 1] = (data.dest_row[pixel_pos] ^ @as(u8, @truncate(gray_alpha))) *| 255;
                            } else {
                                data.dest_row[pixel_pos + 1] = (data.dest_row[pixel_pos] ^ @as(u8, @truncate(gray_alpha))) * 255;
                            }
                        }
                        return .grayscale8Alpha;
                    },
                    .grayscale16 => {
                        var destination = std.mem.bytesAsSlice(u16, data.dest_row);
                        while (pixel_pos + 1 < destination.len) : (pixel_pos += pixel_stride) {
                            // work around broken saturating arithmetic on wasm https://github.com/llvm/llvm-project/issues/58557
                            if (!isWasm) {
                                destination[pixel_pos + 1] = (data.dest_row[pixel_pos] ^ gray_alpha) *| 65535;
                            } else {
                                destination[pixel_pos + 1] = (data.dest_row[pixel_pos] ^ gray_alpha) * 65535;
                            }
                        }
                        return .grayscale16Alpha;
                    },
                    else => unreachable,
                }
            },
            .rgb => |tr_color| {
                switch (data.src_format) {
                    .rgb24 => {
                        var destination = std.mem.bytesAsSlice(color.Rgba32, data.dest_row);
                        pixel_stride /= 4;
                        while (pixel_pos < destination.len) : (pixel_pos += pixel_stride) {
                            var val = destination[pixel_pos];
                            val.a = if (val.r == tr_color.r and val.g == tr_color.g and val.b == tr_color.b) 0 else 255;
                            destination[pixel_pos] = val;
                        }
                        return .rgba32;
                    },
                    .rgb48 => {
                        var destination = std.mem.bytesAsSlice(color.Rgba64, data.dest_row);
                        pixel_stride = 1;
                        while (pixel_pos < destination.len) : (pixel_pos += pixel_stride) {
                            var val = destination[pixel_pos];
                            val.a = if (val.r == tr_color.r and val.g == tr_color.g and val.b == tr_color.b) 0 else 65535;
                            destination[pixel_pos] = val;
                        }
                        return .rgba64;
                    },
                    else => unreachable,
                }
            },
            else => unreachable,
        }
        return data.src_format;
    }
};

/// This processor is used to process the PLTE chunk. It will convert indexed pixel data to RGBA32 format
/// as it is being loaded. If the image is not indexed or the palette is not set it will do nothing.
pub const PlteProcessor = struct {
    const Self = @This();

    palette: []color.Rgba32 = undefined,
    processed: bool = false,

    pub fn processor(self: *Self) ReaderProcessor {
        return ReaderProcessor.init(
            png.Chunks.PLTE.id,
            self,
            processChunk,
            processPalette,
            processDataRow,
        );
    }

    pub fn processChunk(self: *Self, data: *ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat {
        // This is critical chunk so it is already read and there is no need to read it here
        var result_format = data.current_format;
        if (self.processed or !result_format.isIndexed()) {
            self.processed = true;
            return result_format;
        }

        return .rgba32;
    }

    pub fn processPalette(self: *Self, data: *PaletteProcessData) ImageUnmanaged.ReadError!void {
        self.processed = true;
        self.palette = data.palette;
    }

    pub fn processDataRow(self: *Self, data: *RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
        self.processed = true;

        if (!data.src_format.isIndexed() or self.palette.len == 0) {
            return data.src_format;
        }

        const pixel_stride: u8 = switch (data.dest_format) {
            .rgba32, .bgra32 => 4,
            .rgba64 => 8,
            else => return data.src_format,
        };

        var pixel_pos: u32 = 0;
        switch (data.src_format) {
            .indexed1, .indexed2, .indexed4, .indexed8 => {
                while (pixel_pos + 3 < data.dest_row.len) : (pixel_pos += pixel_stride) {
                    const index = data.dest_row[pixel_pos];
                    const entry = self.palette[index];
                    data.dest_row[pixel_pos] = entry.r;
                    data.dest_row[pixel_pos + 1] = entry.g;
                    data.dest_row[pixel_pos + 2] = entry.b;
                    data.dest_row[pixel_pos + 3] = entry.a;
                }
            },
            .indexed16 => {
                while (pixel_pos + 3 < data.dest_row.len) : (pixel_pos += pixel_stride) {
                    const index = std.mem.bytesToValue(u16, &[2]u8{ data.dest_row[pixel_pos], data.dest_row[pixel_pos + 1] });
                    const entry = self.palette[index];
                    data.dest_row[pixel_pos] = entry.r;
                    data.dest_row[pixel_pos + 1] = entry.g;
                    data.dest_row[pixel_pos + 2] = entry.b;
                    data.dest_row[pixel_pos + 3] = entry.a;
                }
            },
            else => unreachable,
        }

        return .rgba32;
    }
};

/// The options you need to pass to PNG reader. If you want default options
/// that use main allocator for temporary allocations and tRNS processor
/// just use this:
/// var options = DefaultOptions.init(.{});
/// png.reader.load(main_allocator, options.get());
/// Note that application can define its own DefaultPngOptions in the root file
/// and all the code that uses DefaultOptions will actually use that.
pub const ReaderOptions = struct {
    /// Allocator for temporary allocations. Some temp allocations depend
    /// on the image size so they will use the main allocator since we can't guarantee
    /// they are bounded. They will be allocated after the destination image to
    /// reduce memory fragmentation and freed internally.
    temp_allocator: Allocator = .{ .ptr = undefined, .vtable = &NoopAllocator },

    /// Default is no processors so they are not even compiled in if not used.
    processors: []ReaderProcessor = &[_]ReaderProcessor{},

    pub fn init(temp_allocator: Allocator) ReaderOptions {
        return .{ .temp_allocator = temp_allocator };
    }

    pub fn initWithProcessors(temp_allocator: Allocator, processors: []ReaderProcessor) ReaderOptions {
        return .{ .temp_allocator = temp_allocator, .processors = processors };
    }
};

pub fn CustomReaderOptions1(Processor: type) type {
    return struct {
        processor: Processor,
        processors: [1]ReaderProcessor = undefined,

        const Self = @This();

        pub fn init(processor: Processor) Self {
            return .{ .processor = processor };
        }

        pub fn get(self: *Self) ReaderOptions {
            return self.getWithTempAllocator(.{ .ptr = undefined, .vtable = &NoopAllocator });
        }

        pub fn getWithTempAllocator(self: *Self, temp_allocator: Allocator) ReaderOptions {
            self.processors[0] = self.processor.processor();
            return .{ .temp_allocator = temp_allocator, .processors = self.processors[0..] };
        }
    };
}

pub fn CustomReaderOptions2(Processor1: type, Processor2: type) type {
    return struct {
        processor1: Processor1,
        processor2: Processor2,
        processors: [2]ReaderProcessor = undefined,

        const Self = @This();

        pub fn init(processor1: Processor1, processor2: Processor2) Self {
            return .{ .processor1 = processor1, .processor2 = processor2 };
        }

        pub fn get(self: *Self) ReaderOptions {
            return self.getWithTempAllocator(.{ .ptr = undefined, .vtable = &NoopAllocator });
        }

        pub fn getWithTempAllocator(self: *Self, temp_allocator: Allocator) ReaderOptions {
            self.processors[0] = self.processor1.processor();
            self.processors[1] = self.processor2.processor();
            return .{ .temp_allocator = temp_allocator, .processors = self.processors[0..] };
        }
    };
}

const root = @import("root");

pub const NoopAllocator = Allocator.VTable{ .alloc = undefined, .free = undefined, .resize = undefined, .remap = undefined };

/// Applications can override this by defining DefaultPngOptions struct in their root source file.
/// We would like to use FixedBufferAllocator with memory from stack here since we should be able
/// to guarantee the max size of temp allocations but zig's std decompressor unlike C zlib doesn't
/// currently guarantee the max it needs.
pub const DefaultOptions = if (@hasDecl(root, "DefaultPngOptions"))
    root.DefaultPngOptions
else
    CustomReaderOptions1(TrnsProcessor);

// ********************* TESTS *********************

test "testDefilter" {
    var buffer = [_]u8{ 0, 1, 2, 3, 0, 5, 6, 7 };
    // Start with none filter
    var current_row: []u8 = buffer[4..];
    var prev_row: []u8 = buffer[0..4];
    var filter_stride: u8 = 1;

    try testFilter(png.FilterType.none, current_row, prev_row, filter_stride, &[_]u8{ 0, 5, 6, 7 });
    try testFilter(png.FilterType.sub, current_row, prev_row, filter_stride, &[_]u8{ 0, 5, 11, 18 });
    try testFilter(png.FilterType.up, current_row, prev_row, filter_stride, &[_]u8{ 0, 6, 13, 21 });
    try testFilter(png.FilterType.average, current_row, prev_row, filter_stride, &[_]u8{ 0, 6, 17, 31 });
    try testFilter(png.FilterType.paeth, current_row, prev_row, filter_stride, &[_]u8{ 0, 7, 24, 55 });

    var buffer16 = [_]u8{ 0, 0, 1, 2, 3, 4, 5, 6, 7, 0, 0, 8, 9, 10, 11, 12, 13, 14 };
    current_row = buffer16[9..];
    prev_row = buffer16[0..9];
    filter_stride = 2;

    try testFilter(png.FilterType.none, current_row, prev_row, filter_stride, &[_]u8{ 0, 0, 8, 9, 10, 11, 12, 13, 14 });
    try testFilter(png.FilterType.sub, current_row, prev_row, filter_stride, &[_]u8{ 0, 0, 8, 9, 18, 20, 30, 33, 44 });
    try testFilter(png.FilterType.up, current_row, prev_row, filter_stride, &[_]u8{ 0, 0, 9, 11, 21, 24, 35, 39, 51 });
    try testFilter(png.FilterType.average, current_row, prev_row, filter_stride, &[_]u8{ 0, 0, 9, 12, 27, 32, 51, 58, 80 });
    try testFilter(png.FilterType.paeth, current_row, prev_row, filter_stride, &[_]u8{ 0, 0, 10, 14, 37, 46, 88, 104, 168 });
}

fn testFilter(filter_type: png.FilterType, current_row: []u8, prev_row: []u8, filter_stride: u8, expected: []const u8) !void {
    const expectEqualSlices = std.testing.expectEqualSlices;
    current_row[filter_stride - 1] = @intFromEnum(filter_type);
    try defilter(current_row, prev_row, filter_stride);
    try expectEqualSlices(u8, expected, current_row);
}

test "spreadRowData" {
    var channel_count: u8 = 1;
    var bit_depth: u8 = 1;
    // 16 destination bytes, filter byte and two more bytes of current_row
    var dest_buffer: [32]u8 = @splat(0);
    var cur_buffer = [_]u8{ 0, 0, 0, 0, 0xa5, 0x7c, 0x39, 0xf2, 0x5b, 0x15, 0x78, 0xd1 };
    var dest_row: []u8 = dest_buffer[0..16];
    var current_row: []u8 = cur_buffer[3..6];
    var filter_stride: u8 = 1;
    var pixel_stride: u8 = 1;
    const expectEqualSlices = std.testing.expectEqualSlices;

    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0 }, dest_row);
    dest_row = dest_buffer[0..32];
    pixel_stride = 2;
    @memset(dest_row, 0);
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0 }, dest_row);

    bit_depth = 2;
    pixel_stride = 1;
    dest_row = dest_buffer[0..8];
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 2, 2, 1, 1, 1, 3, 3, 0 }, dest_row);
    dest_row = dest_buffer[0..16];
    pixel_stride = 2;
    @memset(dest_row, 0);
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 2, 0, 2, 0, 1, 0, 1, 0, 1, 0, 3, 0, 3, 0, 0, 0 }, dest_row);

    bit_depth = 4;
    pixel_stride = 1;
    dest_row = dest_buffer[0..4];
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa, 0x5, 0x7, 0xc }, dest_row);
    dest_row = dest_buffer[0..8];
    pixel_stride = 2;
    @memset(dest_row, 0);
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa, 0, 0x5, 0, 0x7, 0, 0xc, 0 }, dest_row);

    bit_depth = 8;
    pixel_stride = 1;
    dest_row = dest_buffer[0..2];
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa5, 0x7c }, dest_row);
    dest_row = dest_buffer[0..4];
    pixel_stride = 2;
    @memset(dest_row, 0);
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa5, 0, 0x7c, 0 }, dest_row);

    channel_count = 2; // grayscale_alpha
    bit_depth = 8;
    current_row = cur_buffer[2..8];
    dest_row = dest_buffer[0..4];
    filter_stride = 2;
    pixel_stride = 2;
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa5, 0x7c, 0x39, 0xf2 }, dest_row);
    dest_row = dest_buffer[0..8];
    @memset(dest_row, 0);
    pixel_stride = 4;
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa5, 0x7c, 0, 0, 0x39, 0xf2, 0, 0 }, dest_row);

    bit_depth = 16;
    current_row = cur_buffer[0..12];
    dest_row = dest_buffer[0..8];
    filter_stride = 4;
    pixel_stride = 4;
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, true);
    try expectEqualSlices(u8, &[_]u8{ 0x7c, 0xa5, 0xf2, 0x39, 0x15, 0x5b, 0xd1, 0x78 }, dest_row);

    channel_count = 3;
    bit_depth = 8;
    current_row = cur_buffer[1..10];
    dest_row = dest_buffer[0..8];
    @memset(dest_row, 0);
    filter_stride = 3;
    pixel_stride = 4;
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, false);
    try expectEqualSlices(u8, &[_]u8{ 0xa5, 0x7c, 0x39, 0, 0xf2, 0x5b, 0x15, 0 }, dest_row);

    channel_count = 4;
    bit_depth = 16;
    var cbuffer16 = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0xa5, 0x7c, 0x39, 0xf2, 0x5b, 0x15, 0x78, 0xd1 };
    current_row = cbuffer16[0..];
    dest_row = dest_buffer[0..8];
    @memset(dest_row, 0);
    filter_stride = 8;
    pixel_stride = 8;
    spreadRowData(dest_row, current_row[filter_stride..], bit_depth, channel_count, pixel_stride, true);
    try expectEqualSlices(u8, &[_]u8{ 0x7c, 0xa5, 0xf2, 0x39, 0x15, 0x5b, 0xd1, 0x78 }, dest_row);
}
