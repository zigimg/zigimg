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
