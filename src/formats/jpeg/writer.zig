const std = @import("std");
const ImageUnmanaged = @import("../../ImageUnmanaged.zig");
const color = @import("../../color.zig");
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const math = std.math;
const utils = @import("./utils.zig");
const huffman = @import("./huffman.zig");

// Constants from the Go implementation
const blockSize = 64;
const nQuantIndex = 2;
const quantIndexLuminance = 0;
const quantIndexChrominance = 1;
const nHuffIndex = 4;
const huffIndexLuminanceDC = 0;
const huffIndexLuminanceAC = 1;
const huffIndexChrominanceDC = 2;
const huffIndexChrominanceAC = 3;

// Huffman index aliases for convenience
const huffIndex = struct {
    pub const luminanceDC = huffIndexLuminanceDC;
    pub const luminanceAC = huffIndexLuminanceAC;
    pub const chrominanceDC = huffIndexChrominanceDC;
    pub const chrominanceAC = huffIndexChrominanceAC;
};

// Huffman table specification type (reusing existing huffman.Table structure)
const HuffmanSpec = struct {
    count: [16]u8,
    value: []const u8,
};

// Huffman table specifications (from Go's theHuffmanSpec)
const theHuffmanSpec = [nHuffIndex]HuffmanSpec{
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

// DefaultQuality is the default quality encoding parameter.
const DefaultQuality = 75;

// Unscaled quantization tables in zig-zag order. Each encoder copies and scales
// the tables according to its quality parameter.
// The values are derived from section K.1 of the spec, after converting from
// natural to zig-zag order.
const unscaledQuant = [nQuantIndex][blockSize]u8{
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
const huffmanLUT = [256]u32;

// Zigzag ordering for DCT coefficients (same as JPEG spec)
const unzig = [blockSize]u8{
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
    var lut = [_]u32{0} ** 256;

    var code: u32 = 0;
    var k: usize = 0;

    // Generate Huffman codes from specification (same as Go implementation)
    for (0..16) |i| {
        const n_bits = @as(u32, @intCast(i + 1)) << 24;
        const count = spec.count[i];

        var j: u8 = 0;
        while (j < count) : (j += 1) {
            if (k < spec.value.len) {
                const value = spec.value[k];
                lut[value] = n_bits | code;
                code += 1;
                k += 1;
            }
        }
        code <<= 1;
    }

    return lut;
}

/// JPEGWriter handles encoding images to JPEG format
pub const JPEGWriter = struct {
    writer: std.io.AnyWriter,
    err: ?ImageUnmanaged.WriteError = null,
    buf: [16]u8 = undefined,
    bits: u32 = 0,
    n_bits: u32 = 0,
    quant: [nQuantIndex][blockSize]u8 = undefined, // Scaled quantization tables
    huffman_lut: [nHuffIndex][256]u32 = undefined, // Huffman look-up tables

    /// Initialize a new JPEG writer
    pub fn init(writer: std.io.AnyWriter) JPEGWriter {
        var jpeg_writer = JPEGWriter{
            .writer = writer,
        };

        // Initialize Huffman LUTs for each table using the specifications
        for (0..nHuffIndex) |i| {
            jpeg_writer.huffman_lut[i] = initHuffmanLUT(theHuffmanSpec[i]);
        }

        return jpeg_writer;
    }

    /// Encode an image to JPEG format (based on Go's Encode function)
    pub fn encode(self: *JPEGWriter, image: ImageUnmanaged, quality: u8) ImageUnmanaged.WriteError!void {

        // Validate image dimensions
        if (image.width >= 1 << 16 or image.height >= 1 << 16) {
            return ImageUnmanaged.WriteError.InvalidData;
        }

        // Clip quality to [1, 100]
        var clamped_quality = quality;
        if (clamped_quality < 1) {
            clamped_quality = 1;
        } else if (clamped_quality > 100) {
            clamped_quality = 100;
        }

        // Initialize quantization tables based on quality
        try self.initializeQuantizationTables(clamped_quality);

        // Determine number of components based on image type
        const nComponent = self.getComponentCount(image);

        // Write Start Of Image marker
        try self.writeSOI();

        // Write quantization tables
        try self.writeDQT();

        // Write Start of Frame
        try self.writeSOF0(@as(u16, @intCast(image.width)), @as(u16, @intCast(image.height)), nComponent);

        // Write Huffman tables
        try self.writeDHT(nComponent);

        // Write image data (Start of Scan)
        try self.writeSOS(image);

        // Write End Of Image marker
        try self.writeEOI();

        // Flush any remaining data
        try self.flush();

        // Return any error that occurred during writing
        if (self.err) |err| {
            return err;
        }
    }

    /// Initialize quantization tables based on quality parameter
    fn initializeQuantizationTables(self: *JPEGWriter, quality: u8) ImageUnmanaged.WriteError!void {
        // Convert from a quality rating to a scaling factor
        var scale_factor: i32 = undefined;
        if (quality < 50) {
            scale_factor = @divTrunc(5000, @as(i32, quality));
        } else {
            scale_factor = 200 - @as(i32, quality) * 2;
        }

        if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG) {
            std.debug.print("Quality: {}, Scale factor: {}\n", .{ quality, scale_factor });
        }

        // Scale the quantization tables
        for (0..nQuantIndex) |i| {
            for (0..blockSize) |j| {
                var x = @as(i32, unscaledQuant[i][j]);
                x = @divTrunc((x * scale_factor + 50), 100);
                if (x < 1) x = 1;
                if (x > 255) x = 255;
                self.quant[i][j] = @as(u8, @intCast(x));
            }

            // Debug: Print first few quantization values
            if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and i == 0) {
                std.debug.print("Luminance quant table (first 8): ", .{});
                for (0..8) |j| {
                    std.debug.print("{} ", .{self.quant[i][j]});
                }
                std.debug.print("\n", .{});
            }
        }
    }

    /// Get the number of components based on image pixel format
    fn getComponentCount(self: *JPEGWriter, image: ImageUnmanaged) u8 {
        _ = self;
        // For now, assume RGB images have 3 components, grayscale have 1
        switch (image.pixels) {
            .grayscale8 => return 1,
            .rgb24 => return 3,
            else => return 3, // Default to 3 components
        }
    }

    /// Write Start of Image marker
    pub fn writeSOI(self: *JPEGWriter) ImageUnmanaged.WriteError!void {
        self.buf[0] = 0xff;
        self.buf[1] = 0xd8; // SOI marker
        _ = self.writer.write(self.buf[0..2]) catch {
            self.err = ImageUnmanaged.WriteError.InvalidData;
            return ImageUnmanaged.WriteError.InvalidData;
        };
    }

    /// Write End of Image marker
    pub fn writeEOI(self: *JPEGWriter) ImageUnmanaged.WriteError!void {
        self.buf[0] = 0xff;
        self.buf[1] = 0xd9; // EOI marker
        _ = self.writer.write(self.buf[0..2]) catch {
            self.err = ImageUnmanaged.WriteError.InvalidData;
            return ImageUnmanaged.WriteError.InvalidData;
        };
    }

    /// Write Start of Frame (Baseline DCT) marker
    pub fn writeSOF0(self: *JPEGWriter, width: u16, height: u16, components: u8) ImageUnmanaged.WriteError!void {
        const markerlen = 8 + 3 * @as(usize, components);
        self.writeMarkerHeader(@as(u8, @intCast(@intFromEnum(utils.Markers.sof0) & 0xFF)), markerlen); // SOF0 marker

        // 8-bit precision
        self.buf[0] = 8;
        // Image dimensions
        self.buf[1] = @as(u8, @intCast(height >> 8));
        self.buf[2] = @as(u8, @intCast(height & 0xff));
        self.buf[3] = @as(u8, @intCast(width >> 8));
        self.buf[4] = @as(u8, @intCast(width & 0xff));
        // Number of components
        self.buf[5] = components;

        _ = self.writer.write(self.buf[0..6]) catch {
            self.err = ImageUnmanaged.WriteError.InvalidData;
            return ImageUnmanaged.WriteError.InvalidData;
        };

        // Component specifications
        if (components == 1) {
            // Grayscale
            self.buf[0] = 1; // Component ID
            self.buf[1] = 0x11; // 4:4:4 subsampling
            self.buf[2] = 0; // Quantization table
            _ = self.writer.write(self.buf[0..3]) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        } else {
            // Color components
            const subsampling = [_]u8{ 0x22, 0x11, 0x11 }; // 4:2:0 subsampling
            const quant_tables = [_]u8{ 0, 1, 1 }; // Y uses table 0, Cb and Cr use table 1
            for (0..components) |i| {
                self.buf[3 * i] = @as(u8, @intCast(i + 1)); // Component ID
                self.buf[3 * i + 1] = subsampling[i]; // Subsampling
                self.buf[3 * i + 2] = quant_tables[i]; // Quantization table
            }
            _ = self.writer.write(self.buf[0 .. 3 * @as(usize, components)]) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        }
    }

    /// Write Define Quantization Tables marker
    pub fn writeDQT(self: *JPEGWriter) ImageUnmanaged.WriteError!void {
        const markerlen = 2 + nQuantIndex * (1 + blockSize);
        self.writeMarkerHeader(@as(u8, @intCast(@intFromEnum(utils.Markers.define_quantization_tables) & 0xFF)), markerlen); // DQT marker

        for (0..nQuantIndex) |i| {
            // Write table index (8-bit precision, destination i)
            self.buf[0] = @as(u8, @intCast(i)); // table index
            _ = self.writer.write(self.buf[0..1]) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
            // Write quantization table data
            _ = self.writer.write(&self.quant[i]) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        }
    }

    /// Write Define Huffman Tables marker
    pub fn writeDHT(self: *JPEGWriter, nComponent: u8) ImageUnmanaged.WriteError!void {

        // Calculate marker length
        var markerlen: usize = 2;
        const specs_len: usize = if (nComponent == 1) 2 else nHuffIndex;
        for (0..specs_len) |i| {
            const s = theHuffmanSpec[i];
            markerlen += 1 + 16 + s.value.len;
        }

        // Write DHT marker header
        self.writeMarkerHeader(@as(u8, @intCast(@intFromEnum(utils.Markers.define_huffman_tables) & 0xFF)), markerlen); // DHT marker

        // Write Huffman table data
        const table_classes = [_]u8{ 0x00, 0x10, 0x01, 0x11 }; // DC luminance, AC luminance, DC chrominance, AC chrominance
        for (0..specs_len) |i| {
            const s = theHuffmanSpec[i];
            // Write table class and destination
            self.buf[0] = table_classes[i];
            _ = self.writer.write(self.buf[0..1]) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };

            // Write bit counts (16 bytes)
            _ = self.writer.write(&s.count) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };

            // Write Huffman values
            _ = self.writer.write(s.value) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        }
    }

    /// Write Start of Scan marker
    pub fn writeSOS(self: *JPEGWriter, image: ImageUnmanaged) ImageUnmanaged.WriteError!void {
        const nComponent = self.getComponentCount(image);

        // Write SOS header based on component count
        if (nComponent == 1) {
            // Grayscale SOS header
            const sosHeaderY = [_]u8{ 0xff, 0xda, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f, 0x00 };
            _ = self.writer.write(&sosHeaderY) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        } else {
            // Color SOS header
            const sosHeaderYCbCr = [_]u8{
                0xff, 0xda, 0x00, 0x0c, 0x03, // SOS marker + length + component count
                0x01, 0x00, // Y: DC table 0, AC table 1
                0x02, 0x11, // Cb: DC table 2, AC table 3
                0x03, 0x11, // Cr: DC table 2, AC table 3
                0x00, 0x3f, 0x00, // Start/end spectral selection, successive approximation
            };
            _ = self.writer.write(&sosHeaderYCbCr) catch {
                self.err = ImageUnmanaged.WriteError.InvalidData;
                return ImageUnmanaged.WriteError.InvalidData;
            };
        }

        // Write actual encoded image data
        try self.writeImageData(image, nComponent);
    }

    /// Write a generic marker header with length
    pub fn writeMarkerHeader(self: *JPEGWriter, marker: u8, markerlen: usize) void {
        self.buf[0] = 0xff;
        self.buf[1] = marker;
        self.buf[2] = @as(u8, @intCast(markerlen >> 8));
        self.buf[3] = @as(u8, @intCast(markerlen & 0xff));
        _ = self.writer.write(self.buf[0..4]) catch {
            self.err = ImageUnmanaged.WriteError.InvalidData;
        };
    }

    /// Emit bits to the output stream
    pub fn emit(self: *JPEGWriter, bits: u32, n_bits: u32) ImageUnmanaged.WriteError!void {

        // Preconditions: bits < 1<<n_bits && n_bits <= 16
        std.debug.assert(bits < (@as(u32, 1) << @as(u5, @intCast(@min(n_bits, 31)))));
        std.debug.assert(n_bits <= 16);

        var n_bits_mut = n_bits + self.n_bits;
        const shift_amount = @as(u5, @intCast(@min(32 - n_bits_mut, 31)));
        var bits_mut = bits << shift_amount | self.bits;

        while (n_bits_mut >= 8) {
            const b = @as(u8, @intCast(bits_mut >> 24));
            self.writeByte(b);
            if (b == 0xff) {
                self.writeByte(0x00); // Byte stuffing
            }
            bits_mut <<= @as(u5, 8);
            n_bits_mut -= 8;
        }

        self.bits = bits_mut;
        self.n_bits = n_bits_mut;
    }

    /// Write a single byte, handling errors
    fn writeByte(self: *JPEGWriter, b: u8) void {
        if (self.err != null) return;
        _ = self.writer.write(std.mem.asBytes(&b)) catch {
            self.err = ImageUnmanaged.WriteError.InvalidData;
            return;
        };
    }

    /// Emit Huffman-encoded value
    pub fn emitHuff(self: *JPEGWriter, huff_index: usize, value: i32) ImageUnmanaged.WriteError!void {
        if (self.err != null) return;

        // Get Huffman code from LUT (don't clamp - Huffman tables handle the full range)
        const x = self.huffman_lut[huff_index][@as(usize, @intCast(value))];

        // Extract size (high 8 bits) and code (low 24 bits)
        const n_bits = x >> 24;
        const code = x & 0x00FFFFFF;

        // Emit the Huffman code
        try self.emit(code, n_bits);
    }

    /// Process and write an 8x8 DCT block
    pub fn writeBlock(self: *JPEGWriter, block: *[64]i32, quant_index: usize, prev_dc: i32) ImageUnmanaged.WriteError!i32 {
        if (self.err != null) return 0;

        // Debug: Print first block's input values
        if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and prev_dc == 0 and quant_index == 0) {
            std.debug.print("Input block (first 8 values): ", .{});
            for (0..8) |i| {
                std.debug.print("{} ", .{block[i]});
            }
            std.debug.print("\n", .{});
        }

        // Apply forward DCT
        fdct(block);

        // Debug: Print first block's DCT values
        if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and prev_dc == 0 and quant_index == 0) {
            std.debug.print("DCT block (first 8 values): ", .{});
            for (0..8) |i| {
                std.debug.print("{} ", .{block[i]});
            }
            std.debug.print("\n", .{});
            std.debug.print("Quantization table (first 8 values): ", .{});
            for (0..8) |i| {
                std.debug.print("{} ", .{self.quant[quant_index][i]});
            }
            std.debug.print("\n", .{});
        }

        // Quantize the DCT coefficients and handle DC prediction
        const dc = div(block[0], 8 * @as(i32, self.quant[quant_index][0]));

        // Debug: Print quantized DC value
        if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and prev_dc == 0 and quant_index == 0) {
            std.debug.print("DC: raw={}, quant_factor={}, quantized={}\n", .{ block[0], 8 * @as(i32, self.quant[quant_index][0]), dc });
        }

        try self.emitHuffRLE(@as(usize, 2 * quant_index + 0), 0, dc - prev_dc);

        // Handle AC coefficients
        const huff_index = @as(usize, 2 * quant_index + 1);
        var run_length: i32 = 0;

        // Process AC coefficients (skip DC coefficient at index 0)
        var non_zero_ac_count: u32 = 0;
        for (1..blockSize) |zig| {
            const ac = div(block[unzig[zig]], 8 * @as(i32, self.quant[quant_index][zig]));
            if (ac == 0) {
                run_length += 1;
            } else {
                non_zero_ac_count += 1;
                // Handle runs longer than 15 (ZRL - Zero Run Length)
                while (run_length > 15) {
                    try self.emitHuff(huff_index, 0xf0); // ZRL symbol
                    run_length -= 16;
                }

                // Emit the run-length encoded AC coefficient
                try self.emitHuffRLE(huff_index, run_length, ac);
                run_length = 0;
            }
        }

        // Debug: Print AC coefficient count for first block
        if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and prev_dc == 0 and quant_index == 0) {
            std.debug.print("Non-zero AC coefficients: {}\n", .{non_zero_ac_count});
        }

        // End of block - emit EOB if there are trailing zeros
        if (run_length > 0) {
            try self.emitHuff(huff_index, 0x00); // EOB symbol
        }

        return dc;
    }

    /// Convert RGB image data to YCbCr color space for a single 8x8 block
    pub fn rgbToYCbCr(self: *JPEGWriter, image: ImageUnmanaged, px: i32, py: i32, y_block: *[64]i32, cb_block: *[64]i32, cr_block: *[64]i32) ImageUnmanaged.WriteError!void {
        _ = self;

        for (0..8) |j| {
            for (0..8) |i| {
                var sx = px + @as(i32, @intCast(i));
                var sy = py + @as(i32, @intCast(j));

                // Clamp coordinates to image bounds (same as Go implementation)
                if (sx < 0) {
                    sx = 0;
                }
                if (sx > @as(i32, @intCast(image.width - 1))) {
                    sx = @as(i32, @intCast(image.width - 1));
                }
                if (sy < 0) {
                    sy = 0;
                }
                if (sy > @as(i32, @intCast(image.height - 1))) {
                    sy = @as(i32, @intCast(image.height - 1));
                }

                const x = @as(usize, @intCast(sx));
                const y = @as(usize, @intCast(sy));

                // Get pixel from RGB24 data
                const pixel_index = y * image.width + x;
                const pixel = image.pixels.rgb24[pixel_index];

                // Debug: Print first few pixels to see what we're getting
                if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and px == 0 and py == 0 and i < 3 and j < 3) {
                    std.debug.print("Pixel[{},{}]: R={}, G={}, B={}\n", .{ i, j, pixel.r, pixel.g, pixel.b });
                }

                // Convert RGB to YCbCr matching Go's color.RGBToYCbCr (Cb/Cr offset by 128)
                const r_i = @as(i32, pixel.r);
                const g_i = @as(i32, pixel.g);
                const b_i = @as(i32, pixel.b);
                const yy = (19595 * r_i + 38470 * g_i + 7471 * b_i + 32768) >> 16;
                const cb = (-11059 * r_i - 21709 * g_i + 32768 * b_i + ((128 << 16) + 32768)) >> 16;
                const cr = (32768 * r_i - 27439 * g_i - 5329 * b_i + ((128 << 16) + 32768)) >> 16;

                const block_index = j * 8 + i;
                // Clamp to 0..255 range
                const y8: i32 = @intCast(@as(i16, @intCast(@max(0, @min(255, yy)))));
                const cb8: i32 = @intCast(@as(i16, @intCast(@max(0, @min(255, cb)))));
                const cr8: i32 = @intCast(@as(i16, @intCast(@max(0, @min(255, cr)))));

                y_block[block_index] = y8;
                cb_block[block_index] = cb8;
                cr_block[block_index] = cr8;

                // Debug: Print first few YCbCr values
                if (comptime @hasDecl(@This(), "DEBUG") and @This().DEBUG and px == 0 and py == 0 and i < 3 and j < 3) {
                    std.debug.print("YCbCr[{},{}]: Y={}, Cb={}, Cr={}\n", .{ i, j, yy, cb, cr });
                }
            }
        }
    }

    /// Convert grayscale image data to Y block
    pub fn grayToY(self: *JPEGWriter, image: ImageUnmanaged, px: i32, py: i32, y_block: *[64]i32) ImageUnmanaged.WriteError!void {
        _ = self;

        for (0..8) |j| {
            for (0..8) |i| {
                var sx = px + @as(i32, @intCast(i));
                var sy = py + @as(i32, @intCast(j));

                // Clamp coordinates to image bounds (same as Go implementation)
                if (sx < 0) {
                    sx = 0;
                }
                if (sx > @as(i32, @intCast(image.width - 1))) {
                    sx = @as(i32, @intCast(image.width - 1));
                }
                if (sy < 0) {
                    sy = 0;
                }
                if (sy > @as(i32, @intCast(image.height - 1))) {
                    sy = @as(i32, @intCast(image.height - 1));
                }

                const x = @as(usize, @intCast(sx));
                const y = @as(usize, @intCast(sy));

                // Get pixel from grayscale data
                const pixel_index = y * image.width + x;
                const gray = image.pixels.grayscale8[pixel_index];

                const block_index = j * 8 + i;
                y_block[block_index] = @as(i32, gray.value);
            }
        }
    }

    /// Scale 4 chroma blocks (16x16) down to 1 chroma block (8x8) for 4:2:0 subsampling
    pub fn scale(dst: *[64]i32, src: *[4][64]i32) void {
        // Initialize destination block to zero
        for (0..64) |i| {
            dst[i] = 0;
        }

        // Use the same logic as Go implementation: dstOff := (i&2)<<4 | (i&1)<<2
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

    /// Perform forward discrete cosine transform (exact port of Go's fdct).
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
    pub fn flush(self: *JPEGWriter) ImageUnmanaged.WriteError!void {
        if (self.err != null) return;

        // Flush any remaining bits
        if (self.n_bits > 0) {
            try self.emit(0x7f, 7); // Pad with 1's
        }

        // Flush the writer if it supports flushing
        if (@hasDecl(std.io.AnyWriter, "flush")) {
            try self.writer.flush();
        }
    }

    /// Write the actual image data (scan/entropy coded data)
    pub fn writeImageData(self: *JPEGWriter, image: ImageUnmanaged, nComponent: u8) ImageUnmanaged.WriteError!void {
        if (self.err != null) return;

        // Scratch blocks for YCbCr conversion
        var y_block: [64]i32 = undefined;
        var cb_blocks: [4][64]i32 = undefined;
        var cr_blocks: [4][64]i32 = undefined;

        // Initialize all blocks to zero
        for (0..64) |i| {
            y_block[i] = 0;
            for (0..4) |j| {
                cb_blocks[j][i] = 0;
                cr_blocks[j][i] = 0;
            }
        }

        // DC component predictors (for delta encoding)
        var prev_dc_y: i32 = 0;
        var prev_dc_cb: i32 = 0;
        var prev_dc_cr: i32 = 0;

        if (nComponent == 1) {
            // Grayscale image - process 8x8 blocks
            var y: i32 = 0;
            while (y < @as(i32, @intCast(image.height))) : (y += 8) {
                var x: i32 = 0;
                while (x < @as(i32, @intCast(image.width))) : (x += 8) {
                    try self.grayToY(image, x, y, &y_block);
                    prev_dc_y = try self.writeBlock(&y_block, quantIndexLuminance, prev_dc_y);
                }
            }
        } else {
            // Color image - process 16x16 macroblocks with 4:2:0 chroma subsampling
            var y: i32 = 0;
            while (y < @as(i32, @intCast(image.height))) : (y += 16) {
                var x: i32 = 0;
                while (x < @as(i32, @intCast(image.width))) : (x += 16) {
                    // Initialize chroma blocks for this macroblock to prevent stale data
                    for (0..4) |i| {
                        for (0..64) |j| {
                            cb_blocks[i][j] = 0;
                            cr_blocks[i][j] = 0;
                        }
                    }

                    // Process 4 luminance blocks (8x8 each) per macroblock
                    var y_blocks: [4][64]i32 = undefined;
                    for (0..4) |i| {
                        const x_off = @as(i32, @intCast(i & 1)) * 8;
                        const y_off = @as(i32, @intCast(i & 2)) * 4; // Go uses * 4, not * 8
                        try self.rgbToYCbCr(image, x + x_off, y + y_off, &y_blocks[i], &cb_blocks[i], &cr_blocks[i]);
                        prev_dc_y = try self.writeBlock(&y_blocks[i], quantIndexLuminance, prev_dc_y);
                    }

                    // Scale and process chrominance blocks (4:2:0 subsampling)
                    scale(&y_blocks[0], &cb_blocks);
                    prev_dc_cb = try self.writeBlock(&y_blocks[0], quantIndexChrominance, prev_dc_cb);

                    scale(&y_blocks[0], &cr_blocks);
                    prev_dc_cr = try self.writeBlock(&y_blocks[0], quantIndexChrominance, prev_dc_cr);
                }
            }
        }

        // Pad the last byte with 1's (JPEG requirement)
        try self.emit(0x7f, 7);
    }

    /// Emit Huffman-encoded value with run-length encoding
    pub fn emitHuffRLE(self: *JPEGWriter, huff_index: usize, run_length: i32, value: i32) ImageUnmanaged.WriteError!void {
        if (self.err != null) return;

        // Handle value encoding (same as Go implementation)
        var a = value;
        var b = value;
        if (a < 0) {
            a = -value;
            b = value - 1;
        }

        // Calculate number of bits needed to represent the value
        var n_bits: u32 = 0;
        if (a < 0x100) {
            // Use lookup table for small values (same as Go's bitCount)
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
            n_bits = @as(u32, bit_count_lut[@as(usize, @intCast(a))]);
        } else {
            n_bits = 8 + @as(u32, std.math.log2_int(u32, @as(u32, @intCast(a >> 8))));
        }

        // Pack run length and size into Huffman symbol
        // runLength is 0-15, nBits is 1-10, so we pack as (runLength << 4) | nBits
        const huff_symbol = (run_length << 4) | @as(i32, @intCast(n_bits));

        // Emit Huffman code for the packed symbol
        try self.emitHuff(huff_index, huff_symbol);

        // Emit the actual value bits (if any)
        if (n_bits > 0) {
            // Cast to u32 and mask the bits (same as Go implementation)
            const b_unsigned = @as(u32, @bitCast(b));
            try self.emit(b_unsigned & ((@as(u32, 1) << @as(u5, @intCast(n_bits))) - 1), n_bits);
        }
    }

    /// Validate that an image can be encoded as JPEG
    pub fn validateImage(image: ImageUnmanaged) ImageUnmanaged.WriteError!void {
        // Check supported pixel formats
        switch (image.pixels) {
            .grayscale8, .rgb24 => {
                // These formats are supported
            },
            else => {
                return ImageUnmanaged.WriteError.InvalidData;
            },
        }

        // Check image dimensions
        if (image.width == 0 or image.height == 0) {
            return ImageUnmanaged.WriteError.InvalidData;
        }

        // Check maximum dimensions (JPEG spec limit)
        if (image.width >= 1 << 16 or image.height >= 1 << 16) {
            return ImageUnmanaged.WriteError.InvalidData;
        }
    }
};
