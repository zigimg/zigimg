const std = @import("std");
const Allocator = std.mem.Allocator;

const simd = @import("../../simd.zig");

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
    const Co_1: @Vector(8, f32) = @splat(@as(f32, 1.402));
    const Co_2: @Vector(8, f32) = @splat(@as(f32, 1.772));
    const Co_3: @Vector(8, f32) = @splat(@as(f32, 0.344));
    const Co_4: @Vector(8, f32) = @splat(@as(f32, 0.714));
    const vec_0: @Vector(8, f32) = @splat(0.0);
    const vec_128: @Vector(8, f32) = @splat(128.0);
    const vec_255: @Vector(8, f32) = @splat(255.0);

    const y_step = self.vertical_sampling_factor_max;
    const x_step = self.horizontal_sampling_factor_max;

    const x_step_vec: @Vector(8, i32) = @splat(@as(i32, @intCast(x_step)));
    const x_offset: @Vector(8, i32) = @splat(@as(i32, @intCast((8 / x_step) * h)));
    const mask: @Vector(8, i32) = std.simd.iota(i32, 8) / x_step_vec + x_offset;

    var y: usize = 8;
    while (y > 0) {
        y -= 1;
        var y_vec_i32: @Vector(8, i32) = y_block[0][y * 8 ..][0..8].*;
        const y_vec: @Vector(8, f32) = @floatFromInt(y_vec_i32);

        const cbcr_y: usize = y / y_step + (8 / y_step) * v;

        var cb_vec_i32: @Vector(8, i32) = cbcr_block[1][cbcr_y * 8 ..][0..8].*;
        const cb_vec: @Vector(8, f32) = @floatFromInt(simd.vpermd(cb_vec_i32, mask));

        var cr_vec_i32: @Vector(8, i32) = cbcr_block[2][cbcr_y * 8 ..][0..8].*;
        const cr_vec: @Vector(8, f32) = @floatFromInt(simd.vpermd(cr_vec_i32, mask));

        var r_vec = y_vec + cr_vec * Co_1 + vec_128;
        var b_vec = y_vec + cb_vec * Co_2 + vec_128;
        var g_vec = y_vec - Co_3 * cb_vec - Co_4 * cr_vec + vec_128;

        r_vec = std.math.clamp(r_vec, vec_0, vec_255);
        g_vec = std.math.clamp(g_vec, vec_0, vec_255);
        b_vec = std.math.clamp(b_vec, vec_0, vec_255);

        y_vec_i32 = @intFromFloat(r_vec);
        cb_vec_i32 = @intFromFloat(g_vec);
        cr_vec_i32 = @intFromFloat(b_vec);

        simd.store(i32, y_block[0][y * 8 ..][0..8], y_vec_i32, 8);
        simd.store(i32, y_block[1][y * 8 ..][0..8], cb_vec_i32, 8);
        simd.store(i32, y_block[2][y * 8 ..][0..8], cr_vec_i32, 8);
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

// directly from stb_image.h
// https://github.com/nothings/stb/blob/5c205738c191bcb0abc65c4febfa9bd25ff35234/stb_image.h#L2430C9-L2430C22
fn f2f(comptime x: f32) i32 {
    // 4096 = 1 << 12
    return @intFromFloat(x * 4096 + 0.5);
}

fn idct1D(s0: i32, s1: i32, s2: i32, s3: i32, s4: i32, s5: i32, s6: i32, s7: i32) struct { i32, i32, i32, i32, i32, i32, i32, i32 } {
    var p2 = s2;
    var p3 = s6;

    var p1 = (p2 + p3) * f2f(0.5411961);
    var t2 = p1 + p3 * f2f(-1.847759065);
    var t3 = p1 + p2 * f2f(0.765366865);
    p2 = s0;
    p3 = s4;
    var t0 = (p2 + p3) * 4096;
    var t1 = (p2 - p3) * 4096;
    const x0 = t0 + t3;
    const x3 = t0 - t3;
    const x1 = t1 + t2;
    const x2 = t1 - t2;
    t0 = s7;
    t1 = s5;
    t2 = s3;
    t3 = s1;
    p3 = t0 + t2;
    var p4 = t1 + t3;
    p1 = t0 + t3;
    p2 = t1 + t2;
    const p5 = (p3 + p4) * f2f(1.175875602);
    t0 = t0 * f2f(0.298631336);
    t1 = t1 * f2f(2.053119869);
    t2 = t2 * f2f(3.072711026);
    t3 = t3 * f2f(1.501321110);
    p1 = p5 + p1 * f2f(-0.899976223);
    p2 = p5 + p2 * f2f(-2.562915447);
    p3 = p3 * f2f(-1.961570560);
    p4 = p4 * f2f(-0.390180644);
    t3 += p1 + p4;
    t2 += p2 + p3;
    t1 += p2 + p4;
    t0 += p1 + p3;

    return .{ x0, x1, x2, x3, t0, t1, t2, t3 };
}

fn idctBlock(block: *Block) void {
    for (0..8) |x| {
        const s0 = block[0 * 8 + x];
        const s1 = block[1 * 8 + x];
        const s2 = block[2 * 8 + x];
        const s3 = block[3 * 8 + x];
        const s4 = block[4 * 8 + x];
        const s5 = block[5 * 8 + x];
        const s6 = block[6 * 8 + x];
        const s7 = block[7 * 8 + x];

        var x0: i32 = 0;
        var x1: i32 = 0;
        var x2: i32 = 0;
        var x3: i32 = 0;
        var t0: i32 = 0;
        var t1: i32 = 0;
        var t2: i32 = 0;
        var t3: i32 = 0;

        x0, x1, x2, x3, t0, t1, t2, t3 = idct1D(s0, s1, s2, s3, s4, s5, s6, s7);

        x0 += 512;
        x1 += 512;
        x2 += 512;
        x3 += 512;

        block[0 * 8 + x] = (x0 + t3) >> 10;
        block[1 * 8 + x] = (x1 + t2) >> 10;
        block[2 * 8 + x] = (x2 + t1) >> 10;
        block[3 * 8 + x] = (x3 + t0) >> 10;
        block[4 * 8 + x] = (x3 - t0) >> 10;
        block[5 * 8 + x] = (x2 - t1) >> 10;
        block[6 * 8 + x] = (x1 - t2) >> 10;
        block[7 * 8 + x] = (x0 - t3) >> 10;
    }

    for (0..8) |y| {
        const s0 = block[y * 8 + 0];
        const s1 = block[y * 8 + 1];
        const s2 = block[y * 8 + 2];
        const s3 = block[y * 8 + 3];
        const s4 = block[y * 8 + 4];
        const s5 = block[y * 8 + 5];
        const s6 = block[y * 8 + 6];
        const s7 = block[y * 8 + 7];

        var x0: i32 = 0;
        var x1: i32 = 0;
        var x2: i32 = 0;
        var x3: i32 = 0;
        var t0: i32 = 0;
        var t1: i32 = 0;
        var t2: i32 = 0;
        var t3: i32 = 0;

        x0, x1, x2, x3, t0, t1, t2, t3 = idct1D(s0, s1, s2, s3, s4, s5, s6, s7);

        // add 0.5 scaled up by factor
        x0 += (1 << 17) / 2;
        x1 += (1 << 17) / 2;
        x2 += (1 << 17) / 2;
        x3 += (1 << 17) / 2;

        block[y * 8 + 0] = (x0 + t3) >> 17;
        block[y * 8 + 1] = (x1 + t2) >> 17;
        block[y * 8 + 2] = (x2 + t1) >> 17;
        block[y * 8 + 3] = (x3 + t0) >> 17;
        block[y * 8 + 4] = (x3 - t0) >> 17;
        block[y * 8 + 5] = (x2 - t1) >> 17;
        block[y * 8 + 6] = (x1 - t2) >> 17;
        block[y * 8 + 7] = (x0 - t3) >> 17;
    }
}
