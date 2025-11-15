const std = @import("std");
const Image = @import("../../Image.zig");
const color = @import("../../color.zig");
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const math = std.math;
const utils = @import("./utils.zig");
const huffman = @import("./huffman.zig");
const quantization = @import("./quantization.zig");
const FrameHeader = @import("./FrameHeader.zig");

const Block = utils.Block;
const MAX_BLOCKS = utils.MAX_BLOCKS;
const MAX_COMPONENTS = utils.MAX_COMPONENTS;
const ZigzagOffsets = utils.ZigzagOffsets;
const Markers = utils.Markers;

const block_size = 64;
const QuantIndex = enum(u8) {
    luminance,
    chrominance,
};
const quant_index_size = @typeInfo(QuantIndex).@"enum".fields.len;

const n_huff_index = 4;
const HuffmanIndex = enum(usize) {
    luminance_dc,
    luminance_ac,
    chrominance_dc,
    chrominance_ac,
};

// Huffman table specification type (reusing existing huffman.Table structure)
const HuffmanSpec = struct {
    count: [16]u8,
    value: []const u8,
};

// Huffman table specifications
const huffman_spec = [n_huff_index]HuffmanSpec{
    // Luminance DC
    .{
        .count = [_]u8{ 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        .value = &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
    },
    // Luminance AC
    .{
        .count = [_]u8{ 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125 },
        .value = &[_]u8{
            0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
            0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
            0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
            0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
            0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
            0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
            0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
            0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
            0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
            0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
            0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
            0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
            0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
            0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
            0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
            0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
            0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
            0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
            0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
            0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
            0xf9, 0xfa,
        },
    },
    // Chrominance DC
    .{
        .count = [_]u8{ 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
        .value = &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
    },
    // Chrominance AC
    .{
        .count = [_]u8{ 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119 },
        .value = &[_]u8{
            0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
            0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
            0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
            0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
            0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
            0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
            0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
            0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
            0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
            0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
            0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
            0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
            0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
            0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
            0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
            0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
            0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
            0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
            0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
            0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
            0xf9, 0xfa,
        },
    },
};

// Unscaled quantization tables in zig-zag order. Each encoder copies and scales
// the tables according to its quality parameter.
// The values are derived from section K.1 of the spec, after converting from
// natural to zig-zag order.
const unscaled_quant = [quant_index_size][block_size]u8{
    // Luminance.
    [_]u8{
        16,  11,  12,  14,  12,  10,  16,  14,
        13,  14,  18,  17,  16,  19,  24,  40,
        26,  24,  22,  22,  24,  49,  35,  37,
        29,  40,  58,  51,  61,  60,  57,  51,
        56,  55,  64,  72,  92,  78,  64,  68,
        87,  69,  55,  56,  80,  109, 81,  87,
        95,  98,  103, 104, 103, 62,  77,  113,
        121, 112, 100, 120, 92,  101, 103, 99,
    },
    // Chrominance.
    [_]u8{
        17, 18, 18, 24, 21, 24, 47, 26,
        26, 47, 99, 66, 56, 66, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
    },
};

// Huffman LUT entry: 8-bit size in MSB, 24-bit code in LSB
const default_huffman_lut = blk: {
    var tables: [n_huff_index][256]u32 = undefined;
    for (huffman_spec, 0..) |spec, idx| {
        tables[idx] = initHuffmanLUT(spec);
    }
    break :blk tables;
};

// Zigzag ordering for DCT coefficients (same as JPEG spec)
const unzig = [block_size]u8{
    0,  1,  8,  16, 9,  2,  3,  10,
    17, 24, 32, 25, 18, 11, 4,  5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6,  7,  14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
};

// div returns a/b rounded to the nearest integer, instead of rounded to zero
fn div(a: i32, b: i32) i32 {
    if (a >= 0) {
        return @divTrunc((a + (b >> 1)), b);
    } else {
        return -@divTrunc((-a + (b >> 1)), b);
    }
}

// Initialize Huffman LUT from Huffman specification
fn initHuffmanLUT(spec: HuffmanSpec) [256]u32 {
    var lut: [256]u32 = [_]u32{0} ** 256;

    var code: u32 = 0;
    var value_index: usize = 0;

    for (spec.count, 0..) |count, depth| {
        const bit_count = @as(u32, @intCast(depth + 1));
        for (0..count) |_| {
            std.debug.assert(value_index < spec.value.len);
            const symbol = spec.value[value_index];
            lut[symbol] = (bit_count << 24) | code;
            code += 1;
            value_index += 1;
        }
        code <<= 1;
    }

    return lut;
}

/// JPEGWriter handles encoding images to JPEG format
pub const JPEGWriter = struct {
    writer: *std.Io.Writer,
    err: ?Image.WriteError = null,
    buf: [16]u8 = undefined,
    bits: u32 = 0,
    n_bits: u6 = 0,
    quant: [quant_index_size][block_size]u8 = undefined, // Scaled quantization tables (using zigzag ordering)
    huffman_lut: [n_huff_index][256]u32 = undefined, // Huffman look-up tables

    /// Initialize a new JPEG writer
    pub fn init(writer: *std.Io.Writer) JPEGWriter {
        return .{
            .writer = writer,
            .huffman_lut = default_huffman_lut,
        };
    }

    /// Encode an image to JPEG format
    pub fn encode(self: *JPEGWriter, image: Image, quality: u8) Image.WriteError!void {
        const clamped_quality = math.clamp(quality, @as(u8, 1), @as(u8, 100));
        self.initializeQuantizationTables(clamped_quality);

        const width: u16 = @intCast(image.width);
        const height: u16 = @intCast(image.height);
        const component_count = componentCount(image);

        try self.writeSOI();
        try self.writeDQT();
        try self.writeSOF0(width, height, component_count);
        try self.writeDHT(component_count);
        try self.writeSOS(image, component_count);

        if (self.err) |err| {
            return err;
        }

        try self.writeEOI();
        try self.flush();

        if (self.err) |err| {
            return err;
        }
    }

    /// Initialize quantization tables based on quality parameter
    fn initializeQuantizationTables(self: *JPEGWriter, quality: u8) void {
        const scale_factor: i32 = if (quality < 50)
            @divTrunc(5000, @as(i32, quality))
        else
            200 - @as(i32, quality) * 2;

        for (0..quant_index_size) |table_index| {
            for (0..block_size) |coeff_index| {
                const base = @as(i32, unscaled_quant[table_index][coeff_index]);
                var scaled = @divTrunc(base * scale_factor + 50, 100);
                scaled = math.clamp(scaled, @as(i32, 1), @as(i32, 255));
                self.quant[table_index][coeff_index] = @intCast(scaled);
            }
        }
    }

    /// Get the number of components based on image pixel format
    fn componentCount(image: Image) u8 {
        return switch (image.pixels) {
            .grayscale8 => 1,
            .rgb24 => 3,
            else => unreachable,
        };
    }

    /// Write Start of Image marker
    pub fn writeSOI(self: *JPEGWriter) Image.WriteError!void {
        try self.writeMarker(Markers.start_of_image);
    }

    /// Write End of Image marker
    pub fn writeEOI(self: *JPEGWriter) Image.WriteError!void {
        try self.writeMarker(Markers.end_of_image);
    }

    /// Write Start of Frame (Baseline DCT) marker
    pub fn writeSOF0(self: *JPEGWriter, width: u16, height: u16, components: u8) Image.WriteError!void {
        const component_count = @as(usize, components);
        const marker_len = 8 + 3 * component_count;

        try self.writeMarkerHeader(Markers.sof0, marker_len);

        var header: [6]u8 = .{
            8,
            @as(u8, @intCast(height >> 8)),
            @as(u8, @intCast(height & 0xff)),
            @as(u8, @intCast(width >> 8)),
            @as(u8, @intCast(width & 0xff)),
            components,
        };
        try self.writer.writeAll(header[0..]);

        var component_bytes: [MAX_COMPONENTS * 3]u8 = undefined;
        var idx: usize = 0;

        switch (components) {
            1 => {
                component_bytes[idx + 0] = 1; // Component ID
                component_bytes[idx + 1] = 0x11; // 4:4:4 sampling
                component_bytes[idx + 2] = 0; // Quant table selector
                idx += 3;
            },
            3 => {
                component_bytes[idx + 0] = 1;
                component_bytes[idx + 1] = 0x22; // 4:2:0 sampling for Y
                component_bytes[idx + 2] = 0;
                component_bytes[idx + 3] = 2;
                component_bytes[idx + 4] = 0x11;
                component_bytes[idx + 5] = 1;
                component_bytes[idx + 6] = 3;
                component_bytes[idx + 7] = 0x11;
                component_bytes[idx + 8] = 1;
                idx += 9;
            },
            else => unreachable,
        }

        try self.writer.writeAll(component_bytes[0..idx]);
    }

    /// Write Define Quantization Tables marker
    pub fn writeDQT(self: *JPEGWriter) Image.WriteError!void {
        const marker_len = 2 + quant_index_size * (1 + block_size);
        try self.writeMarkerHeader(Markers.define_quantization_tables, marker_len);

        for (self.quant, 0..) |table, idx| {
            try self.writer.writeByte(@as(u8, @intCast(idx)));
            try self.writer.writeAll(table[0..]);
        }
    }

    /// Write Define Huffman Tables marker
    pub fn writeDHT(self: *JPEGWriter, component_count: u8) Image.WriteError!void {
        var marker_len: usize = 2;
        const specs_len: usize = if (component_count == 1) 2 else n_huff_index;

        for (huffman_spec[0..specs_len]) |spec| {
            marker_len += 1 + spec.count.len + spec.value.len;
        }

        try self.writeMarkerHeader(Markers.define_huffman_tables, marker_len);

        const table_classes = [_]u8{ 0x00, 0x10, 0x01, 0x11 };
        for (huffman_spec[0..specs_len], 0..) |spec, idx| {
            try self.writer.writeByte(table_classes[idx]);
            try self.writer.writeAll(spec.count[0..]);
            try self.writer.writeAll(spec.value);
        }
    }

    /// Write Start of Scan marker and entropy-coded data
    pub fn writeSOS(self: *JPEGWriter, image: Image, component_count: u8) Image.WriteError!void {
        const comp_usize = @as(usize, component_count);
        const marker_len = 6 + 2 * comp_usize;
        try self.writeMarkerHeader(Markers.start_of_scan, marker_len);

        var payload: [1 + MAX_COMPONENTS * 2 + 3]u8 = undefined;
        payload[0] = component_count;
        var offset: usize = 1;

        switch (component_count) {
            1 => {
                payload[offset + 0] = 1;
                payload[offset + 1] = 0x00;
                offset += 2;
            },
            3 => {
                payload[offset + 0] = 1;
                payload[offset + 1] = 0x00;
                payload[offset + 2] = 2;
                payload[offset + 3] = 0x11;
                payload[offset + 4] = 3;
                payload[offset + 5] = 0x11;
                offset += 6;
            },
            else => unreachable,
        }

        payload[offset + 0] = 0x00;
        payload[offset + 1] = 0x3f;
        payload[offset + 2] = 0x00;
        offset += 3;

        try self.writer.writeAll(payload[0..offset]);
        try self.writeImageData(image, component_count);
        try self.finishEntropy();
    }

    /// Write a generic marker header with length
    fn writeMarkerHeader(self: *JPEGWriter, marker: Markers, marker_len: usize) Image.WriteError!void {
        std.debug.assert(marker_len <= math.maxInt(u16));

        const value = @intFromEnum(marker);
        self.buf[0] = @as(u8, @intCast(value >> 8));
        self.buf[1] = @as(u8, @intCast(value & 0xff));
        self.buf[2] = @as(u8, @intCast(marker_len >> 8));
        self.buf[3] = @as(u8, @intCast(marker_len & 0xff));
        try self.writer.writeAll(self.buf[0..4]);
    }

    fn writeMarker(self: *JPEGWriter, marker: Markers) Image.WriteError!void {
        const value = @intFromEnum(marker);
        self.buf[0] = @as(u8, @intCast(value >> 8));
        self.buf[1] = @as(u8, @intCast(value & 0xff));
        try self.writer.writeAll(self.buf[0..2]);
    }

    /// Emit bits to the output stream
    pub fn emit(self: *JPEGWriter, bits: u32, n_bits: u5) Image.WriteError!void {
        if (self.err != null) return;

        std.debug.assert(n_bits > 0 and n_bits <= 16);
        std.debug.assert(bits < (@as(u32, 1) << n_bits));

        var n_bits_mut = @as(u32, n_bits) + @as(u32, self.n_bits);
        const shift_amount = @as(u5, @intCast(@min(32 - n_bits_mut, 31)));
        var bits_mut = (bits << shift_amount) | self.bits;

        while (n_bits_mut >= 8) {
            const byte = @as(u8, @intCast(bits_mut >> 24));
            self.writeByte(byte);
            if (byte == 0xff) {
                self.writeByte(0x00);
            }
            bits_mut <<= @as(u5, 8);
            n_bits_mut -= 8;
        }

        self.bits = bits_mut;
        self.n_bits = @as(u6, @intCast(n_bits_mut));
    }

    /// Write a single byte, handling errors
    fn writeByte(self: *JPEGWriter, b: u8) void {
        if (self.err != null) return;
        self.writer.writeByte(b) catch |err| {
            self.err = err;
        };
    }

    /// Emit Huffman-encoded value
    pub fn emitHuff(self: *JPEGWriter, huff_index: usize, value: u8) Image.WriteError!void {
        if (self.err != null) return;

        const entry = self.huffman_lut[huff_index][value];
        const n_bits_u32 = entry >> 24;
        if (n_bits_u32 == 0) return Image.WriteError.InvalidData;

        const n_bits: u5 = @intCast(n_bits_u32);
        const code = entry & 0x00FF_FFFF;
        try self.emit(code, n_bits);
    }

    /// Process and write an 8x8 DCT block
    pub fn writeBlock(self: *JPEGWriter, block: *[64]i32, quant_idx: QuantIndex, prev_dc: i32) Image.WriteError!i32 {
        if (self.err != null) return 0;

        fdct(block);

        const dc_table = @intFromEnum(quant_idx) * 2;
        const ac_table = dc_table + 1;

        const dc_quant = 8 * @as(i32, self.quant[@intFromEnum(quant_idx)][0]);
        const dc = div(block[0], dc_quant);
        try self.emitHuffRLE(dc_table, 0, dc - prev_dc);

        var run_length: i32 = 0;

        for (1..block_size) |zig| {
            const quant = 8 * @as(i32, self.quant[@intFromEnum(quant_idx)][zig]);
            const ac = div(block[unzig[zig]], quant);

            if (ac == 0) {
                run_length += 1;
                continue;
            }

            while (run_length > 15) {
                try self.emitHuff(ac_table, 0xf0);
                run_length -= 16;
            }

            try self.emitHuffRLE(ac_table, run_length, ac);
            run_length = 0;
        }

        if (run_length > 0) {
            try self.emitHuff(ac_table, 0x00);
        }

        if (self.err) |err| return err;
        return dc;
    }

    /// Convert RGB image data to YCbCr color space for a single 8x8 block
    pub fn rgbToYCbCr(
        self: *JPEGWriter,
        image: Image,
        px: i32,
        py: i32,
        y_block: *[64]i32,
        cb_block: *[64]i32,
        cr_block: *[64]i32,
    ) void {
        _ = self;

        const max_x: i32 = @intCast(image.width - 1);
        const max_y: i32 = @intCast(image.height - 1);

        for (0..8) |j| {
            for (0..8) |i| {
                const sx = math.clamp(px + @as(i32, @intCast(i)), @as(i32, 0), max_x);
                const sy = math.clamp(py + @as(i32, @intCast(j)), @as(i32, 0), max_y);

                const x = @as(usize, @intCast(sx));
                const y = @as(usize, @intCast(sy));
                const pixel_index = y * image.width + x;
                const pixel = image.pixels.rgb24[pixel_index];

                const r_i = @as(i32, pixel.r);
                const g_i = @as(i32, pixel.g);
                const b_i = @as(i32, pixel.b);

                const yy = (19595 * r_i + 38470 * g_i + 7471 * b_i + 32768) >> 16;
                const cb = (-11059 * r_i - 21709 * g_i + 32768 * b_i + ((128 << 16) + 32768)) >> 16;
                const cr = (32768 * r_i - 27439 * g_i - 5329 * b_i + ((128 << 16) + 32768)) >> 16;

                const block_index = j * 8 + i;
                y_block[block_index] = math.clamp(yy, @as(i32, 0), @as(i32, 255));
                cb_block[block_index] = math.clamp(cb, @as(i32, 0), @as(i32, 255));
                cr_block[block_index] = math.clamp(cr, @as(i32, 0), @as(i32, 255));
            }
        }
    }

    /// Convert grayscale image data to Y block
    pub fn grayToY(self: *JPEGWriter, image: Image, px: i32, py: i32, y_block: *[64]i32) void {
        _ = self;

        const max_x: i32 = @intCast(image.width - 1);
        const max_y: i32 = @intCast(image.height - 1);

        for (0..8) |j| {
            for (0..8) |i| {
                const sx = math.clamp(px + @as(i32, @intCast(i)), @as(i32, 0), max_x);
                const sy = math.clamp(py + @as(i32, @intCast(j)), @as(i32, 0), max_y);

                const x = @as(usize, @intCast(sx));
                const y = @as(usize, @intCast(sy));
                const pixel_index = y * image.width + x;
                const gray = image.pixels.grayscale8[pixel_index];

                y_block[j * 8 + i] = @as(i32, gray.value);
            }
        }
    }

    /// Scale 4 chroma blocks (16x16) down to 1 chroma block (8x8) for 4:2:0 subsampling
    pub fn scale(dst: *[64]i32, src: *const [4][64]i32) void {
        for (0..4) |i| {
            const dst_off = (@as(u8, @intCast(i & 2)) << 4) | (@as(u8, @intCast(i & 1)) << 2);

            for (0..4) |y| {
                for (0..4) |x| {
                    const j = 16 * y + 2 * x;
                    const sum = src[i][j] + src[i][j + 1] + src[i][j + 8] + src[i][j + 9];
                    dst[8 * y + x + dst_off] = (sum + 2) >> 2;
                }
            }
        }
    }

    /// Perform forward discrete cosine transform
    pub fn fdct(block: *[64]i32) void {
        const fix_0_298631336 = 2446;
        const fix_0_390180644 = 3196;
        const fix_0_541196100 = 4433;
        const fix_0_765366865 = 6270;
        const fix_0_899976223 = 7373;
        const fix_1_175875602 = 9633;
        const fix_1_501321110 = 12299;
        const fix_1_847759065 = 15137;
        const fix_1_961570560 = 16069;
        const fix_2_053119869 = 16819;
        const fix_2_562915447 = 20995;
        const fix_3_072711026 = 25172;

        const constBits = 13;
        const pass1Bits = 2;
        const centerJSample = 128;

        // Pass 1: process rows.
        var y: usize = 0;
        while (y < 8) : (y += 1) {
            const y8 = y * 8;
            const x0 = block[y8 + 0];
            const x1 = block[y8 + 1];
            const x2 = block[y8 + 2];
            const x3 = block[y8 + 3];
            const x4 = block[y8 + 4];
            const x5 = block[y8 + 5];
            const x6 = block[y8 + 6];
            const x7 = block[y8 + 7];

            var tmp0 = x0 + x7;
            var tmp1 = x1 + x6;
            var tmp2 = x2 + x5;
            var tmp3 = x3 + x4;

            var tmp10 = tmp0 + tmp3;
            var tmp12 = tmp0 - tmp3;
            var tmp11 = tmp1 + tmp2;
            var tmp13 = tmp1 - tmp2;

            tmp0 = x0 - x7;
            tmp1 = x1 - x6;
            tmp2 = x2 - x5;
            tmp3 = x3 - x4;

            block[y8 + 0] = (tmp10 + tmp11 - 8 * centerJSample) << pass1Bits;
            block[y8 + 4] = (tmp10 - tmp11) << pass1Bits;
            var z1 = (tmp12 + tmp13) * fix_0_541196100;
            z1 += 1 << (constBits - pass1Bits - 1);
            block[y8 + 2] = @as(i32, @intCast((z1 + tmp12 * fix_0_765366865) >> (@as(u6, constBits - pass1Bits))));
            block[y8 + 6] = @as(i32, @intCast((z1 - tmp13 * fix_1_847759065) >> (@as(u6, constBits - pass1Bits))));

            tmp10 = tmp0 + tmp3;
            tmp11 = tmp1 + tmp2;
            tmp12 = tmp0 + tmp2;
            tmp13 = tmp1 + tmp3;
            z1 = (tmp12 + tmp13) * fix_1_175875602;
            z1 += 1 << (constBits - pass1Bits - 1);
            tmp0 *= fix_1_501321110;
            tmp1 *= fix_3_072711026;
            tmp2 *= fix_2_053119869;
            tmp3 *= fix_0_298631336;
            tmp10 *= -fix_0_899976223;
            tmp11 *= -fix_2_562915447;
            tmp12 *= -fix_0_390180644;
            tmp13 *= -fix_1_961570560;

            tmp12 += z1;
            tmp13 += z1;
            block[y8 + 1] = @as(i32, @intCast((tmp0 + tmp10 + tmp12) >> (@as(u6, constBits - pass1Bits))));
            block[y8 + 3] = @as(i32, @intCast((tmp1 + tmp11 + tmp13) >> (@as(u6, constBits - pass1Bits))));
            block[y8 + 5] = @as(i32, @intCast((tmp2 + tmp11 + tmp12) >> (@as(u6, constBits - pass1Bits))));
            block[y8 + 7] = @as(i32, @intCast((tmp3 + tmp10 + tmp13) >> (@as(u6, constBits - pass1Bits))));
        }

        // Pass 2: process columns. Remove pass1Bits scaling, leave results scaled by 8.
        var x: usize = 0;
        while (x < 8) : (x += 1) {
            var tmp0 = block[0 * 8 + x] + block[7 * 8 + x];
            var tmp1 = block[1 * 8 + x] + block[6 * 8 + x];
            var tmp2 = block[2 * 8 + x] + block[5 * 8 + x];
            var tmp3 = block[3 * 8 + x] + block[4 * 8 + x];

            var tmp10 = tmp0 + tmp3 + (1 << (pass1Bits - 1));
            var tmp12 = tmp0 - tmp3;
            var tmp11 = tmp1 + tmp2;
            var tmp13 = tmp1 - tmp2;

            tmp0 = block[0 * 8 + x] - block[7 * 8 + x];
            tmp1 = block[1 * 8 + x] - block[6 * 8 + x];
            tmp2 = block[2 * 8 + x] - block[5 * 8 + x];
            tmp3 = block[3 * 8 + x] - block[4 * 8 + x];

            block[0 * 8 + x] = (tmp10 + tmp11) >> pass1Bits;
            block[4 * 8 + x] = (tmp10 - tmp11) >> pass1Bits;

            var z1 = (tmp12 + tmp13) * fix_0_541196100;
            z1 += 1 << (constBits + pass1Bits - 1);
            block[2 * 8 + x] = @as(i32, @intCast((z1 + tmp12 * fix_0_765366865) >> (@as(u6, constBits + pass1Bits))));
            block[6 * 8 + x] = @as(i32, @intCast((z1 - tmp13 * fix_1_847759065) >> (@as(u6, constBits + pass1Bits))));

            tmp10 = tmp0 + tmp3;
            tmp11 = tmp1 + tmp2;
            tmp12 = tmp0 + tmp2;
            tmp13 = tmp1 + tmp3;
            z1 = (tmp12 + tmp13) * fix_1_175875602;
            z1 += 1 << (constBits + pass1Bits - 1);
            tmp0 *= fix_1_501321110;
            tmp1 *= fix_3_072711026;
            tmp2 *= fix_2_053119869;
            tmp3 *= fix_0_298631336;
            tmp10 *= -fix_0_899976223;
            tmp11 *= -fix_2_562915447;
            tmp12 *= -fix_0_390180644;
            tmp13 *= -fix_1_961570560;

            tmp12 += z1;
            tmp13 += z1;
            block[1 * 8 + x] = @as(i32, @intCast((tmp0 + tmp10 + tmp12) >> (@as(u6, constBits + pass1Bits))));
            block[3 * 8 + x] = @as(i32, @intCast((tmp1 + tmp11 + tmp13) >> (@as(u6, constBits + pass1Bits))));
            block[5 * 8 + x] = @as(i32, @intCast((tmp2 + tmp11 + tmp12) >> (@as(u6, constBits + pass1Bits))));
            block[7 * 8 + x] = @as(i32, @intCast((tmp3 + tmp10 + tmp13) >> (@as(u6, constBits + pass1Bits))));
        }
    }

    /// Flush any remaining buffered data
    pub fn flush(self: *JPEGWriter) Image.WriteError!void {
        if (self.err) |err| return err;
        if (self.n_bits != 0) {
            self.err = Image.WriteError.UnfinishedBits;
            return Image.WriteError.UnfinishedBits;
        }

        // Flush the writer
        try self.writer.flush();
    }

    /// Write the actual image data (scan/entropy coded data)
    pub fn writeImageData(self: *JPEGWriter, image: Image, component_count: u8) Image.WriteError!void {
        if (self.err != null) return;

        std.debug.assert(component_count == 1 or component_count == 3);

        var y_block: [64]i32 = undefined;
        var cb_blocks: [4][64]i32 = undefined;
        var cr_blocks: [4][64]i32 = undefined;
        var cb_macro: [64]i32 = undefined;
        var cr_macro: [64]i32 = undefined;

        var prev_dc_y: i32 = 0;
        var prev_dc_cb: i32 = 0;
        var prev_dc_cr: i32 = 0;

        const width_i32: i32 = @intCast(image.width);
        const height_i32: i32 = @intCast(image.height);

        if (component_count == 1) {
            var y: i32 = 0;
            while (y < height_i32) : (y += 8) {
                var x: i32 = 0;
                while (x < width_i32) : (x += 8) {
                    self.grayToY(image, x, y, &y_block);
                    prev_dc_y = try self.writeBlock(&y_block, .luminance, prev_dc_y);
                    if (self.err) |err| return err;
                }
            }
            return;
        }

        var y_blocks: [4][64]i32 = undefined;
        var macro_y: i32 = 0;
        while (macro_y < height_i32) : (macro_y += 16) {
            var macro_x: i32 = 0;
            while (macro_x < width_i32) : (macro_x += 16) {
                for (0..4) |i| {
                    const x_off = @as(i32, @intCast(i & 1)) * 8;
                    const y_off = @as(i32, @intCast((i >> 1) & 1)) * 8;
                    self.rgbToYCbCr(image, macro_x + x_off, macro_y + y_off, &y_blocks[i], &cb_blocks[i], &cr_blocks[i]);
                    prev_dc_y = try self.writeBlock(&y_blocks[i], .luminance, prev_dc_y);
                    if (self.err) |err| return err;
                }

                scale(&cb_macro, &cb_blocks);
                prev_dc_cb = try self.writeBlock(&cb_macro, .chrominance, prev_dc_cb);
                if (self.err) |err| return err;

                scale(&cr_macro, &cr_blocks);
                prev_dc_cr = try self.writeBlock(&cr_macro, .chrominance, prev_dc_cr);
                if (self.err) |err| return err;
            }
        }
    }

    fn finishEntropy(self: *JPEGWriter) Image.WriteError!void {
        if (self.err != null) return;

        const pending: u6 = self.n_bits;
        if (pending == 0) return;

        const pad_count: u5 = @intCast(8 - @as(u32, pending));
        if (pad_count == 0) return;

        const pad_bits: u32 = (@as(u32, 1) << pad_count) - 1;
        try self.emit(pad_bits, pad_count);
        self.bits = 0;
        self.n_bits = 0;
    }

    /// Emit Huffman-encoded value with run-length encoding
    pub fn emitHuffRLE(self: *JPEGWriter, huff_index: usize, run_length: i32, value: i32) Image.WriteError!void {
        if (self.err != null) return;

        std.debug.assert(run_length >= 0 and run_length <= 15);

        var magnitude = value;
        var payload = value;
        if (magnitude < 0) {
            magnitude = -value;
            payload = value - 1;
        }

        const bit_count_lut = [_]u8{
            0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4,
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
            6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
            6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        };

        const mag_u32: u32 = @intCast(magnitude);
        const bit_size: u5 = if (mag_u32 < 0x100)
            @intCast(bit_count_lut[@as(usize, mag_u32)])
        else
            @intCast(8 + bit_count_lut[@as(usize, mag_u32 >> 8)]);

        const symbol: u8 = @intCast((run_length << 4) | @as(i32, bit_size));
        try self.emitHuff(huff_index, symbol);

        if (bit_size > 0) {
            const payload_bits = @as(u32, @bitCast(payload));
            const mask = (@as(u32, 1) << bit_size) - 1;
            const bits_to_emit = payload_bits & mask;
            try self.emit(bits_to_emit, bit_size);
        }
    }

    /// Validate that an image can be encoded as JPEG
    pub fn validateImage(image: Image) Image.WriteError!void {
        // Check supported pixel formats
        switch (image.pixels) {
            .grayscale8, .rgb24 => {
                // These formats are supported
            },
            else => {
                return Image.WriteError.InvalidData;
            },
        }

        // Check image dimensions
        if (image.width == 0 or image.height == 0) {
            return Image.WriteError.InvalidData;
        }

        // Check maximum dimensions (JPEG spec limit)
        if (image.width >= 1 << 16 or image.height >= 1 << 16) {
            return Image.WriteError.InvalidData;
        }
    }
};
