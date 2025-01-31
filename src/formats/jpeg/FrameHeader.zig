//! this module implements the frame header followint the t-81 specs,
//! section b.2.2 Frame Header Syntax

const std = @import("std");

const buffered_stream_source = @import("../../buffered_stream_source.zig");
const Image = @import("../../Image.zig");
const ImageReadError = Image.ReadError;

const Markers = @import("utils.zig").Markers;

const Allocator = std.mem.Allocator;

const JPEG_DEBUG = false;

const Component = struct {
    id: u8,
    horizontal_sampling_factor: u4,
    vertical_sampling_factor: u4,
    quantization_table_id: u8,

    pub fn read(reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!Component {
        const component_id = try reader.readByte();
        const sampling_factors = try reader.readByte();
        const quantization_table_id = try reader.readByte();

        const horizontal_sampling_factor: u4 = @intCast(sampling_factors >> 4);
        const vertical_sampling_factor: u4 = @intCast(sampling_factors & 0xF);

        if (horizontal_sampling_factor < 1 or horizontal_sampling_factor > 4) {
            // TODO(angelo): error, create cusotm error
            return ImageReadError.InvalidData;
        }

        if (vertical_sampling_factor < 1 or vertical_sampling_factor > 4) {
            // TODO(angelo): error, create custom error
            return ImageReadError.InvalidData;
        }

        if (quantization_table_id > 3) {
            // TODO(angelo): error, create custom error
            return ImageReadError.InvalidData;
        }

        return Component{
            .id = component_id,
            .horizontal_sampling_factor = horizontal_sampling_factor,
            .vertical_sampling_factor = vertical_sampling_factor,
            .quantization_table_id = quantization_table_id,
        };
    }
};

const Self = @This();

allocator: Allocator,
sample_precision: u8,
height: u16,
width: u16,
components: []Component,

pub fn read(allocator: Allocator, reader: buffered_stream_source.DefaultBufferedStreamSourceReader.Reader) ImageReadError!Self {
    const segment_size = try reader.readInt(u16, .big);
    if (JPEG_DEBUG) std.debug.print("StartOfFrame: frame size = 0x{X}\n", .{segment_size});

    const sample_precision = try reader.readByte();
    const height = try reader.readInt(u16, .big);
    const width = try reader.readInt(u16, .big);

    const component_count = try reader.readByte();

    if (component_count != 1 and component_count != 3) {
        // TODO(angelo): use jpeg error here, for components
        return ImageReadError.InvalidData;
    }

    if (JPEG_DEBUG) std.debug.print("  {}x{}, precision={}, {} components\n", .{ height, width, sample_precision, component_count });

    var components = try allocator.alloc(Component, component_count);
    errdefer allocator.free(components);

    var i: usize = 0;
    while (i < component_count) : (i += 1) {
        components[i] = try Component.read(reader);
    }

    // see B 8.2 table for the meaning of this check.
    std.debug.assert(segment_size == 8 + 3 * component_count);

    return Self{
        .allocator = allocator,
        .sample_precision = sample_precision,
        .height = height,
        .width = width,
        .components = components,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.components);
}

pub fn getMaxHorizontalSamplingFactor(self: Self) usize {
    var ret: u4 = 0;
    for (self.components) |component| {
        if (ret < component.horizontal_sampling_factor) {
            ret = component.horizontal_sampling_factor;
        }
    }

    return ret;
}

pub fn getMaxVerticalSamplingFactor(self: Self) usize {
    var ret: u4 = 0;
    for (self.components) |component| {
        if (ret < component.vertical_sampling_factor) {
            ret = component.vertical_sampling_factor;
        }
    }

    return ret;
}
