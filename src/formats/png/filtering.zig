const std = @import("std");
const color = @import("../../color.zig");
const PixelFormat = @import("../../pixel_format.zig").PixelFormat;
const Image = @import("../../Image.zig");
const HeaderData = @import("types.zig").HeaderData;
const builtin = @import("builtin");

pub const FilterType = enum(u8) {
    none = 0,
    sub = 1,
    up = 2,
    average = 3,
    paeth = 4,
};

pub const FilterChoiceStrategies = enum {
    try_all,
    heuristic,
    specified,
};

pub const FilterChoice = union(FilterChoiceStrategies) {
    try_all,
    heuristic,
    specified: FilterType,
};

pub fn filter(allocator: std.mem.Allocator, writer: anytype, pixels: color.PixelStorage, filter_choice: FilterChoice, header: HeaderData) Image.WriteError!void {
    const line_bytes = header.lineBytes();
    const scanline_allocation_size = 2 * line_bytes;

    const scanline_buffer = try allocator.alloc(u8, scanline_allocation_size);
    defer allocator.free(scanline_buffer);

    const previous_scanline_row = scanline_buffer[0..line_bytes];
    const current_scanline_row = scanline_buffer[line_bytes..(2 * line_bytes)];

    // Fill previous scanline with 0
    @memset(previous_scanline_row, 0);

    const format: PixelFormat = pixels;

    const pixel_len = format.pixelStride();

    var y: usize = 0;
    while (y < header.height) : (y += 1) {
        fillScanline(pixels, current_scanline_row, y, header.width);

        const filter_type: FilterType = switch (filter_choice) {
            .try_all => @panic("Unimplemented"),
            .heuristic => filterChoiceHeuristic(current_scanline_row, previous_scanline_row),
            .specified => |f| f,
        };

        writer.writeByte(@intFromEnum(filter_type)) catch return Image.WriteError.InvalidData;

        for (0..current_scanline_row.len) |byte_index| {
            const i = byte_index;

            const sample = current_scanline_row[i];
            const previous: u8 = if (byte_index >= pixel_len) current_scanline_row[i - pixel_len] else 0;
            const above: u8 = previous_scanline_row[i];
            const above_previous = if (byte_index >= pixel_len) previous_scanline_row[i - pixel_len] else 0;

            const byte: u8 = switch (filter_type) {
                .none => sample,
                .sub => sample -% previous,
                .up => sample -% above,
                .average => sample -% average(previous, above),
                .paeth => sample -% paeth(previous, above, above_previous),
            };

            writer.writeByte(byte) catch return Image.WriteError.InvalidData;
        }

        @memcpy(previous_scanline_row, current_scanline_row);
    }
}

fn fillScanline(pixels: color.PixelStorage, scanline_bytes: []u8, y: usize, width: usize) void {
    const pixels_scanline = pixels.slice(y * width, (y + 1) * width);
    const pixel_format: PixelFormat = std.meta.activeTag(pixels);
    const bit_depth = pixel_format.bitsPerChannel();
    switch (bit_depth) {
        1, 2, 4 => {
            const source_row_bytes = pixels_scanline.asConstBytes();

            @memset(scanline_bytes, 0);

            var destination_index: usize = 0;

            const bit_depth_reduced: u3 = @intCast(bit_depth);

            var shift: i8 = @intCast(8 - bit_depth);
            const mask: u8 = (@as(u8, 1) << bit_depth_reduced) - 1;

            for (source_row_bytes) |source_byte| {
                scanline_bytes[destination_index] |= (source_byte & mask) << @as(u3, @intCast(shift));
                shift -= bit_depth_reduced;
                if (shift < 0) {
                    destination_index += 1;
                    if (destination_index >= scanline_bytes.len) {
                        break;
                    }
                    shift = @intCast(8 - bit_depth);
                }
            }
        },
        8 => {
            const source_row_bytes = pixels_scanline.asConstBytes();

            @memcpy(scanline_bytes, source_row_bytes);
        },
        16 => {
            const source_row_bytes = pixels_scanline.asConstBytes();

            const source_row_u16 = std.mem.bytesAsSlice(u16, source_row_bytes);
            var destination_scanline_u16 = std.mem.bytesAsSlice(u16, scanline_bytes);

            const need_byteswap = builtin.target.cpu.arch.endian() == .little;

            const length = scanline_bytes.len / 2;
            for (0..length) |index| {
                destination_scanline_u16[index] = if (need_byteswap) @byteSwap(source_row_u16[index]) else source_row_u16[index];
            }
        },
        else => {},
    }
}

fn filterChoiceHeuristic(scanline: []const u8, previous_scanline: []const u8) FilterType {
    const pixel_len = scanline.len;

    const filter_types = [_]FilterType{ .none, .sub, .up, .average, .paeth };

    var previous_bytes: [filter_types.len]u8 = @splat(0);
    var combos: [filter_types.len]usize = @splat(0);
    var scores: [filter_types.len]usize = @splat(0);

    for (scanline, 0..) |sample, i| {
        const previous: u8 = if (i >= pixel_len) scanline[i - pixel_len] else 0;
        const above: u8 = previous_scanline[i];
        const above_previous = if (i >= pixel_len) previous_scanline[i - pixel_len] else 0;

        inline for (filter_types, &previous_bytes, &combos, &scores) |filter_type, *previous_byte, *combo, *score| {
            const byte: u8 = switch (filter_type) {
                .none => sample,
                .sub => sample -% previous,
                .up => sample -% above,
                .average => sample -% average(previous, above),
                .paeth => sample -% paeth(previous, above, above_previous),
            };

            if (byte == previous_byte.*) {
                combo.* += 1;
            } else {
                score.* += combo.* * combo.*;
                combo.* = 0;
                previous_byte.* = byte;
            }
        }
    }

    var best: FilterType = .none;
    var max_score: usize = 0;
    inline for (filter_types, scores) |filter_type, score| {
        if (score > max_score) {
            max_score = score;
            best = filter_type;
        }
    }
    return best;
}

fn average(a: u9, b: u9) u8 {
    return @truncate((a + b) / 2);
}

fn paeth(b4: u8, up: u8, b4_up: u8) u8 {
    const p: i16 = @as(i16, @intCast(b4)) + up - b4_up;
    const pa = @abs(p - b4);
    const pb = @abs(p - up);
    const pc = @abs(p - b4_up);

    if (pa <= pb and pa <= pc) {
        return b4;
    } else if (pb <= pc) {
        return up;
    } else {
        return b4_up;
    }
}

test "filtering 16-bit grayscale pixels uses correct endianess" {
    var output_bytes = std.ArrayList(u8).init(std.testing.allocator);
    defer output_bytes.deinit();

    const pixels = try std.testing.allocator.dupe(color.Grayscale16, &.{
        .{ .value = 0xF },
        .{ .value = 0xFF },
        .{ .value = 0xFFF },
        .{ .value = 0xFFFF },
        .{ .value = 0xF },
        .{ .value = 0xFF },
        .{ .value = 0xFFF },
        .{ .value = 0xFFFF },
    });
    defer std.testing.allocator.free(pixels);

    // We specify the endianess as none to simplify the test
    try filter(std.testing.allocator, output_bytes.writer(), .{ .grayscale16 = pixels }, .{ .specified = .none }, .{
        .width = 4,
        .height = 2,
        .bit_depth = 16,
        .color_type = .grayscale,
        .compression_method = .deflate,
        .filter_method = .adaptive,
        .interlace_method = .none,
    });

    try std.testing.expectEqualSlices(u8, &.{
        0x00, 0x00, 0x0F, 0x00, 0xFF, 0x0F, 0xFF, 0xFF, 0xFF, //
        0x00, 0x00, 0x0F, 0x00, 0xFF, 0x0F, 0xFF, 0xFF, 0xFF, //
    }, output_bytes.items);
}
