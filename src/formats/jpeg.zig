const std = @import("std");
const Allocator = std.mem.Allocator;

const ImageError = Image.Error;
const ImageReadError = Image.ReadError;
const ImageWriteError = Image.WriteError;
const Image = @import("../Image.zig");
const FormatInterface = @import("../format_interface.zig").FormatInterface;
const color = @import("../color.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;

const Markers = @import("./jpeg/markers.zig").Markers;
const FrameHeader = @import("./jpeg/frame_header.zig");
const JFIFHeader = @import("./jpeg/jfif_header.zig");

// TODO: Chroma subsampling
// TODO: Progressive scans
// TODO: Non-baseline sequential DCT
// TODO: Precisions other than 8-bit

const JPEG_DEBUG = false;
const JPEG_VERY_DEBUG = false;
const MAX_COMPONENTS = 3;
const MAX_BLOCKS = 8;
const MCU = [64]i32;

const QuantizationTable = union(enum) {
    q8: [64]u8,
    q16: [64]u16,

    pub fn read(precision: u8, reader: Image.Stream.Reader) ImageReadError!QuantizationTable {
        // 0 = 8 bits, 1 = 16 bits
        switch (precision) {
            0 => {
                var table = QuantizationTable{ .q8 = undefined };

                var offset: usize = 0;
                while (offset < 64) : (offset += 1) {
                    const value = try reader.readByte();
                    table.q8[ZigzagOffsets[offset]] = value;
                }

                if (JPEG_DEBUG) {
                    var i: usize = 0;
                    while (i < 8) : (i += 1) {
                        var j: usize = 0;
                        while (j < 8) : (j += 1) {
                            std.debug.print("{d:4} ", .{table.q8[i * 8 + j]});
                        }
                        std.debug.print("\n", .{});
                    }
                }

                return table;
            },
            1 => {
                var table = QuantizationTable{ .q16 = undefined };

                var offset: usize = 0;
                while (offset < 64) : (offset += 1) {
                    const value = try reader.readIntBig(u16);
                    table.q16[ZigzagOffsets[offset]] = value;
                }

                return table;
            },
            else => return ImageReadError.InvalidData,
        }
    }
};

const HuffmanCode = struct { length_minus_one: u4, code: u16 };
const HuffmanCodeMap = std.AutoArrayHashMap(HuffmanCode, u8);

const HuffmanTable = struct {
    allocator: Allocator,

    code_counts: [16]u8,
    code_map: HuffmanCodeMap,

    table_class: u8,

    pub fn read(allocator: Allocator, table_class: u8, reader: Image.Stream.Reader) ImageReadError!HuffmanTable {
        if (table_class & 1 != table_class)
            return ImageReadError.InvalidData;

        var code_counts: [16]u8 = undefined;
        if ((try reader.read(code_counts[0..])) < 16) {
            return ImageReadError.InvalidData;
        }

        if (JPEG_DEBUG) std.debug.print("  Code counts: {any}\n", .{code_counts});

        var total_huffman_codes: usize = 0;
        for (code_counts) |count| total_huffman_codes += count;

        var huffman_code_map = HuffmanCodeMap.init(allocator);
        errdefer huffman_code_map.deinit();

        if (JPEG_VERY_DEBUG) std.debug.print("  Decoded huffman codes map:\n", .{});

        var code: u16 = 0;
        for (code_counts, 0..) |count, i| {
            if (JPEG_VERY_DEBUG) {
                std.debug.print("    Length {}: ", .{i + 1});
                if (count == 0) {
                    std.debug.print("(none)\n", .{});
                } else {
                    std.debug.print("\n", .{});
                }
            }

            var j: usize = 0;
            while (j < count) : (j += 1) {
                // Check if we hit all 1s, i.e. 111111 for i == 6, which is an invalid value
                if (code == (@as(u17, @intCast(1)) << (@as(u5, @intCast(i)) + 1)) - 1) {
                    return ImageReadError.InvalidData;
                }

                const byte = try reader.readByte();
                try huffman_code_map.put(.{ .length_minus_one = @as(u4, @intCast(i)), .code = code }, byte);

                if (JPEG_VERY_DEBUG) std.debug.print("      {b} => 0x{X}\n", .{ code, byte });
                code += 1;
            }

            code <<= 1;
        }

        return HuffmanTable{
            .allocator = allocator,
            .code_counts = code_counts,
            .code_map = huffman_code_map,
            .table_class = table_class,
        };
    }

    pub fn deinit(self: *HuffmanTable) void {
        self.code_map.deinit();
    }
};

const HuffmanReader = struct {
    table: ?*const HuffmanTable = null,
    reader: Image.Stream.Reader,
    byte_buffer: u8 = 0,
    bits_left: u4 = 0,
    last_byte_was_ff: bool = false,

    pub fn init(reader: Image.Stream.Reader) HuffmanReader {
        return .{
            .reader = reader,
        };
    }

    pub fn setHuffmanTable(self: *HuffmanReader, table: *const HuffmanTable) void {
        self.table = table;
    }

    fn readBit(self: *HuffmanReader) ImageReadError!u1 {
        if (self.bits_left == 0) {
            self.byte_buffer = try self.reader.readByte();

            if (self.byte_buffer == 0 and self.last_byte_was_ff) {
                // This was a stuffed byte, read one more.
                self.byte_buffer = try self.reader.readByte();
            }
            self.last_byte_was_ff = self.byte_buffer == 0xFF;
            self.bits_left = 8;
        }

        const bit: u1 = @intCast(self.byte_buffer >> 7);
        self.byte_buffer <<= 1;
        self.bits_left -= 1;

        return bit;
    }

    pub fn readCode(self: *HuffmanReader) ImageReadError!u8 {
        var code: u16 = 0;

        var i: u5 = 0;
        while (i < 16) : (i += 1) {
            code = (code << 1) | (try self.readBit());
            if (self.table.?.code_map.get(.{ .length_minus_one = @intCast(i), .code = code })) |value| {
                return value;
            }
        }

        if (JPEG_DEBUG) std.debug.print("found unknown code: {x}\n", .{code});
        return ImageReadError.InvalidData;
    }

    pub fn readLiteralBits(self: *HuffmanReader, bitsNeeded: u8) ImageReadError!u32 {
        var bits: u32 = 0;

        var i: usize = 0;
        while (i < bitsNeeded) : (i += 1) {
            bits = (bits << 1) | (try self.readBit());
        }

        return bits;
    }

    /// This function implements T.81 section F1.2.1, Huffman encoding of DC coefficients.
    pub fn readMagnitudeCoded(self: *HuffmanReader, magnitude: u5) ImageReadError!i32 {
        if (magnitude == 0)
            return 0;

        const bits = try self.readLiteralBits(magnitude);

        // The sign of the read bits value.
        const bits_sign = (bits >> (magnitude - 1)) & 1;
        // The mask for clearing the sign bit.
        const bits_mask = (@as(u32, 1) << (magnitude - 1)) - 1;
        // The bits without the sign bit.
        const unsigned_bits = bits & bits_mask;

        // The magnitude base value. This is -2^n+1 when bits_sign == 0, and
        // 2^(n-1) when bits_sign == 1.
        const base = if (bits_sign == 0)
            -(@as(i32, 1) << magnitude) + 1
        else
            (@as(i32, 1) << (magnitude - 1));

        return base + @as(i32, @bitCast(unsigned_bits));
    }
};

const ScanComponentSpec = struct {
    component_selector: u8,
    dc_table_selector: u4,
    ac_table_selector: u4,

    pub fn read(reader: Image.Stream.Reader) ImageReadError!ScanComponentSpec {
        const component_selector = try reader.readByte();
        const entropy_coding_selectors = try reader.readByte();

        const dc_table_selector: u4 = @intCast(entropy_coding_selectors >> 4);
        const ac_table_selector: u4 = @intCast(entropy_coding_selectors & 0b11);

        if (JPEG_VERY_DEBUG) {
            std.debug.print("    Component spec: selector={}, DC table ID={}, AC table ID={}\n", .{ component_selector, dc_table_selector, ac_table_selector });
        }

        return ScanComponentSpec{
            .component_selector = component_selector,
            .dc_table_selector = dc_table_selector,
            .ac_table_selector = ac_table_selector,
        };
    }
};

const ScanHeader = struct {
    components: [4]?ScanComponentSpec,
    start_of_spectral_selection: u8,
    end_of_spectral_selection: u8,
    approximation_high: u4,
    approximation_low: u4,

    pub fn read(reader: Image.Stream.Reader) ImageReadError!ScanHeader {
        var segment_size = try reader.readIntBig(u16);
        if (JPEG_DEBUG) std.debug.print("StartOfScan: segment size = 0x{X}\n", .{segment_size});
        segment_size -= 2;

        const component_count = try reader.readByte();
        if (component_count < 1 or component_count > 4) {
            return ImageReadError.InvalidData;
        }

        segment_size -= 1;

        var components = [_]?ScanComponentSpec{null} ** 4;

        if (JPEG_VERY_DEBUG) std.debug.print("  Components:\n", .{});
        var i: usize = 0;
        while (i < component_count) : (i += 1) {
            components[i] = try ScanComponentSpec.read(reader);
            segment_size -= 2;
        }

        const start_of_spectral_selection = try reader.readByte();
        const end_of_spectral_selection = try reader.readByte();

        if (start_of_spectral_selection > 63) {
            return ImageReadError.InvalidData;
        }

        if (end_of_spectral_selection < start_of_spectral_selection or end_of_spectral_selection > 63) {
            return ImageReadError.InvalidData;
        }

        // If Ss = 0, then Se = 63.
        if (start_of_spectral_selection == 0 and end_of_spectral_selection != 63) {
            return ImageReadError.InvalidData;
        }

        segment_size -= 2;
        if (JPEG_VERY_DEBUG) std.debug.print("  Spectral selection: {}-{}\n", .{ start_of_spectral_selection, end_of_spectral_selection });

        const approximation_bits = try reader.readByte();
        const approximation_high: u4 = @intCast(approximation_bits >> 4);
        const approximation_low: u4 = @intCast(approximation_bits & 0b1111);

        segment_size -= 1;
        if (JPEG_VERY_DEBUG) std.debug.print("  Approximation bit position: high={} low={}\n", .{ approximation_high, approximation_low });

        std.debug.assert(segment_size == 0);

        return ScanHeader{
            .components = components,
            .start_of_spectral_selection = start_of_spectral_selection,
            .end_of_spectral_selection = end_of_spectral_selection,
            .approximation_high = approximation_high,
            .approximation_low = approximation_low,
        };
    }
};

// See figure A.6 in T.81.
const ZigzagOffsets = blk: {
    var offsets: [64]usize = undefined;
    offsets[0] = 0;

    var current_offset: usize = 0;
    var direction: enum { north_east, south_west } = .north_east;
    var i: usize = 1;
    while (i < 64) : (i += 1) {
        switch (direction) {
            .north_east => {
                if (current_offset < 8) {
                    // Hit top edge
                    current_offset += 1;
                    direction = .south_west;
                } else if (current_offset % 8 == 7) {
                    // Hit right edge
                    current_offset += 8;
                    direction = .south_west;
                } else {
                    current_offset -= 7;
                }
            },
            .south_west => {
                if (current_offset >= 56) {
                    // Hit bottom edge
                    current_offset += 1;
                    direction = .north_east;
                } else if (current_offset % 8 == 0) {
                    // Hit left edge
                    current_offset += 8;
                    direction = .north_east;
                } else {
                    current_offset += 7;
                }
            },
        }

        if (current_offset >= 64) {
            @compileError(std.fmt.comptimePrint("ZigzagOffsets: Hit offset {} (>= 64) at index {}!\n", .{ current_offset, i }));
        }

        offsets[i] = current_offset;
    }

    break :blk offsets;
};

// The precalculated IDCT multipliers. This is possible because the only part of
// the IDCT calculation that changes between runs is the coefficients.
const IDCTMultipliers = blk: {
    var multipliers: [8][8][8][8]f32 = undefined;
    @setEvalBranchQuota(18086);

    var y: usize = 0;
    while (y < 8) : (y += 1) {
        var x: usize = 0;
        while (x < 8) : (x += 1) {
            var u: usize = 0;
            while (u < 8) : (u += 1) {
                var v: usize = 0;
                while (v < 8) : (v += 1) {
                    const C_u: f32 = if (u == 0) 1.0 / @sqrt(2.0) else 1.0;
                    const C_v: f32 = if (v == 0) 1.0 / @sqrt(2.0) else 1.0;

                    const x_cosine = @cos(((2 * @as(f32, @floatFromInt(x)) + 1) * @as(f32, @floatFromInt(u)) * std.math.pi) / 16.0);
                    const y_cosine = @cos(((2 * @as(f32, @floatFromInt(y)) + 1) * @as(f32, @floatFromInt(v)) * std.math.pi) / 16.0);
                    const uv_value = C_u * C_v * x_cosine * y_cosine;
                    multipliers[y][x][u][v] = uv_value;
                }
            }
        }
    }

    break :blk multipliers;
};

const Scan = struct {
    pub fn performScan(frame: *const Frame, reader: Image.Stream.Reader, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        const scan_header = try ScanHeader.read(reader);

        var prediction_values = [3]i12{ 0, 0, 0 };
        var huffman_reader = HuffmanReader.init(reader);
        var mcu_storage: [MAX_COMPONENTS][MAX_BLOCKS]MCU = undefined;

        const mcu_count = Scan.calculateMCUCountInFrame(&frame.frame_header);
        for (0..mcu_count) |mcu_id| {
            try Scan.decodeMCU(frame, scan_header, &mcu_storage, &huffman_reader, &prediction_values);
            try Scan.dequantize(frame, &mcu_storage);
            try frame.renderToPixels(&mcu_storage, mcu_id, &pixels_opt.*.?);
        }
    }

    fn calculateMCUCountInFrame(frame_header: *const FrameHeader) usize {
        // FIXME: This is very naive and probably only works for Baseline DCT.
        // MCU of non-interleaved is just one block.
        const horizontal_block_count = if (1 < frame_header.components.len) frame_header.getMaxHorizontalSamplingFactor() else 1;
        const vertical_block_count = if (1 < frame_header.components.len) frame_header.getMaxVerticalSamplingFactor() else 1;
        const mcu_width = 8 * horizontal_block_count;
        const mcu_height = 8 * vertical_block_count;
        const mcu_count_per_row = (frame_header.samples_per_row + mcu_width - 1) / mcu_width;
        const mcu_count_per_column = (frame_header.row_count + mcu_height - 1) / mcu_height;
        return mcu_count_per_row * mcu_count_per_column;
    }

    fn dequantize(self: *const Frame, mcu_storage: *[MAX_COMPONENTS][MAX_BLOCKS]MCU) !void {
        for (self.frame_header.components, 0..) |component, component_id| {
            const block_count = self.frame_header.getBlockCount(component_id);
            for (0..block_count) |i| {
                const block = &mcu_storage[component_id][i];

                if (self.quantization_tables[component.quantization_table_id]) |quantization_table| {
                    var sample_id: usize = 0;
                    while (sample_id < 64) : (sample_id += 1) {
                        block[sample_id] = block[sample_id] * quantization_table.q8[sample_id];
                    }
                } else return ImageReadError.InvalidData;
            }
        }
    }

    fn decodeMCU(frame: *const Frame, scan_header: ScanHeader, mcu_storage: *[MAX_COMPONENTS][MAX_BLOCKS]MCU, reader: *HuffmanReader, prediction_values: *[3]i12) ImageReadError!void {
        for (scan_header.components, 0..) |maybe_component, component_id| {
            _ = component_id;
            if (maybe_component == null)
                break;

            try Scan.decodeMCUComponent(frame, maybe_component.?, mcu_storage, reader, prediction_values);
        }
    }

    fn decodeMCUComponent(frame: *const Frame, component: ScanComponentSpec, mcu_storage: *[MAX_COMPONENTS][MAX_BLOCKS]MCU, reader: *HuffmanReader, prediction_values: *[3]i12) ImageReadError!void {
        // The encoder might reorder components or omit one if it decides that the
        // file size can be reduced that way. Therefore we need to select the correct
        // destination for this component.
        const component_destination = blk: {
            for (frame.frame_header.components, 0..) |frame_component, i| {
                if (frame_component.id == component.component_selector) {
                    break :blk i;
                }
            }

            return ImageReadError.InvalidData;
        };

        const block_count = frame.frame_header.getBlockCount(component_destination);
        for (0..block_count) |i| {
            const mcu = &mcu_storage[component_destination][i];

            // Decode the DC coefficient
            if (frame.dc_huffman_tables[component.dc_table_selector] == null) return ImageReadError.InvalidData;

            reader.setHuffmanTable(&frame.dc_huffman_tables[component.dc_table_selector].?);

            const dc_coefficient = try Scan.decodeDCCoefficient(reader, &prediction_values[component_destination]);
            mcu[0] = dc_coefficient;

            // Decode the AC coefficients
            if (frame.ac_huffman_tables[component.ac_table_selector] == null)
                return ImageReadError.InvalidData;

            reader.setHuffmanTable(&frame.ac_huffman_tables[component.ac_table_selector].?);

            try Scan.decodeACCoefficients(reader, mcu);
        }
    }

    fn decodeDCCoefficient(reader: *HuffmanReader, prediction: *i12) ImageReadError!i12 {
        const maybe_magnitude = try reader.readCode();
        if (maybe_magnitude > 11) return ImageReadError.InvalidData;
        const magnitude: u4 = @intCast(maybe_magnitude);

        const diff: i12 = @intCast(try reader.readMagnitudeCoded(magnitude));
        const dc_coefficient = diff + prediction.*;
        prediction.* = dc_coefficient;

        return dc_coefficient;
    }

    fn decodeACCoefficients(reader: *HuffmanReader, mcu: *MCU) ImageReadError!void {
        var ac: usize = 1;
        var did_see_eob = false;
        while (ac < 64) : (ac += 1) {
            if (did_see_eob) {
                mcu[ZigzagOffsets[ac]] = 0;
                continue;
            }

            const zero_run_length_and_magnitude = try reader.readCode();
            // 00 == EOB
            if (zero_run_length_and_magnitude == 0x00) {
                did_see_eob = true;
                mcu[ZigzagOffsets[ac]] = 0;
                continue;
            }

            const zero_run_length = zero_run_length_and_magnitude >> 4;

            const maybe_magnitude = zero_run_length_and_magnitude & 0xF;
            if (maybe_magnitude > 10) return ImageReadError.InvalidData;
            const magnitude: u4 = @intCast(maybe_magnitude);

            const ac_coefficient: i11 = @intCast(try reader.readMagnitudeCoded(magnitude));

            var i: usize = 0;
            while (i < zero_run_length) : (i += 1) {
                mcu[ZigzagOffsets[ac]] = 0;
                ac += 1;
            }

            mcu[ZigzagOffsets[ac]] = ac_coefficient;
        }
    }
};

const Frame = struct {
    allocator: Allocator,
    frame_header: FrameHeader,
    quantization_tables: *[4]?QuantizationTable,
    dc_huffman_tables: [2]?HuffmanTable,
    ac_huffman_tables: [2]?HuffmanTable,

    pub fn read(allocator: Allocator, quantization_tables: *[4]?QuantizationTable, stream: *Image.Stream) ImageReadError!Frame {
        const reader = stream.reader();
        var frame_header = try FrameHeader.read(allocator, reader);

        var self = Frame{
            .allocator = allocator,
            .frame_header = frame_header,
            .quantization_tables = quantization_tables,
            .dc_huffman_tables = [_]?HuffmanTable{null} ** 2,
            .ac_huffman_tables = [_]?HuffmanTable{null} ** 2,
        };
        errdefer self.deinit();

        var marker = try reader.readIntBig(u16);
        while (marker != @intFromEnum(Markers.start_of_scan)) : (marker = try reader.readIntBig(u16)) {
            if (JPEG_DEBUG) std.debug.print("Frame: Parsing marker value: 0x{X}\n", .{marker});

            switch (@as(Markers, @enumFromInt(marker))) {
                .define_huffman_tables => {
                    try self.parseDefineHuffmanTables(reader);
                },
                else => {
                    return ImageReadError.InvalidData;
                },
            }
        }

        // Undo the last marker read
        try stream.seekBy(-2);

        return self;
    }

    pub fn deinit(self: *Frame) void {
        for (&self.dc_huffman_tables) |*maybe_huffman_table| {
            if (maybe_huffman_table.*) |*huffman_table| {
                huffman_table.deinit();
            }
        }

        for (&self.ac_huffman_tables) |*maybe_huffman_table| {
            if (maybe_huffman_table.*) |*huffman_table| {
                huffman_table.deinit();
            }
        }

        self.frame_header.deinit();
    }

    fn parseDefineHuffmanTables(self: *Frame, reader: Image.Stream.Reader) ImageReadError!void {
        var segment_size = try reader.readIntBig(u16);
        if (JPEG_DEBUG) std.debug.print("DefineHuffmanTables: segment size = 0x{X}\n", .{segment_size});
        segment_size -= 2;

        while (segment_size > 0) {
            const class_and_destination = try reader.readByte();
            const table_class = class_and_destination >> 4;
            const table_destination = class_and_destination & 0b1;

            const huffman_table = try HuffmanTable.read(self.allocator, table_class, reader);

            if (table_class == 0) {
                if (self.dc_huffman_tables[table_destination]) |*old_huffman_table| {
                    old_huffman_table.deinit();
                }
                self.dc_huffman_tables[table_destination] = huffman_table;
            } else {
                if (self.ac_huffman_tables[table_destination]) |*old_huffman_table| {
                    old_huffman_table.deinit();
                }
                self.ac_huffman_tables[table_destination] = huffman_table;
            }

            if (JPEG_DEBUG) std.debug.print("  Table with class {} installed at {}\n", .{ table_class, table_destination });

            // Class+Destination + code counts + code table
            segment_size -= 1 + 16 + @as(u16, @intCast(huffman_table.code_map.count()));
        }
    }

    pub fn renderToPixels(self: *const Frame, mcu_storage: *[MAX_COMPONENTS][MAX_BLOCKS]MCU, mcu_id: usize, pixels: *color.PixelStorage) ImageReadError!void {
        switch (self.frame_header.components.len) {
            1 => try self.renderToPixelsGrayscale(&mcu_storage[0][0], mcu_id, pixels.grayscale8), // Grayscale images is non-interleaved
            3 => try self.renderToPixelsRgb(mcu_storage, mcu_id, pixels.rgb24),
            else => unreachable,
        }
    }

    fn renderToPixelsGrayscale(self: *const Frame, mcu_storage: *MCU, mcu_id: usize, pixels: []color.Grayscale8) ImageReadError!void {
        const mcu_width = 8;
        const mcu_height = 8;
        const width = self.frame_header.samples_per_row;
        const height = pixels.len / width;
        const mcus_per_row = (width + mcu_width - 1) / mcu_width;
        const mcu_origin_x = (mcu_id % mcus_per_row) * mcu_width;
        const mcu_origin_y = (mcu_id / mcus_per_row) * mcu_height;

        for (0..mcu_height) |mcu_y| {
            const y = mcu_origin_y + mcu_y;
            if (y >= height) continue;

            // y coordinates in the block
            const block_y = mcu_y % 8;

            const stride = y * width;

            for (0..mcu_width) |mcu_x| {
                const x = mcu_origin_x + mcu_x;
                if (x >= width) continue;

                // x coordinates in the block
                const block_x = mcu_x % 8;

                const reconstructed_Y = idct(mcu_storage, @as(u3, @intCast(block_x)), @as(u3, @intCast(block_y)), mcu_id, 0);
                const Y: f32 = @floatFromInt(reconstructed_Y);
                pixels[stride + x] = .{
                    .value = @as(u8, @intFromFloat(std.math.clamp(Y + 128.0, 0.0, 255.0))),
                };
            }
        }
    }

    fn renderToPixelsRgb(self: *const Frame, mcu_storage: *[MAX_COMPONENTS][MAX_BLOCKS]MCU, mcu_id: usize, pixels: []color.Rgb24) ImageReadError!void {
        const max_horizontal_sampling_factor = self.frame_header.getMaxHorizontalSamplingFactor();
        const max_vertical_sampling_factor = self.frame_header.getMaxVerticalSamplingFactor();
        const mcu_width = 8 * max_horizontal_sampling_factor;
        const mcu_height = 8 * max_vertical_sampling_factor;
        const width = self.frame_header.samples_per_row;
        const height = pixels.len / width;
        const mcus_per_row = (width + mcu_width - 1) / mcu_width;

        const mcu_origin_x = (mcu_id % mcus_per_row) * mcu_width;
        const mcu_origin_y = (mcu_id / mcus_per_row) * mcu_height;

        for (0..mcu_height) |mcu_y| {
            const y = mcu_origin_y + mcu_y;
            if (y >= height) continue;

            // y coordinates of each component applied to the sampling factor
            const y_sampled_y = (mcu_y * self.frame_header.components[0].vertical_sampling_factor) / max_vertical_sampling_factor;
            const cb_sampled_y = (mcu_y * self.frame_header.components[1].vertical_sampling_factor) / max_vertical_sampling_factor;
            const cr_sampled_y = (mcu_y * self.frame_header.components[2].vertical_sampling_factor) / max_vertical_sampling_factor;

            // y coordinates of each component in the block
            const y_block_y = y_sampled_y % 8;
            const cb_block_y = cb_sampled_y % 8;
            const cr_block_y = cr_sampled_y % 8;

            const stride = y * width;

            for (0..mcu_width) |mcu_x| {
                const x = mcu_origin_x + mcu_x;
                if (x >= width) continue;

                // x coordinates of each component applied to the sampling factor
                const y_sampled_x = (mcu_x * self.frame_header.components[0].horizontal_sampling_factor) / max_horizontal_sampling_factor;
                const cb_sampled_x = (mcu_x * self.frame_header.components[1].horizontal_sampling_factor) / max_horizontal_sampling_factor;
                const cr_sampled_x = (mcu_x * self.frame_header.components[2].horizontal_sampling_factor) / max_horizontal_sampling_factor;

                // x coordinates of each component in the block
                const y_block_x = y_sampled_x % 8;
                const cb_block_x = cb_sampled_x % 8;
                const cr_block_x = cr_sampled_x % 8;

                const y_block_ind = (y_sampled_y / 8) * self.frame_header.components[0].horizontal_sampling_factor + (y_sampled_x / 8);
                const cb_block_ind = (cb_sampled_y / 8) * self.frame_header.components[1].horizontal_sampling_factor + (cb_sampled_x / 8);
                const cr_block_ind = (cr_sampled_y / 8) * self.frame_header.components[2].horizontal_sampling_factor + (cr_sampled_x / 8);

                const mcu_Y = &mcu_storage[0][y_block_ind];
                const mcu_Cb = &mcu_storage[1][cb_block_ind];
                const mcu_Cr = &mcu_storage[2][cr_block_ind];

                const reconstructed_Y = idct(mcu_Y, @as(u3, @intCast(y_block_x)), @as(u3, @intCast(y_block_y)), mcu_id, 0);
                const reconstructed_Cb = idct(mcu_Cb, @as(u3, @intCast(cb_block_x)), @as(u3, @intCast(cb_block_y)), mcu_id, 1);
                const reconstructed_Cr = idct(mcu_Cr, @as(u3, @intCast(cr_block_x)), @as(u3, @intCast(cr_block_y)), mcu_id, 2);

                const Y: f32 = @floatFromInt(reconstructed_Y);
                const Cb: f32 = @floatFromInt(reconstructed_Cb);
                const Cr: f32 = @floatFromInt(reconstructed_Cr);

                const Co_red = 0.299;
                const Co_green = 0.587;
                const Co_blue = 0.114;

                const r = Cr * (2 - 2 * Co_red) + Y;
                const b = Cb * (2 - 2 * Co_blue) + Y;
                const g = (Y - Co_blue * b - Co_red * r) / Co_green;

                pixels[stride + x] = .{
                    .r = @intFromFloat(std.math.clamp(r + 128.0, 0.0, 255.0)),
                    .g = @intFromFloat(std.math.clamp(g + 128.0, 0.0, 255.0)),
                    .b = @intFromFloat(std.math.clamp(b + 128.0, 0.0, 255.0)),
                };
            }
        }
    }

    fn idct(mcu: *const MCU, x: u3, y: u3, mcu_id: usize, component_id: usize) i8 {
        var reconstructed_pixel: f32 = 0.0;

        var u: usize = 0;
        while (u < 8) : (u += 1) {
            var v: usize = 0;
            while (v < 8) : (v += 1) {
                const mcu_value = mcu[v * 8 + u];
                reconstructed_pixel += IDCTMultipliers[y][x][u][v] * @as(f32, @floatFromInt(mcu_value));
            }
        }

        const scaled_pixel = @round(reconstructed_pixel / 4.0);
        if (JPEG_DEBUG) {
            if (scaled_pixel < -128.0 or scaled_pixel > 127.0) {
                std.debug.print("Pixel at mcu={} x={} y={} component_id={} is out of bounds with DCT: {d}!\n", .{ mcu_id, x, y, component_id, scaled_pixel });
            }
        }

        return @intFromFloat(std.math.clamp(scaled_pixel, -128.0, 127.0));
    }
};

pub const JPEG = struct {
    frame: ?Frame = null,
    allocator: Allocator,
    quantization_tables: [4]?QuantizationTable,

    pub fn init(allocator: Allocator) JPEG {
        return .{
            .allocator = allocator,
            .quantization_tables = [_]?QuantizationTable{null} ** 4,
        };
    }

    pub fn deinit(self: *JPEG) void {
        if (self.frame) |*frame| {
            frame.deinit();
        }
    }

    fn parseDefineQuantizationTables(self: *JPEG, reader: Image.Stream.Reader) ImageReadError!void {
        var segment_size = try reader.readIntBig(u16);
        if (JPEG_DEBUG) std.debug.print("DefineQuantizationTables: segment size = 0x{X}\n", .{segment_size});
        segment_size -= 2;

        while (segment_size > 0) {
            const precision_and_destination = try reader.readByte();
            const table_precision = precision_and_destination >> 4;
            const table_destination = precision_and_destination & 0b11;

            const quantization_table = try QuantizationTable.read(table_precision, reader);
            switch (quantization_table) {
                .q8 => segment_size -= 64 + 1,
                .q16 => segment_size -= 128 + 1,
            }

            self.quantization_tables[table_destination] = quantization_table;
            if (JPEG_DEBUG) std.debug.print("  Table with precision {} installed at {}\n", .{ table_precision, table_destination });
        }
    }

    fn parseScan(self: *JPEG, reader: Image.Stream.Reader, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        if (self.frame) |frame| {
            try Scan.performScan(&frame, reader, pixels_opt);
        } else return ImageReadError.InvalidData;
    }

    fn initializePixels(self: *JPEG, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        if (self.frame) |frame| {
            var pixel_format: PixelFormat = undefined;
            switch (frame.frame_header.components.len) {
                1 => pixel_format = .grayscale8,
                3 => pixel_format = .rgb24,
                else => unreachable,
            }

            const pixel_count = @as(usize, @intCast(frame.frame_header.samples_per_row)) * @as(usize, @intCast(frame.frame_header.row_count));
            pixels_opt.* = try color.PixelStorage.init(self.allocator, pixel_format, pixel_count);
        } else return ImageReadError.InvalidData;
    }

    pub fn read(self: *JPEG, stream: *Image.Stream, pixels_opt: *?color.PixelStorage) ImageReadError!Frame {
        const jfif_header = JFIFHeader.read(stream) catch |err| switch (err) {
            error.App0MarkerDoesNotExist, error.JfifIdentifierNotSet, error.ThumbnailImagesUnsupported, error.ExtraneousApplicationMarker => return ImageReadError.InvalidData,
            else => |e| return e,
        };
        _ = jfif_header;

        errdefer {
            if (pixels_opt.*) |pixels| {
                pixels.deinit(self.allocator);
                pixels_opt.* = null;
            }
        }

        const reader = stream.reader();
        var marker = try reader.readIntBig(u16);
        while (marker != @intFromEnum(Markers.end_of_image)) : (marker = try reader.readIntBig(u16)) {
            if (JPEG_DEBUG) std.debug.print("Parsing marker value: 0x{X}\n", .{marker});

            if (marker >= @intFromEnum(Markers.application0) and marker < @intFromEnum(Markers.application0) + 16) {
                if (JPEG_DEBUG) std.debug.print("Skipping application data segment\n", .{});
                const application_data_length = try reader.readIntBig(u16);
                try stream.seekBy(application_data_length - 2);
                continue;
            }

            switch (@as(Markers, @enumFromInt(marker))) {
                // TODO(angelo): this should be moved inside the frameheader, it's part of thet
                // and then the header just dispatches correctly what to do with it.
                // JPEG should be as clear as possible
                .sof0 => {  // Baseline DCT
                    if (self.frame != null) {
                        return ImageError.Unsupported;
                    }

                    self.frame = try Frame.read(self.allocator, &self.quantization_tables, stream);
                },

                .sof1 => return ImageError.Unsupported,  // extended sequential DCT Huffman coding
                .sof2 => return ImageError.Unsupported,  // progressive DCT Huffman coding
                .sof3 => return ImageError.Unsupported,  // lossless (sequential) Huffman coding
                .sof5 => return ImageError.Unsupported,
                .sof6 => return ImageError.Unsupported,
                .sof7 => return ImageError.Unsupported,
                .sof9 => return ImageError.Unsupported,   // extended sequential DCT arithmetic coding
                .sof10 => return ImageError.Unsupported,  // progressive DCT arithmetic coding
                .sof11 => return ImageError.Unsupported,  // lossless (sequential) arithmetic coding
                .sof13 => return ImageError.Unsupported,
                .sof14 => return ImageError.Unsupported,
                .sof15 => return ImageError.Unsupported,

                .start_of_scan => {
                    try self.initializePixels(pixels_opt);
                    try self.parseScan(reader, pixels_opt);
                },

                .define_quantization_tables => {
                    try self.parseDefineQuantizationTables(reader);
                },

                .comment => {
                    if (JPEG_DEBUG) std.debug.print("Skipping comment segment\n", .{});

                    const comment_length = try reader.readIntBig(u16);
                    try stream.seekBy(comment_length - 2);
                },

                else => {
                    // TODO(angelo): raise invalid marker, more precise error.
                    return ImageReadError.InvalidData;
                },
            }
        }

        return if (self.frame) |frame| frame else ImageReadError.InvalidData;
    }

    // Format interface
    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    fn format() Image.Format {
        return Image.Format.jpg;
    }

    fn formatDetect(stream: *Image.Stream) ImageReadError!bool {
        const reader = stream.reader();
        const maybe_start_of_image = try reader.readIntBig(u16);
        if (maybe_start_of_image != @intFromEnum(Markers.start_of_image)) {
            return false;
        }

        try stream.seekTo(6);
        var identifier_buffer: [4]u8 = undefined;
        _ = try stream.read(identifier_buffer[0..]);

        return std.mem.eql(u8, identifier_buffer[0..], "JFIF");
    }

    fn readImage(allocator: Allocator, stream: *Image.Stream) ImageReadError!Image {
        var result = Image.init(allocator);
        errdefer result.deinit();
        var jpeg = JPEG.init(allocator);
        defer jpeg.deinit();

        var pixels_opt: ?color.PixelStorage = null;

        const frame = try jpeg.read(stream, &pixels_opt);

        result.width = frame.frame_header.samples_per_row;
        result.height = frame.frame_header.row_count;

        if (pixels_opt) |pixels| {
            result.pixels = pixels;
        } else {
            return ImageReadError.InvalidData;
        }

        return result;
    }

    fn writeImage(allocator: Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) ImageWriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }
};
