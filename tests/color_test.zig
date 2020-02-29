const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const color = @import("zigimg").color;
usingnamespace @import("helpers.zig");

test "Convert color to premultipled alpha" {
    const originalColor = color.Color.initRGBA(100, 128, 210, 100);
    const premultipliedAlpha = originalColor.premultipliedAlpha();

    expectEq(premultipliedAlpha.R, 39);
    expectEq(premultipliedAlpha.G, 50);
    expectEq(premultipliedAlpha.B, 82);
    expectEq(premultipliedAlpha.A, 100);
}

test "Convert Rgb24 to Color" {
    const originalColor = color.Rgb24.initRGB(100, 128, 210);
    const result = originalColor.toColor();

    expectEq(result.R, 100);
    expectEq(result.G, 128);
    expectEq(result.B, 210);
    expectEq(result.A, 255);
}

test "Convert Rgba32 to Color" {
    const originalColor = color.Rgba32.initRGBA(1, 2, 3, 4);
    const result = originalColor.toColor();

    expectEq(result.R, 1);
    expectEq(result.G, 2);
    expectEq(result.B, 3);
    expectEq(result.A, 4);
}

test "Convert Rgb565 to Color" {
    const originalColor = color.Rgb565.initRGB(10, 30, 20);
    const result = originalColor.toColor();

    expectEq(result.R, 82);
    expectEq(result.G, 121);
    expectEq(result.B, 165);
    expectEq(result.A, 255);
}

test "Convert Rgb555 to Color" {
    const originalColor = color.Rgb555.initRGB(16, 20, 24);
    const result = originalColor.toColor();

    expectEq(result.R, 132);
    expectEq(result.G, 165);
    expectEq(result.B, 197);
    expectEq(result.A, 255);
}

test "Convert Argb32 to Color" {
    const originalColor = color.Argb32.initRGBA(50, 100, 150, 200);
    const result = originalColor.toColor();

    expectEq(result.R, 50);
    expectEq(result.G, 100);
    expectEq(result.B, 150);
    expectEq(result.A, 200);
}
