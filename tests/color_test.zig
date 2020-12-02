const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const color = @import("zigimg").color;
usingnamespace @import("helpers.zig");

test "Convert color to premultipled alpha" {
    const originalColor = color.Color.initRGBA(100 / 255, 128 / 255, 210 / 255, 100 / 255);
    const premultipliedAlpha = originalColor.premultipliedAlpha();

    expectEq(premultipliedAlpha.R, 39 / 255);
    expectEq(premultipliedAlpha.G, 50 / 255);
    expectEq(premultipliedAlpha.B, 82 / 255);
    expectEq(premultipliedAlpha.A, 100 / 255);
}

test "Convert Rgb24 to Color" {
    const originalColor = color.Rgb24.initRGB(100, 128, 210);
    const result = originalColor.toColor().toIntegerColor8();

    expectEq(result.R, 100);
    expectEq(result.G, 128);
    expectEq(result.B, 210);
    expectEq(result.A, 255);
}

test "Convert Rgba32 to Color" {
    const originalColor = color.Rgba32.initRGBA(1, 2, 3, 4);
    const result = originalColor.toColor().toIntegerColor8();

    expectEq(result.R, 1);
    expectEq(result.G, 2);
    expectEq(result.B, 3);
    expectEq(result.A, 4);
}

test "Convert Rgb565 to Color" {
    const originalColor = color.Rgb565.initRGB(10, 30, 20);
    const result = originalColor.toColor().toIntegerColor8();

    expectEq(result.R, 82);
    expectEq(result.G, 121);
    expectEq(result.B, 165);
    expectEq(result.A, 255);
}

test "Convert Rgb555 to Color" {
    const originalColor = color.Rgb555.initRGB(16, 20, 24);
    const result = originalColor.toColor().toIntegerColor8();

    expectEq(result.R, 132);
    expectEq(result.G, 165);
    expectEq(result.B, 197);
    expectEq(result.A, 255);
}

test "Convert Argb32 to Color" {
    const originalColor = color.Argb32.initRGBA(50, 100, 150, 200);
    const result = originalColor.toColor().toIntegerColor8();

    expectEq(result.R, 50);
    expectEq(result.G, 100);
    expectEq(result.B, 150);
    expectEq(result.A, 200);
}

test "Convert Grayscale1 to Color" {
    const white = color.Grayscale1{ .value = 1 };
    const whiteColor = white.toColor().toIntegerColor8();

    expectEq(whiteColor.R, 255);
    expectEq(whiteColor.G, 255);
    expectEq(whiteColor.B, 255);
    expectEq(whiteColor.A, 255);

    const black = color.Grayscale1{ .value = 0 };
    const blackColor = black.toColor().toIntegerColor8();

    expectEq(blackColor.R, 0);
    expectEq(blackColor.G, 0);
    expectEq(blackColor.B, 0);
    expectEq(blackColor.A, 255);
}

test "Convert Grayscale8 to Color" {
    const original = color.Grayscale8{ .value = 128 };
    const result = original.toColor().toIntegerColor8();

    expectEq(result.R, 128);
    expectEq(result.G, 128);
    expectEq(result.B, 128);
    expectEq(result.A, 255);
}

test "Convert Grayscale16 to Color" {
    const original = color.Grayscale16{ .value = 21845 };
    const result = original.toColor().toIntegerColor8();

    expectEq(result.R, 85);
    expectEq(result.G, 85);
    expectEq(result.B, 85);
    expectEq(result.A, 255);
}

test "From HTMl hex to IntegerColor" {
    const actual = color.IntegerColor8.fromHtmlHex(0x876347);

    expectEq(actual.R, 0x87);
    expectEq(actual.G, 0x63);
    expectEq(actual.B, 0x47);
    expectEq(actual.A, 0xFF);
}
