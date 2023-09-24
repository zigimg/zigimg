const color = @import("../../color.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const FrameHeader = @import("frame_header.zig");
const Frame = @import("frame.zig");
const ScanHeader = @import("scan_header.zig");
const ScanComponentSpec = @import("scan_header.zig").ScanComponentSpec;
const HuffmanReader = @import("huffman.zig").Reader;

const MAX_COMPONENTS = @import("utils.zig").MAX_COMPONENTS;
const MAX_BLOCKS = @import("utils.zig").MAX_BLOCKS;
const MCU = @import("utils.zig").MCU;
const ZigzagOffsets = @import("utils.zig").ZigzagOffsets;

const Self = @This();

pub fn performScan(frame: *const Frame, reader: Image.Stream.Reader, pixels_opt: *?color.PixelStorage) ImageReadError!void {
    const scan_header = try ScanHeader.read(reader);

    var prediction_values = [3]i12{ 0, 0, 0 };
    var huffman_reader = HuffmanReader.init(reader);
    var mcu_storage: [MAX_COMPONENTS][MAX_BLOCKS]MCU = undefined;

    const mcu_count = Self.calculateMCUCountInFrame(&frame.frame_header);
    for (0..mcu_count) |mcu_id| {
        try Self.decodeMCU(frame, scan_header, &mcu_storage, &huffman_reader, &prediction_values);
        try Self.dequantize(frame, &mcu_storage);
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

        try Self.decodeMCUComponent(frame, maybe_component.?, mcu_storage, reader, prediction_values);
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

        const dc_coefficient = try Self.decodeDCCoefficient(reader, &prediction_values[component_destination]);
        mcu[0] = dc_coefficient;

        // Decode the AC coefficients
        if (frame.ac_huffman_tables[component.ac_table_selector] == null)
            return ImageReadError.InvalidData;

        reader.setHuffmanTable(&frame.ac_huffman_tables[component.ac_table_selector].?);

        try Self.decodeACCoefficients(reader, mcu);
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