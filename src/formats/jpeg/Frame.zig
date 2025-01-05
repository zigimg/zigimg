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
const MCU = @import("utils.zig").MCU;

const Self = @This();
allocator: Allocator,
frame_header: FrameHeader,
quantization_tables: *[4]?QuantizationTable,
dc_huffman_tables: *[2]?HuffmanTable,
ac_huffman_tables: *[2]?HuffmanTable,
mcu_storage: [][MAX_COMPONENTS][MAX_BLOCKS]MCU,
restart_interval: u16 = 0,
frame_type: Markers = undefined,

const JPEG_DEBUG = false;

pub fn calculateMCUCountInFrame(frame_header: *const FrameHeader) usize {
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

pub fn read(allocator: Allocator, frame_type: Markers, restart_interval: u16, quantization_tables: *[4]?QuantizationTable, dc_huffman_tables: *[2]?HuffmanTable, ac_huffman_tables: *[2]?HuffmanTable, buffered_stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) ImageReadError!Self {
    const reader = buffered_stream.reader();
    const frame_header = try FrameHeader.read(allocator, reader);
    const mcu_count: usize = calculateMCUCountInFrame(&frame_header);

    const mcu_storage = try allocator.alloc([MAX_COMPONENTS][MAX_BLOCKS]MCU, mcu_count);

    var self = Self{
        .allocator = allocator,
        .frame_header = frame_header,
        .quantization_tables = quantization_tables,
        .dc_huffman_tables = dc_huffman_tables,
        .ac_huffman_tables = ac_huffman_tables,
        .mcu_storage = mcu_storage,
        .restart_interval = restart_interval,
        .frame_type = frame_type,
    };
    errdefer self.deinit();

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.mcu_storage);
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
        3 => try self.renderToPixelsRgb(pixels.rgb24),
        else => unreachable,
    }
}

fn renderToPixelsGrayscale(self: *Self, pixels: []color.Grayscale8) ImageReadError!void {
    const mcu_width = 8;
    const mcu_height = 8;
    const width = self.frame_header.samples_per_row;
    const height = pixels.len / width;
    const mcus_per_row = (width + mcu_width - 1) / mcu_width;
    var mcu_id: usize = 0;
    while (mcu_id < self.mcu_storage.len) : (mcu_id += 1) {
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

                const reconstructed_Y = self.mcu_storage[mcu_id][0][0][block_y * 8 + block_x];
                const Y: f32 = @floatFromInt(reconstructed_Y);
                pixels[stride + x] = .{
                    .value = @as(u8, @intFromFloat(std.math.clamp(Y + 128.0, 0.0, 255.0))),
                };
            }
        }
    }
}

fn renderToPixelsRgb(self: *Self, pixels: []color.Rgb24) ImageReadError!void {
    const max_horizontal_sampling_factor = self.frame_header.getMaxHorizontalSamplingFactor();
    const max_vertical_sampling_factor = self.frame_header.getMaxVerticalSamplingFactor();
    const mcu_width = 8 * max_horizontal_sampling_factor; // in pixels
    const mcu_height = 8 * max_vertical_sampling_factor; // in pixels
    const width = self.frame_header.samples_per_row;
    const height = pixels.len / width;
    const mcus_per_row = (width + mcu_width - 1) / mcu_width;

    var mcu_id: usize = 0;
    while (mcu_id < self.mcu_storage.len) : (mcu_id += 1) {
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

                const mcu_Y = &self.mcu_storage[mcu_id][0][y_block_ind];
                const mcu_Cb = &self.mcu_storage[mcu_id][1][cb_block_ind];
                const mcu_Cr = &self.mcu_storage[mcu_id][2][cr_block_ind];

                const Y: f32 = @floatFromInt(mcu_Y[y_block_y * 8 + y_block_x]);
                const Cb: f32 = @floatFromInt(mcu_Cb[cb_block_y * 8 + cb_block_x]);
                const Cr: f32 = @floatFromInt(mcu_Cr[cr_block_y * 8 + cr_block_x]);

                const Co_red = 0.299;
                const Co_green = 0.587;
                const Co_blue = 0.114;

                const r = Cr * (2 - 2 * Co_red) + Y;
                const b = Cb * (2 - 2 * Co_blue) + Y;
                const g = (Y - Co_blue * b - Co_red * r) / Co_green;

                pixels[y * width + x] = .{
                    .r = @intFromFloat(std.math.clamp(r + 128.0, 0.0, 255.0)),
                    .g = @intFromFloat(std.math.clamp(g + 128.0, 0.0, 255.0)),
                    .b = @intFromFloat(std.math.clamp(b + 128.0, 0.0, 255.0)),
                };
            }
        }
    }
}

pub fn dequantizeMCUs(self: *Self) !void {
    var mcu_id: usize = 0;
    while (mcu_id < self.mcu_storage.len) : (mcu_id += 1) {
        for (self.frame_header.components, 0..) |component, component_id| {
            const block_count = self.frame_header.getBlockCount(component_id);
            for (0..block_count) |i| {
                const block = &self.mcu_storage[mcu_id][component_id][i];

                if (self.quantization_tables[component.quantization_table_id]) |quantization_table| {
                    var sample_id: usize = 0;
                    while (sample_id < 64) : (sample_id += 1) {
                        block[sample_id] = block[sample_id] * quantization_table.q8[sample_id];
                    }
                } else return ImageReadError.InvalidData;
            }
        }
    }
}

pub fn idctMCUs(self: *Self) void {
    for (0..self.mcu_storage.len) |mcu_id| {
        for (0..self.frame_header.components.len) |component_id| {
            const block_count: usize = self.frame_header.getBlockCount(component_id);
            for (0..block_count) |i| {
                idctBlock(&self.mcu_storage[mcu_id][component_id][i]);
            }
        }
    }
}

fn idctBlock(mcu: *MCU) void {
    var result: MCU = undefined;

    for (0..8) |y| {
        for (0..8) |x| {
            result[y * 8 + x] = idct(mcu, x, y, 0, 0);
        }
    }

    // write final result back
    for (0..64) |idx| {
        mcu[idx] = result[idx];
    }
}

fn idct(mcu: *const MCU, x: usize, y: usize, mcu_id: usize, component_id: usize) i8 {
    // TODO(angelo): if Ns > 1 it is not interleaved, so the order this should be fixed...
    // FIXME is wrong for Ns > 1
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
