const std = @import("std");
const Allocator = std.mem.Allocator;

const buffered_stream_source = @import("../../buffered_stream_source.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const Markers = @import("utils.zig").Markers;
const FrameHeader = @import("FrameHeader.zig");
const QuantizationTable = @import("quantization.zig").Table;
const HuffmanTable = @import("huffman.zig").Table;
const color = @import("../../color.zig");

const IDCTMultipliers = @import("utils.zig").IDCTMultipliers;
const MAX_COMPONENTS = @import("utils.zig").MAX_COMPONENTS;
const MAX_BLOCKS = @import("utils.zig").MAX_BLOCKS;
const Block = @import("utils.zig").Block;

const Self = @This();
allocator: Allocator,
frame_header: FrameHeader,
quantization_tables: *[4]?QuantizationTable,
dc_huffman_tables: *[4]?HuffmanTable,
ac_huffman_tables: *[4]?HuffmanTable,
block_storage: [][MAX_COMPONENTS]Block,
frame_type: Markers = undefined,

block_height: u32 = 0,
block_width: u32 = 0,
block_width_actual: u32 = 0,
block_height_actual: u32 = 0,

horizontal_sampling_factor_max: usize = 0,
vertical_sampling_factor_max: usize = 0,

const JPEG_DEBUG = false;

pub fn read(allocator: Allocator, frame_type: Markers, quantization_tables: *[4]?QuantizationTable, dc_huffman_tables: *[4]?HuffmanTable, ac_huffman_tables: *[4]?HuffmanTable, buffered_stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) ImageReadError!Self {
    const reader = buffered_stream.reader();
    const frame_header = try FrameHeader.read(allocator, reader);

    const horizontal_sampling_factor_max = frame_header.getMaxHorizontalSamplingFactor();
    const vertical_sampling_factor_max = frame_header.getMaxVerticalSamplingFactor();

    const mcu_width = 8 * horizontal_sampling_factor_max;
    const mcu_height = 8 * vertical_sampling_factor_max;
    const width_actual = ((frame_header.width + mcu_width - 1) / mcu_width) * mcu_width;

    const height_actual = ((frame_header.height + mcu_height - 1) / mcu_height) * mcu_height;
    const block_storage = try allocator.alloc([MAX_COMPONENTS]Block, width_actual * height_actual / 64);

    var self = Self{
        .allocator = allocator,
        .frame_header = frame_header,
        .quantization_tables = quantization_tables,
        .dc_huffman_tables = dc_huffman_tables,
        .ac_huffman_tables = ac_huffman_tables,
        .frame_type = frame_type,
        .block_storage = block_storage,
        .block_height_actual = @intCast((height_actual + 7) / 8),
        .block_width_actual = @intCast((width_actual + 7) / 8),
        .block_height = (frame_header.height + 7) / 8,
        .block_width = (frame_header.width + 7) / 8,
        .horizontal_sampling_factor_max = horizontal_sampling_factor_max,
        .vertical_sampling_factor_max = vertical_sampling_factor_max,
    };
    errdefer self.deinit();

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.block_storage);
    for (self.dc_huffman_tables) |*maybe_huffman_table| {
        if (maybe_huffman_table.*) |*huffman_table| {
            huffman_table.deinit();
        }
    }

    for (self.ac_huffman_tables) |*maybe_huffman_table| {
        if (maybe_huffman_table.*) |*huffman_table| {
            huffman_table.deinit();
        }
    }

    self.frame_header.deinit();
}

pub fn renderToPixels(self: *Self, pixels: *color.PixelStorage) ImageReadError!void {
    switch (self.frame_header.components.len) {
        1 => try self.renderToPixelsGrayscale(pixels.grayscale8), // Grayscale images is non-interleaved
        3 => {
            try self.yCbCrToRgb();
            try self.renderToPixelsRgb(pixels.rgb24);
        },
        else => unreachable,
    }
}

fn renderToPixelsGrayscale(self: *Self, pixels: []color.Grayscale8) ImageReadError!void {
    var block_y: usize = 0;
    while (block_y < self.block_height) : (block_y += 1) {
        const pixel_y = block_y * 8;

        var block_x: usize = 0;
        while (block_x < self.block_width) : (block_x += 1) {
            const block_index = block_y * self.block_width_actual + block_x;

            const pixel_x = block_x * 8;

            for (0..8) |y| {
                for (0..8) |x| {
                    if (pixel_y + y >= self.frame_header.height or pixel_x + x >= self.frame_header.width) {
                        continue;
                    }
                    const pixel_index = (pixel_y + y) * self.frame_header.width + (pixel_x + x);
                    const Y = self.block_storage[block_index][0][y * 8 + x];

                    pixels[pixel_index] = .{
                        .value = @intCast(std.math.clamp(Y + 128, 0, 255)),
                    };
                }
            }
        }
    }
}

pub fn renderToPixelsRgb(self: *Self, pixels: []color.Rgb24) ImageReadError!void {
    var block_y: usize = 0;
    while (block_y < self.block_height) : (block_y += 1) {
        const pixel_y = block_y * 8;

        var block_x: usize = 0;
        while (block_x < self.block_width) : (block_x += 1) {
            const block_index = block_y * self.block_width_actual + block_x;

            const pixel_x = block_x * 8;

            for (0..8) |y| {
                for (0..8) |x| {
                    if (pixel_y + y >= self.frame_header.height or pixel_x + x >= self.frame_header.width) {
                        continue;
                    }

                    const pixel_index = (pixel_y + y) * self.frame_header.width + (pixel_x + x);

                    pixels[pixel_index] = .{
                        .r = @intCast(self.block_storage[block_index][0][y * 8 + x]),
                        .g = @intCast(self.block_storage[block_index][1][y * 8 + x]),
                        .b = @intCast(self.block_storage[block_index][2][y * 8 + x]),
                    };
                }
            }
        }
    }
}

pub fn yCbCrToRgbBlock(self: *Self, y_block: *[3]Block, cbcr_block: *[3]Block, v: usize, h: usize) void {
    const y_step = self.vertical_sampling_factor_max;
    const x_step = self.horizontal_sampling_factor_max;

    var y: usize = 8;
    while (y > 0) {
        y -= 1;
        const cbcr_y: usize = y / y_step + (8 / y_step) * v;

        const pixel_index: usize = y * 8;
        const Y0: f32 = @floatFromInt(y_block[0][pixel_index + 0]);
        const Y1: f32 = @floatFromInt(y_block[0][pixel_index + 1]);
        const Y2: f32 = @floatFromInt(y_block[0][pixel_index + 2]);
        const Y3: f32 = @floatFromInt(y_block[0][pixel_index + 3]);
        const Y4: f32 = @floatFromInt(y_block[0][pixel_index + 4]);
        const Y5: f32 = @floatFromInt(y_block[0][pixel_index + 5]);
        const Y6: f32 = @floatFromInt(y_block[0][pixel_index + 6]);
        const Y7: f32 = @floatFromInt(y_block[0][pixel_index + 7]);

        const cbcr_x0: usize = (0 / x_step) + (8 / x_step) * h;
        const cbcr_x1: usize = (1 / x_step) + (8 / x_step) * h;
        const cbcr_x2: usize = (2 / x_step) + (8 / x_step) * h;
        const cbcr_x3: usize = (3 / x_step) + (8 / x_step) * h;
        const cbcr_x4: usize = (4 / x_step) + (8 / x_step) * h;
        const cbcr_x5: usize = (5 / x_step) + (8 / x_step) * h;
        const cbcr_x6: usize = (6 / x_step) + (8 / x_step) * h;
        const cbcr_x7: usize = (7 / x_step) + (8 / x_step) * h;

        const cbcr_pixel0: usize = cbcr_y * 8 + cbcr_x0;
        const cbcr_pixel1: usize = cbcr_y * 8 + cbcr_x1;
        const cbcr_pixel2: usize = cbcr_y * 8 + cbcr_x2;
        const cbcr_pixel3: usize = cbcr_y * 8 + cbcr_x3;
        const cbcr_pixel4: usize = cbcr_y * 8 + cbcr_x4;
        const cbcr_pixel5: usize = cbcr_y * 8 + cbcr_x5;
        const cbcr_pixel6: usize = cbcr_y * 8 + cbcr_x6;
        const cbcr_pixel7: usize = cbcr_y * 8 + cbcr_x7;

        const Cb0: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel0]);
        const Cb1: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel1]);
        const Cb2: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel2]);
        const Cb3: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel3]);
        const Cb4: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel4]);
        const Cb5: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel5]);
        const Cb6: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel6]);
        const Cb7: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel7]);

        const Cr0: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel0]);
        const Cr1: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel1]);
        const Cr2: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel2]);
        const Cr3: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel3]);
        const Cr4: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel4]);
        const Cr5: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel5]);
        const Cr6: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel6]);
        const Cr7: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel7]);

        const r0 = Cr0 * (2 - 2 * 0.299) + Y0;
        const r1 = Cr1 * (2 - 2 * 0.299) + Y1;
        const r2 = Cr2 * (2 - 2 * 0.299) + Y2;
        const r3 = Cr3 * (2 - 2 * 0.299) + Y3;
        const r4 = Cr4 * (2 - 2 * 0.299) + Y4;
        const r5 = Cr5 * (2 - 2 * 0.299) + Y5;
        const r6 = Cr6 * (2 - 2 * 0.299) + Y6;
        const r7 = Cr7 * (2 - 2 * 0.299) + Y7;

        const b0 = Cb0 * (2 - 2 * 0.114) + Y0;
        const b1 = Cb1 * (2 - 2 * 0.114) + Y1;
        const b2 = Cb2 * (2 - 2 * 0.114) + Y2;
        const b3 = Cb3 * (2 - 2 * 0.114) + Y3;
        const b4 = Cb4 * (2 - 2 * 0.114) + Y4;
        const b5 = Cb5 * (2 - 2 * 0.114) + Y5;
        const b6 = Cb6 * (2 - 2 * 0.114) + Y6;
        const b7 = Cb7 * (2 - 2 * 0.114) + Y7;

        const g0 = (Y0 - 0.114 * b0 - 0.299 * r0) / 0.587;
        const g1 = (Y1 - 0.114 * b1 - 0.299 * r1) / 0.587;
        const g2 = (Y2 - 0.114 * b2 - 0.299 * r2) / 0.587;
        const g3 = (Y3 - 0.114 * b3 - 0.299 * r3) / 0.587;
        const g4 = (Y4 - 0.114 * b4 - 0.299 * r4) / 0.587;
        const g5 = (Y5 - 0.114 * b5 - 0.299 * r5) / 0.587;
        const g6 = (Y6 - 0.114 * b6 - 0.299 * r6) / 0.587;
        const g7 = (Y7 - 0.114 * b7 - 0.299 * r7) / 0.587;

        y_block[0][pixel_index + 0] = @intFromFloat(std.math.clamp(r0 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 0] = @intFromFloat(std.math.clamp(g0 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 0] = @intFromFloat(std.math.clamp(b0 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 1] = @intFromFloat(std.math.clamp(r1 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 1] = @intFromFloat(std.math.clamp(g1 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 1] = @intFromFloat(std.math.clamp(b1 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 2] = @intFromFloat(std.math.clamp(r2 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 2] = @intFromFloat(std.math.clamp(g2 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 2] = @intFromFloat(std.math.clamp(b2 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 3] = @intFromFloat(std.math.clamp(r3 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 3] = @intFromFloat(std.math.clamp(g3 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 3] = @intFromFloat(std.math.clamp(b3 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 4] = @intFromFloat(std.math.clamp(r4 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 4] = @intFromFloat(std.math.clamp(g4 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 4] = @intFromFloat(std.math.clamp(b4 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 5] = @intFromFloat(std.math.clamp(r5 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 5] = @intFromFloat(std.math.clamp(g5 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 5] = @intFromFloat(std.math.clamp(b5 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 6] = @intFromFloat(std.math.clamp(r6 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 6] = @intFromFloat(std.math.clamp(g6 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 6] = @intFromFloat(std.math.clamp(b6 + 128.0, 0.0, 255.0));

        y_block[0][pixel_index + 7] = @intFromFloat(std.math.clamp(r7 + 128.0, 0.0, 255.0));
        y_block[1][pixel_index + 7] = @intFromFloat(std.math.clamp(g7 + 128.0, 0.0, 255.0));
        y_block[2][pixel_index + 7] = @intFromFloat(std.math.clamp(b7 + 128.0, 0.0, 255.0));
    }
}

pub fn yCbCrToRgb(self: *Self) ImageReadError!void {
    const y_step = self.vertical_sampling_factor_max;
    const x_step = self.horizontal_sampling_factor_max;

    var y: usize = 0;
    while (y < self.block_height) : (y += y_step) {
        var x: usize = 0;
        while (x < self.block_width) : (x += x_step) {
            const v_max = self.vertical_sampling_factor_max;
            const h_max = self.horizontal_sampling_factor_max;

            const cbcr_block = &self.block_storage[y * self.block_width_actual + x];

            var v: usize = v_max;
            while (v > 0) {
                v -= 1;
                var h: usize = h_max;
                while (h > 0) {
                    h -= 1;
                    if (y + v >= self.block_height or x + h >= self.block_width) continue;

                    const y_block = &self.block_storage[(y + v) * self.block_width_actual + (x + h)];
                    yCbCrToRgbBlock(self, y_block, cbcr_block, v, h);
                }
            }
        }
    }
}

pub fn dequantizeBlocks(self: *Self) ImageReadError!void {
    for (self.frame_header.components) |component| {
        if (self.quantization_tables[component.quantization_table_id] == null) {
            return ImageReadError.InvalidData;
        }
    }

    const y_step = self.vertical_sampling_factor_max;
    const x_step = self.horizontal_sampling_factor_max;

    var y: usize = 0;
    while (y < self.block_height) : (y += y_step) {
        var x: usize = 0;
        while (x < self.block_width) : (x += x_step) {
            for (self.frame_header.components, 0..) |component, component_id| {
                const quantization_table = self.quantization_tables[component.quantization_table_id].?;
                const v_max = component.vertical_sampling_factor;
                const h_max = component.horizontal_sampling_factor;

                for (0..v_max) |v| {
                    for (0..h_max) |h| {
                        const block_id = (y + v) * self.block_width_actual + (x + h);
                        const block = &self.block_storage[block_id][component_id];
                        if (y + v >= self.block_height) {
                            @memset(block, 0);
                        } else {
                            for (0..64) |sample_id| {
                                block[sample_id] = block[sample_id] * quantization_table.q8[sample_id];
                            }
                        }
                    }
                }
            }
        }
    }
}

pub fn idctBlocks(self: *Self) void {
    const y_step = self.vertical_sampling_factor_max;
    const x_step = self.horizontal_sampling_factor_max;

    var y: usize = 0;
    while (y < self.block_height) : (y += y_step) {
        var x: usize = 0;
        while (x < self.block_width) : (x += x_step) {
            for (self.frame_header.components, 0..) |component, component_id| {
                const v_max = component.vertical_sampling_factor;
                const h_max = component.horizontal_sampling_factor;

                for (0..v_max) |v| {
                    for (0..h_max) |h| {
                        const block_id = (y + v) * self.block_width_actual + (x + h);
                        const block = &self.block_storage[block_id][component_id];
                        idctBlock(block);
                    }
                }
            }
        }
    }
}

fn idctBlock(block: *Block) void {
    var result: [64]f32 = undefined;

    const m0: f32 = 2.0 * @cos(1.0 / 16.0 * 2.0 * std.math.pi);
    const m1: f32 = 2.0 * @cos(2.0 / 16.0 * 2.0 * std.math.pi);
    const m3: f32 = 2.0 * @cos(2.0 / 16.0 * 2.0 * std.math.pi);
    const m5: f32 = 2.0 * @cos(3.0 / 16.0 * 2.0 * std.math.pi);
    const m2: f32 = m0 - m5;
    const m4: f32 = m0 + m5;

    const s0: f32 = @cos(0.0 / 16.0 * std.math.pi) / @sqrt(8.0);
    const s1: f32 = @cos(1.0 / 16.0 * std.math.pi) / 2.0;
    const s2: f32 = @cos(2.0 / 16.0 * std.math.pi) / 2.0;
    const s3: f32 = @cos(3.0 / 16.0 * std.math.pi) / 2.0;
    const s4: f32 = @cos(4.0 / 16.0 * std.math.pi) / 2.0;
    const s5: f32 = @cos(5.0 / 16.0 * std.math.pi) / 2.0;
    const s6: f32 = @cos(6.0 / 16.0 * std.math.pi) / 2.0;
    const s7: f32 = @cos(7.0 / 16.0 * std.math.pi) / 2.0;

    for (0..8) |x| {
        const a0 = @as(f32, @floatFromInt(block[0 * 8 + x])) * s0;
        const a1 = @as(f32, @floatFromInt(block[4 * 8 + x])) * s4;
        const a2 = @as(f32, @floatFromInt(block[2 * 8 + x])) * s2;
        const a3 = @as(f32, @floatFromInt(block[6 * 8 + x])) * s6;
        const a4 = @as(f32, @floatFromInt(block[5 * 8 + x])) * s5;
        const a5 = @as(f32, @floatFromInt(block[1 * 8 + x])) * s1;
        const a6 = @as(f32, @floatFromInt(block[7 * 8 + x])) * s7;
        const a7 = @as(f32, @floatFromInt(block[3 * 8 + x])) * s3;

        const b0 = a0;
        const b1 = a1;
        const b2 = a2;
        const b3 = a3;
        const b4 = a4 - a7;
        const b5 = a5 + a6;
        const b6 = a5 - a6;
        const b7 = a4 + a7;

        const c0 = b0;
        const c1 = b1;
        const c2 = b2 - b3;
        const c3 = b2 + b3;
        const c4 = b4;
        const c5 = b5 - b7;
        const c6 = b6;
        const c7 = b5 + b7;
        const c8 = b4 + b6;

        const d0 = c0;
        const d1 = c1;
        const d2 = c2 * m1;
        const d3 = c3;
        const d4 = c4 * m2;
        const d5 = c5 * m3;
        const d6 = c6 * m4;
        const d7 = c7;
        const d8 = c8 * m5;

        const e0 = d0 + d1;
        const e1 = d0 - d1;
        const e2 = d2 - d3;
        const e3 = d3;
        const e4 = d4 + d8;
        const e5 = d5 + d7;
        const e6 = d6 - d8;
        const e7 = d7;
        const e8 = e5 - e6;

        const f0 = e0 + e3;
        const f1 = e1 + e2;
        const f2 = e1 - e2;
        const f3 = e0 - e3;
        const f4 = e4 - e8;
        const f5 = e8;
        const f6 = e6 - e7;
        const f7 = e7;

        result[0 * 8 + x] = f0 + f7;
        result[1 * 8 + x] = f1 + f6;
        result[2 * 8 + x] = f2 + f5;
        result[3 * 8 + x] = f3 + f4;
        result[4 * 8 + x] = f3 - f4;
        result[5 * 8 + x] = f2 - f5;
        result[6 * 8 + x] = f1 - f6;
        result[7 * 8 + x] = f0 - f7;
    }

    for (0..8) |y| {
        const a0 = result[y * 8 + 0] * s0;
        const a1 = result[y * 8 + 4] * s4;
        const a2 = result[y * 8 + 2] * s2;
        const a3 = result[y * 8 + 6] * s6;
        const a4 = result[y * 8 + 5] * s5;
        const a5 = result[y * 8 + 1] * s1;
        const a6 = result[y * 8 + 7] * s7;
        const a7 = result[y * 8 + 3] * s3;

        const b0 = a0;
        const b1 = a1;
        const b2 = a2;
        const b3 = a3;
        const b4 = a4 - a7;
        const b5 = a5 + a6;
        const b6 = a5 - a6;
        const b7 = a4 + a7;

        const c0 = b0;
        const c1 = b1;
        const c2 = b2 - b3;
        const c3 = b2 + b3;
        const c4 = b4;
        const c5 = b5 - b7;
        const c6 = b6;
        const c7 = b5 + b7;
        const c8 = b4 + b6;

        const d0 = c0;
        const d1 = c1;
        const d2 = c2 * m1;
        const d3 = c3;
        const d4 = c4 * m2;
        const d5 = c5 * m3;
        const d6 = c6 * m4;
        const d7 = c7;
        const d8 = c8 * m5;

        const e0 = d0 + d1;
        const e1 = d0 - d1;
        const e2 = d2 - d3;
        const e3 = d3;
        const e4 = d4 + d8;
        const e5 = d5 + d7;
        const e6 = d6 - d8;
        const e7 = d7;
        const e8 = e5 - e6;

        const f0 = e0 + e3;
        const f1 = e1 + e2;
        const f2 = e1 - e2;
        const f3 = e0 - e3;
        const f4 = e4 - e8;
        const f5 = e8;
        const f6 = e6 - e7;
        const f7 = e7;

        block[y * 8 + 0] = @intFromFloat(std.math.clamp(f0 + f7 + 0.5, -128.0, 127.0));
        block[y * 8 + 1] = @intFromFloat(std.math.clamp(f1 + f6 + 0.5, -128.0, 127.0));
        block[y * 8 + 2] = @intFromFloat(std.math.clamp(f2 + f5 + 0.5, -128.0, 127.0));
        block[y * 8 + 3] = @intFromFloat(std.math.clamp(f3 + f4 + 0.5, -128.0, 127.0));
        block[y * 8 + 4] = @intFromFloat(std.math.clamp(f3 - f4 + 0.5, -128.0, 127.0));
        block[y * 8 + 5] = @intFromFloat(std.math.clamp(f2 - f5 + 0.5, -128.0, 127.0));
        block[y * 8 + 6] = @intFromFloat(std.math.clamp(f1 - f6 + 0.5, -128.0, 127.0));
        block[y * 8 + 7] = @intFromFloat(std.math.clamp(f0 - f7 + 0.5, -128.0, 127.0));
    }
}
