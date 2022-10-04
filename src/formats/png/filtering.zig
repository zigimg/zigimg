const std = @import("std");
const Image = @import("../../Image.zig");

pub const FilterType = enum(u8) {
    None = 0,
    Sub = 1,
    Up = 2,
    Average = 3,
    Paeth = 4,
};

pub const FilterChoiceStrategies = enum {
    TryAll,
    Heuristic,
    Specified,
};

pub const FilterChoice = union(FilterChoiceStrategies) {
    TryAll,
    Heuristic,
    Specified: FilterType,
};

pub fn filter(writer: anytype, image: Image, filter_choice: FilterChoice) !void {
    var scanline: []const u8 = undefined;
    var prev_scanline: ?[]const u8 = null;

    const pixel_len: usize = switch (image.pixels) {
        .rgb24 => 3,
        .rgba32 => 4,
        .grayscale8 => 1,
        .grayscale8Alpha =>  2,
        .indexed8 => 1,
        else => @panic("PNG filtering for this format unimplemented")
    };

    const scanline_len = pixel_len * image.width;
    
    var y: usize = 0;
    while (y < image.height) : (y += 1) {
        scanline = image.pixels.asBytes()[(y * scanline_len)..((y + 1) * scanline_len)];

        const filter_type: FilterType = switch (filter_choice) {
            .Heuristic,
            .TryAll => @panic("Unimplemented"),
            //.Heuristic => filterChoiceHeuristic(bytes, prev_bytes),
            .Specified => |f| f,
        };

        try writer.writeByte(@enumToInt(filter_type));

        switch (filter_type) {
            .None => {
                // Just copy the line
                try writer.writeAll(scanline);
            },
            .Sub => {
                // Substract each pixel with the previous one
                for (scanline) |pix, i| {
                    const prev: u8 = if (i >= pixel_len) scanline[i - pixel_len] else 0;
                    const diff: u8 = pix -% prev;
                    try writer.writeByte(diff);
                }
            },
            .Up => {
                // Substract each pixel from the one above
                for (scanline) |pix, i| {
                    const above: u8 = if (prev_scanline) |b| b[i] else 0;
                    const diff: u8 = pix -% above;
                    try writer.writeByte(diff);
                }
            },
            .Average => {
                for (scanline) |pix, i| {
                    const prev: u8 = if (i >= pixel_len) scanline[i - pixel_len] else 0;
                    const above: u8 = if (prev_scanline) |b| b[i] else 0;
                    const avg: u8 = @truncate(u8, (@intCast(u9, prev) + above) / 2);
                    const diff = pix -% avg;
                    try writer.writeByte(diff);
                }
            },
            .Paeth => {
                for (scanline) |pix, i| {
                    const prev: u8 = if (i >= pixel_len) scanline[i - pixel_len] else 0;
                    const above: u8 = if (prev_scanline) |b| b[i] else 0;
                    const prev_above = if (prev_scanline) |b| (if (i >= pixel_len) b[i - pixel_len] else 0) else 0;
                    const diff = pix -% paeth(prev, above, prev_above);
                    try writer.writeByte(diff);
                }
            }
        }

        prev_scanline = scanline;
    }
}
fn paeth(b4: u8, up: u8, b4_up: u8) u8 {
    const p: i16 = @intCast(i16, b4) + up - b4_up;
    const pa = std.math.absInt(p - b4) catch unreachable;
    const pb = std.math.absInt(p - up) catch unreachable;
    const pc = std.math.absInt(p - b4_up) catch unreachable;

    if (pa <= pb and pa <= pc) {
        return b4;
    } else if (pb <= pc) {
        return up;
    } else {
        return b4_up;
    }
}