const std = @import("std");

const color = @import("../src/color.zig");
const Image = @import("../src/Image.zig");
const ImageEditor = @import("../src/ImageEditor.zig");

test "Flip image vertically" {
    var unflipped = try Image.create(std.testing.allocator, 8, 8, .rgb24);
    defer unflipped.deinit();
    var flipped = try Image.create(std.testing.allocator, unflipped.width, unflipped.height, .rgb24);
    defer flipped.deinit();

    for (0..unflipped.height) |y| {
        for (0..unflipped.width) |x| {
            const level = 255 / unflipped.height;
            const clr = color.Rgb24{ .r = @intCast(y * level), .g = 0, .b = 0 };
            unflipped.pixels.rgb24[unflipped.width * y + x] = clr;
            flipped.pixels.rgb24[flipped.width * (flipped.height - 1 - y) + x] = clr;
        }
    }

    try unflipped.flipVertically();
    try std.testing.expectEqualSlices(color.Rgb24, unflipped.pixels.rgb24, flipped.pixels.rgb24);
}

test "normalise_simple" {
    const box = (ImageEditor.Box{
        .x = 0,
        .y = 0,
        .width = 10,
        .height = 10,
    }).clamp(10, 10);
    try std.testing.expectEqual(0, box.x);
    try std.testing.expectEqual(0, box.y);
    try std.testing.expectEqual(10, box.width);
    try std.testing.expectEqual(10, box.height);
}

test "normalise_overflow" {
    const box = (ImageEditor.Box{
        .x = 0,
        .y = 0,
        .width = 16,
        .height = 14,
    }).clamp(10, 10);
    try std.testing.expectEqual(0, box.x);
    try std.testing.expectEqual(0, box.y);
    try std.testing.expectEqual(10, box.width);
    try std.testing.expectEqual(10, box.height);
}

test "normalise_overflow2" {
    const box = (ImageEditor.Box{
        .x = 4,
        .y = 6,
        .width = 10,
        .height = 10,
    }).clamp(10, 10);
    try std.testing.expectEqual(4, box.x);
    try std.testing.expectEqual(6, box.y);
    try std.testing.expectEqual(6, box.width);
    try std.testing.expectEqual(4, box.height);
}
