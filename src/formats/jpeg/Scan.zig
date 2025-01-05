const std = @import("std");

const buffered_stream_source = @import("../../buffered_stream_source.zig");
const color = @import("../../color.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const Markers = @import("utils.zig").Markers;
const FrameHeader = @import("FrameHeader.zig");
const Frame = @import("Frame.zig");
const HuffmanReader = @import("huffman.zig").Reader;

const MCU = @import("utils.zig").MCU;
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

prediction_values: [3]i12,

pub fn init(frame: *const Frame, reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!Self {
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
        .reader = HuffmanReader.init(reader),
        .components = components,
        .component_count = component_count,
        .start_of_spectral_selection = start_of_spectral_selection,
        .end_of_spectral_selection = end_of_spectral_selection,
        .approximation_high = approximation_high,
        .approximation_low = approximation_low,
        .prediction_values = [3]i12{ 0, 0, 0 },
    };
}

/// Perform the scan operation.
/// We assume the AC and DC huffman tables are already set up, and ready to decode.
/// This should implement section E.2.3 of t-81 1992.
pub fn performScan(frame: *const Frame, reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!void {
    var self = try Self.init(frame, reader);

    const mcu_count = Frame.calculateMCUCountInFrame(&self.frame.frame_header);
    for (0..mcu_count) |mcu_id| {
        if (frame.restart_interval != 0 and mcu_id % frame.restart_interval == 0) {
            self.reader.flushBits();
            self.prediction_values = @splat(0);
        }
        try self.decodeMCU(mcu_id);
    }
}

fn decodeMCU(self: *Self, mcu_id: usize) ImageReadError!void {
    for (0..self.component_count) |index| {
        const component: ScanComponentSpec = self.components[index].?;

        var component_index: usize = undefined;
        for (self.frame.frame_header.components, 0..) |frame_component, i| {
            if (frame_component.id == component.component_id) {
                component_index = i;
                std.debug.assert(component_index < self.component_count);
            }
        }

        const block_count = self.frame.frame_header.getBlockCount(component_index);
        for (0..block_count) |i| {
            const mcu = &self.frame.mcu_storage[mcu_id][component_index][i];

            // Decode the DC coefficient
            self.reader.setHuffmanTable(&self.frame.dc_huffman_tables[component.dc_table_selector].?);

            try self.decodeDCCoefficient(mcu, component_index);

            // Decode the AC coefficients
            self.reader.setHuffmanTable(&self.frame.ac_huffman_tables[component.ac_table_selector].?);

            try self.decodeACCoefficients(mcu);
        }
    }
}

fn decodeDCCoefficient(self: *Self, mcu: *MCU, component_destination: usize) ImageReadError!void {
    if (self.start_of_spectral_selection == 0) {
        const maybe_magnitude = try self.reader.readCode();
        if (maybe_magnitude > 11) return ImageReadError.InvalidData;
        const magnitude: u4 = @intCast(maybe_magnitude);

        const diff: i12 = @intCast(try self.reader.readMagnitudeCoded(magnitude));
        const dc_coefficient = diff + self.prediction_values[component_destination];
        self.prediction_values[component_destination] = dc_coefficient;

        mcu[0] = dc_coefficient;
    }
}

fn decodeACCoefficients(self: *Self, mcu: *MCU) ImageReadError!void {
    var ac: usize = undefined;
    if (self.frame.frame_type == Markers.sof0) {
        ac = 1;
    } else if (self.frame.frame_type == Markers.sof2) {
        if (self.start_of_spectral_selection == 0) return;
        ac = self.start_of_spectral_selection;
    }
    var did_see_eob = false;
    while (ac < self.end_of_spectral_selection + 1) : (ac += 1) {
        if (did_see_eob) {
            mcu[ZigzagOffsets[ac]] = 0;
            continue;
        }

        const zero_run_length_and_magnitude = try self.reader.readCode();
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

        const ac_coefficient: i11 = @intCast(try self.reader.readMagnitudeCoded(magnitude));

        var i: usize = 0;
        while (i < zero_run_length) : (i += 1) {
            mcu[ZigzagOffsets[ac]] = 0;
            ac += 1;
        }

        mcu[ZigzagOffsets[ac]] = ac_coefficient;
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
