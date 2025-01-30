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
restart_interval: u16 = 0,
frame_type: Markers = undefined,

block_height: u32 = 0,
block_width: u32 = 0,
block_width_actual: u32 = 0,
block_height_actual: u32 = 0,

const JPEG_DEBUG = false;

pub fn read(allocator: Allocator, frame_type: Markers, restart_interval: u16, quantization_tables: *[4]?QuantizationTable, dc_huffman_tables: *[4]?HuffmanTable, ac_huffman_tables: *[4]?HuffmanTable, buffered_stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) ImageReadError!Self {
    const reader = buffered_stream.reader();
    const frame_header = try FrameHeader.read(allocator, reader);

    const horizontal_block_count = frame_header.getMaxHorizontalSamplingFactor();
    const vertical_block_count = frame_header.getMaxVerticalSamplingFactor();

    const mcu_width = 8 * horizontal_block_count; // pixels
    const mcu_height = 8 * vertical_block_count; // pixels
    const width_actual = ((frame_header.width + mcu_width - 1) / mcu_width) * mcu_width; //

    const height_actual = ((frame_header.height + mcu_height - 1) / mcu_height) * mcu_height;
    const block_storage = try allocator.alloc([MAX_COMPONENTS]Block, width_actual * height_actual / 64);

    var self = Self{
        .allocator = allocator,
        .frame_header = frame_header,
        .quantization_tables = quantization_tables,
        .dc_huffman_tables = dc_huffman_tables,
        .ac_huffman_tables = ac_huffman_tables,
        .restart_interval = restart_interval,
        .frame_type = frame_type,
        .block_storage = block_storage,
        .block_height_actual = @intCast((height_actual + 7) / 8),
        .block_width_actual = @intCast((width_actual + 7) / 8),
        .block_height = (frame_header.height + 7) / 8,
        .block_width = (frame_header.width + 7) / 8,
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
            try self.YCbCrToRgb();
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

pub fn YCbCrToRgbBlock(self: *Self, y_block: *[3]Block, cbcr_block: *[3]Block, v: usize, h: usize) void {
    const y_step = self.frame_header.getMaxVerticalSamplingFactor();
    const x_step = self.frame_header.getMaxHorizontalSamplingFactor();

    var y: usize = 8;
    while (y > 0) {
        y -= 1;
        var x: usize = 8;
        while (x > 0) {
            x -= 1;
            const pixel_index: usize = y * 8 + x;
            const Y: f32 = @floatFromInt(y_block[0][pixel_index]);

            const cbcr_y: usize = y / y_step + (8 / y_step) * v;
            const cbcr_x: usize = x / x_step + (8 / x_step) * h;
            const cbcr_pixel: usize = cbcr_y * 8 + cbcr_x;

            const Cb: f32 = @floatFromInt(cbcr_block[1][cbcr_pixel]);
            const Cr: f32 = @floatFromInt(cbcr_block[2][cbcr_pixel]);

            const Co_red = 0.299;
            const Co_green = 0.587;
            const Co_blue = 0.114;

            const r = Cr * (2 - 2 * Co_red) + Y;
            const b = Cb * (2 - 2 * Co_blue) + Y;
            const g = (Y - Co_blue * b - Co_red * r) / Co_green;

            y_block[0][pixel_index] = @intFromFloat(std.math.clamp(r + 128.0, 0.0, 255.0));
            y_block[1][pixel_index] = @intFromFloat(std.math.clamp(g + 128.0, 0.0, 255.0));
            y_block[2][pixel_index] = @intFromFloat(std.math.clamp(b + 128.0, 0.0, 255.0));
        }
    }
}

pub fn YCbCrToRgb(self: *Self) ImageReadError!void {
    const y_step = self.frame_header.getMaxVerticalSamplingFactor();
    const x_step = self.frame_header.getMaxHorizontalSamplingFactor();

    var y: usize = 0;
    while (y < self.block_height) : (y += y_step) {
        var x: usize = 0;
        while (x < self.block_width) : (x += x_step) {
            const v_max = self.frame_header.getMaxVerticalSamplingFactor();
            const h_max = self.frame_header.getMaxHorizontalSamplingFactor();

            const cbcr_block = &self.block_storage[y * self.block_width_actual + x];

            var v: usize = v_max;
            while (v > 0) {
                v -= 1;
                var h: usize = h_max;
                while (h > 0) {
                    h -= 1;
                    const y_block = &self.block_storage[(y + v) * self.block_width_actual + (x + h)];
                    YCbCrToRgbBlock(self, y_block, cbcr_block, v, h);
                }
            }
        }
    }
}

pub fn dequantizeMCUs(self: *Self) !void {
    const y_step = self.frame_header.getMaxVerticalSamplingFactor();
    const x_step = self.frame_header.getMaxHorizontalSamplingFactor();

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
                        if (self.quantization_tables[component.quantization_table_id]) |quantization_table| {
                            for (0..64) |sample_id| {
                                block[sample_id] = block[sample_id] * quantization_table.q8[sample_id];
                            }
                        } else return ImageReadError.InvalidData;
                    }
                }
            }
        }
    }
}

pub fn idctMCUs(self: *Self) void {
    const y_step = self.frame_header.getMaxVerticalSamplingFactor();
    const x_step = self.frame_header.getMaxHorizontalSamplingFactor();

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
    var result: Block = undefined;

    for (0..8) |y| {
        for (0..8) |x| {
            result[y * 8 + x] = idct(block, x, y, 0, 0);
        }
    }

    // write final result back
    for (0..64) |idx| {
        block[idx] = result[idx];
    }
}

fn idct(block: *const Block, x: usize, y: usize, mcu_id: usize, component_id: usize) i8 {
    // TODO(angelo): if Ns > 1 it is not interleaved, so the order this should be fixed...
    // FIXME is wrong for Ns > 1
    var reconstructed_pixel: f32 = 0.0;

    var u: usize = 0;
    while (u < 8) : (u += 1) {
        var v: usize = 0;
        while (v < 8) : (v += 1) {
            const block_value = block[v * 8 + u];
            reconstructed_pixel += IDCTMultipliers[y][x][u][v] * @as(f32, @floatFromInt(block_value));
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
