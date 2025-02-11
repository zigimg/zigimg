const std = @import("std");

const buffered_stream_source = @import("../../buffered_stream_source.zig");
const color = @import("../../color.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const Markers = @import("utils.zig").Markers;
const FrameHeader = @import("FrameHeader.zig");
const Frame = @import("Frame.zig");
const HuffmanReader = @import("huffman.zig").Reader;

const Block = @import("utils.zig").Block;
const ZigzagOffsets = @import("utils.zig").ZigzagOffsets;

const Self = @This();

const JPEG_DEBUG = false;
const JPEG_VERY_DEBUG = false;

frame: *const Frame,
reader: HuffmanReader,

components: [4]?ScanComponentSpec,
component_count: u8,
start_of_spectral_selection: u8,
end_of_spectral_selection: u8,
approximation_high: u4,
approximation_low: u4,

prediction_values: [3]i32,

pub fn init(frame: *const Frame, stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) ImageReadError!Self {
    const reader = stream.reader();
    const segment_size = try reader.readInt(u16, .big);
    if (JPEG_DEBUG) std.debug.print("StartOfScan: segment size = 0x{X}\n", .{segment_size});

    const component_count = try reader.readByte();
    if (component_count < 1 or component_count > 4) {
        return ImageReadError.InvalidData;
    }

    if (JPEG_DEBUG) std.debug.print("  Component count: {}\n", .{component_count});

    var components: [4]?ScanComponentSpec = @splat(null);

    if (JPEG_VERY_DEBUG) std.debug.print("  Components:\n", .{});
    var i: usize = 0;
    while (i < component_count) : (i += 1) {
        components[i] = try ScanComponentSpec.read(reader);

        var valid_component: bool = false;
        for (frame.frame_header.components) |frame_component| {
            if (frame_component.id == components[i].?.component_id) {
                valid_component = true;
            }
        }

        if (frame.dc_huffman_tables[components[i].?.dc_table_selector] != null) {
            valid_component = true;
        }
        if (frame.ac_huffman_tables[components[i].?.ac_table_selector] != null) {
            valid_component = true;
        }

        if (!valid_component) {
            return ImageReadError.InvalidData;
        }
    }

    const start_of_spectral_selection = try reader.readByte();
    const end_of_spectral_selection = try reader.readByte();

    if (start_of_spectral_selection > 63 or end_of_spectral_selection > 63) {
        return ImageReadError.InvalidData;
    }

    if (end_of_spectral_selection < start_of_spectral_selection) {
        return ImageReadError.InvalidData;
    }

    if (frame.frame_type == Markers.sof0) {
        if (start_of_spectral_selection != 0 or end_of_spectral_selection != 63) {
            return ImageReadError.InvalidData;
        }
    }

    if (frame.frame_type == Markers.sof2) {
        const any_zero: bool = start_of_spectral_selection == 0 or end_of_spectral_selection == 0;
        const both_zero: bool = start_of_spectral_selection == 0 and end_of_spectral_selection == 0;
        if (any_zero and !both_zero) {
            return ImageReadError.InvalidData;
        }
    }

    if (JPEG_VERY_DEBUG) std.debug.print("  Spectral selection: {}-{}\n", .{ start_of_spectral_selection, end_of_spectral_selection });

    const approximation_bits = try reader.readByte();
    const approximation_high: u4 = @intCast(approximation_bits >> 4);
    const approximation_low: u4 = @intCast(approximation_bits & 0b1111);
    if (JPEG_VERY_DEBUG) std.debug.print("  Approximation bit position: high={} low={}\n", .{ approximation_high, approximation_low });

    std.debug.assert(segment_size == 2 * component_count + 1 + 2 + 1 + 2);

    return Self{
        .frame = frame,
        .reader = HuffmanReader.init(stream),
        .components = components,
        .component_count = component_count,
        .start_of_spectral_selection = start_of_spectral_selection,
        .end_of_spectral_selection = end_of_spectral_selection,
        .approximation_high = approximation_high,
        .approximation_low = approximation_low,
        .prediction_values = @splat(0),
    };
}

/// Perform the scan operation.
/// We assume the AC and DC huffman tables are already set up, and ready to decode.
/// This should implement section E.2.3 of t-81 1992.
pub fn performScan(frame: *const Frame, restart_interval: u16, stream: *buffered_stream_source.DefaultBufferedStreamSourceReader) ImageReadError!void {
    var self = try Self.init(frame, stream);

    var skips: u32 = 0;

    const noninterleaved = self.component_count == 1 and self.components[0].?.component_id == 1;

    const y_step = if (noninterleaved) 1 else frame.vertical_sampling_factor_max;
    const x_step = if (noninterleaved) 1 else frame.horizontal_sampling_factor_max;

    var y: usize = 0;
    while (y < self.frame.block_height) : (y += y_step) {
        var x: usize = 0;
        while (x < self.frame.block_width) : (x += x_step) {
            const mcu_id = y * self.frame.block_width_actual + x;

            if (restart_interval != 0 and mcu_id % (restart_interval * y_step * x_step) == 0) {
                self.reader.flushBits();
                self.prediction_values = @splat(0);
                skips = 0;
            }
            for (0..self.component_count) |index| {
                const component: ScanComponentSpec = self.components[index].?;

                var component_index: usize = undefined;
                var v_max: usize = undefined;
                var h_max: usize = undefined;

                for (self.frame.frame_header.components, 0..) |frame_component, i| {
                    if (frame_component.id == component.component_id) {
                        component_index = i;
                        v_max = if (noninterleaved) 1 else frame_component.vertical_sampling_factor;
                        h_max = if (noninterleaved) 1 else frame_component.horizontal_sampling_factor;
                        break;
                    }
                }

                for (0..v_max) |v| {
                    for (0..h_max) |h| {
                        const block_id = (y + v) * self.frame.block_width_actual + (x + h);
                        const block = &self.frame.block_storage[block_id][component_index];

                        self.reader.fillBits(24) catch {};
                        if (self.frame.frame_type == Markers.sof0) {
                            try self.decodeBlockBaseline(&component, block, component_index);
                        } else if (self.frame.frame_type == Markers.sof2) {
                            try self.decodeBlockProgressive(&component, block, component_index, &skips);
                        }
                    }
                }
            }
        }
    }
}

fn decodeBlockProgressive(self: *Self, component: *const ScanComponentSpec, block: *Block, component_index: usize, skips: *u32) ImageReadError!void {
    if (self.start_of_spectral_selection == 0) {
        self.reader.setHuffmanTable(&self.frame.dc_huffman_tables[component.dc_table_selector].?);
        if (self.approximation_high == 0) {
            const maybe_magnitude = try self.reader.readCode();
            if (maybe_magnitude > 11) return ImageReadError.InvalidData;
            const diff = try self.reader.readMagnitudeCoded(@intCast(maybe_magnitude));
            const dc_coefficient = diff + self.prediction_values[component_index];
            self.prediction_values[component_index] = dc_coefficient;
            block[0] = dc_coefficient << self.approximation_low;
        } else if (self.approximation_high != 0) {
            const bit: u32 = try self.reader.readBits(1);
            block[0] += @bitCast(bit << self.approximation_low);
        }
    } else if (self.start_of_spectral_selection != 0) {
        self.reader.setHuffmanTable(&self.frame.ac_huffman_tables[component.ac_table_selector].?);
        if (self.approximation_high == 0) {
            var ac: usize = self.start_of_spectral_selection;
            if (skips.* == 0) {
                while (ac <= self.end_of_spectral_selection) {
                    var coeff: i32 = 0;
                    const zero_run_length_and_magnitude = try self.reader.readCode();
                    const zero_run_length = zero_run_length_and_magnitude >> 4;
                    const maybe_magnitude = zero_run_length_and_magnitude & 0x0F;

                    if (maybe_magnitude == 0) {
                        if (zero_run_length < 15) {
                            const extra_skips: u32 = try self.reader.readBits(@intCast(zero_run_length));
                            skips.* = (@as(u32, 1) << @intCast(zero_run_length));
                            skips.* += extra_skips;
                            break; // process skips
                        } // no special case for zrl == 15
                    } else if (maybe_magnitude != 0) {
                        if (maybe_magnitude > 10) return ImageReadError.InvalidData;
                        coeff = try self.reader.readMagnitudeCoded(@intCast(maybe_magnitude));
                    }

                    for (0..zero_run_length) |_| {
                        block[ZigzagOffsets[ac]] = 0;
                        ac += 1;
                    }
                    block[ZigzagOffsets[ac]] = coeff << self.approximation_low;
                    ac += 1;
                }
            }

            if (skips.* > 0) {
                skips.* -= 1;
                while (ac <= self.end_of_spectral_selection) {
                    block[ZigzagOffsets[ac]] = 0;
                    ac += 1;
                }
            }
        } else if (self.approximation_high != 0) {
            const bit: i32 = @as(i32, 1) << self.approximation_low;
            var ac: usize = self.start_of_spectral_selection;
            if (skips.* == 0) {
                while (ac <= self.end_of_spectral_selection) {
                    var coeff: i32 = 0;
                    const zero_run_length_and_magnitude = try self.reader.readCode();
                    var zero_run_length = zero_run_length_and_magnitude >> 4;
                    const maybe_magnitude = zero_run_length_and_magnitude & 0x0F;

                    if (maybe_magnitude == 0) {
                        if (zero_run_length < 15) {
                            skips.* = (@as(u32, 1) << @intCast(zero_run_length));
                            const extra_skips: u32 = try self.reader.readBits(@intCast(zero_run_length));
                            skips.* += extra_skips;
                            break; // start processing skips
                        } // no special treatment for zero_run_length == 15
                    } else if (maybe_magnitude != 0) {
                        const sign_bit: u32 = try self.reader.readBits(1);
                        coeff = if (sign_bit == 1) bit else -bit;
                    }

                    while (ac <= self.end_of_spectral_selection) {
                        if (block[ZigzagOffsets[ac]] == 0) {
                            if (zero_run_length > 0) {
                                zero_run_length -= 1;
                                ac += 1;
                            } else {
                                block[ZigzagOffsets[ac]] = coeff;
                                ac += 1;
                                break;
                            }
                        } else {
                            const sign_bit: u32 = try self.reader.readBits(1);
                            if (sign_bit != 0) {
                                block[ZigzagOffsets[ac]] += if (block[ZigzagOffsets[ac]] > 0) bit else -bit;
                            }
                            ac += 1;
                        }
                    }
                }
            }

            if (skips.* > 0) {
                while (ac <= self.end_of_spectral_selection) : (ac += 1) {
                    if (block[ZigzagOffsets[ac]] != 0) {
                        const sign_bit: u32 = try self.reader.readBits(1);
                        if (sign_bit != 0) {
                            block[ZigzagOffsets[ac]] += if (block[ZigzagOffsets[ac]] > 0) bit else -bit;
                        }
                    }
                }
                skips.* -= 1;
            }
        }
    }
}

fn decodeBlockBaseline(self: *Self, component: *const ScanComponentSpec, block: *Block, component_destination: usize) ImageReadError!void {
    // decode DC coefficient
    self.reader.setHuffmanTable(&self.frame.dc_huffman_tables[component.dc_table_selector].?);
    var maybe_magnitude = try self.reader.readCode();
    if (maybe_magnitude > 11) return ImageReadError.InvalidData;
    const diff: i32 = try self.reader.readMagnitudeCoded(@intCast(maybe_magnitude));
    const dc_coefficient = diff + self.prediction_values[component_destination];
    self.prediction_values[component_destination] = dc_coefficient;

    block[0] = dc_coefficient;

    // decode AC coefficients
    self.reader.setHuffmanTable(&self.frame.ac_huffman_tables[component.ac_table_selector].?);
    var ac: usize = 1;
    while (ac < 64) : (ac += 1) {
        const zero_run_length_and_magnitude = try self.reader.readCode();
        // 00 == EOB
        if (zero_run_length_and_magnitude == 0x00) {
            while (ac < 64) : (ac += 1) {
                block[ZigzagOffsets[ac]] = 0;
            }
            return;
        }

        const zero_run_length = zero_run_length_and_magnitude >> 4;
        maybe_magnitude = zero_run_length_and_magnitude & 0xF;
        if (maybe_magnitude > 10) return ImageReadError.InvalidData;

        const ac_coefficient: i11 = @intCast(try self.reader.readMagnitudeCoded(@intCast(maybe_magnitude)));

        for (0..zero_run_length) |_| {
            block[ZigzagOffsets[ac]] = 0;
            ac += 1;
        }

        block[ZigzagOffsets[ac]] = ac_coefficient;
    }
}

pub const ScanComponentSpec = struct {
    component_id: u8,
    dc_table_selector: u4,
    ac_table_selector: u4,

    pub fn read(reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!ScanComponentSpec {
        const component_id = try reader.readByte();
        const entropy_coding_selectors = try reader.readByte();

        const dc_table_selector: u4 = @intCast(entropy_coding_selectors >> 4);
        const ac_table_selector: u4 = @intCast(entropy_coding_selectors & 0b11);

        if (JPEG_VERY_DEBUG) {
            std.debug.print("    Component spec: selector={}, DC table ID={}, AC table ID={}\n", .{ component_id, dc_table_selector, ac_table_selector });
        }

        return ScanComponentSpec{
            .component_id = component_id,
            .dc_table_selector = dc_table_selector,
            .ac_table_selector = ac_table_selector,
        };
    }
};
