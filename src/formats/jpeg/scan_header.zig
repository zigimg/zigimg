//! This module implements the JPEG Scan header sections described in
//! B.2.3 of https://www.w3.org/Graphics/JPEG/itu-t81.pdf

const std = @import("std");
const Image = @import("../../Image.zig");

const ImageReadError = Image.ReadError;

const Self = @This();

components: [4]?ScanComponentSpec,

///  first DCT coefficient in each block in zig-zag order
start_of_spectral_selection: u8,

/// last DCT coefficient in each block in zig-zag order
/// 63 for sequential DCT, 0 for lossless
/// TODO(angelo) add check for this.
end_of_spectral_selection: u8,
approximation_high: u4,
approximation_low: u4,

const JPEG_DEBUG = false;
const JPEG_VERY_DEBUG = false;

pub fn read(reader: Image.Stream.Reader) ImageReadError!Self {
    var segment_size = try reader.readIntBig(u16);
    if (JPEG_DEBUG) std.debug.print("StartOfScan: segment size = 0x{X}\n", .{segment_size});

    const component_count = try reader.readByte();
    if (component_count < 1 or component_count > 4) {
        return ImageReadError.InvalidData;
    }

    var components = [_]?ScanComponentSpec{null} ** 4;

    if (JPEG_VERY_DEBUG) std.debug.print("  Components:\n", .{});
    var i: usize = 0;
    while (i < component_count) : (i += 1) {
        components[i] = try ScanComponentSpec.read(reader);
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

    if (JPEG_VERY_DEBUG) std.debug.print("  Spectral selection: {}-{}\n", .{ start_of_spectral_selection, end_of_spectral_selection });

    const approximation_bits = try reader.readByte();
    const approximation_high: u4 = @intCast(approximation_bits >> 4);
    const approximation_low: u4 = @intCast(approximation_bits & 0b1111);
    if (JPEG_VERY_DEBUG) std.debug.print("  Approximation bit position: high={} low={}\n", .{ approximation_high, approximation_low });

    std.debug.assert(segment_size == 2 * component_count + 1 + 2 + 1 + 2);

    return Self{
        .components = components,
        .start_of_spectral_selection = start_of_spectral_selection,
        .end_of_spectral_selection = end_of_spectral_selection,
        .approximation_high = approximation_high,
        .approximation_low = approximation_low,
    };
}

pub const ScanComponentSpec = struct {
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