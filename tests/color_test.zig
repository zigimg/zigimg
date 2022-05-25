const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const color = @import("../src/color.zig");
const helpers = @import("helpers.zig");

test "Convert color to premultipled alpha" {
    const originalColor = color.Color.initRGBA(100 / 255, 128 / 255, 210 / 255, 100 / 255);
    const premultipliedAlpha = originalColor.premultipliedAlpha();

    try helpers.expectEq(premultipliedAlpha.R, 39 / 255);
    try helpers.expectEq(premultipliedAlpha.G, 50 / 255);
    try helpers.expectEq(premultipliedAlpha.B, 82 / 255);
    try helpers.expectEq(premultipliedAlpha.A, 100 / 255);
}

test "Convert Rgb24 to Color" {
    const originalColor = color.Rgb24.initRGB(100, 128, 210);
    const result = originalColor.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 100);
    try helpers.expectEq(result.G, 128);
    try helpers.expectEq(result.B, 210);
    try helpers.expectEq(result.A, 255);
}

test "Convert Rgba32 to Color" {
    const originalColor = color.Rgba32.initRGBA(1, 2, 3, 4);
    const result = originalColor.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 1);
    try helpers.expectEq(result.G, 2);
    try helpers.expectEq(result.B, 3);
    try helpers.expectEq(result.A, 4);
}

test "Convert Rgb565 to Color" {
    const originalColor = color.Rgb565.initRGB(10, 30, 20);
    const result = originalColor.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 82);
    try helpers.expectEq(result.G, 121);
    try helpers.expectEq(result.B, 165);
    try helpers.expectEq(result.A, 255);
}

test "Convert Rgb555 to Color" {
    const originalColor = color.Rgb555.initRGB(16, 20, 24);
    const result = originalColor.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 132);
    try helpers.expectEq(result.G, 165);
    try helpers.expectEq(result.B, 197);
    try helpers.expectEq(result.A, 255);
}

test "Convert Bgra32 to Color" {
    const originalColor = color.Bgra32.initRGBA(50, 100, 150, 200);
    const result = originalColor.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 50);
    try helpers.expectEq(result.G, 100);
    try helpers.expectEq(result.B, 150);
    try helpers.expectEq(result.A, 200);
}

test "Convert Grayscale1 to Color" {
    const white = color.Grayscale1{ .value = 1 };
    const whiteColor = white.toColor().toIntegerColor8();

    try helpers.expectEq(whiteColor.R, 255);
    try helpers.expectEq(whiteColor.G, 255);
    try helpers.expectEq(whiteColor.B, 255);
    try helpers.expectEq(whiteColor.A, 255);

    const black = color.Grayscale1{ .value = 0 };
    const blackColor = black.toColor().toIntegerColor8();

    try helpers.expectEq(blackColor.R, 0);
    try helpers.expectEq(blackColor.G, 0);
    try helpers.expectEq(blackColor.B, 0);
    try helpers.expectEq(blackColor.A, 255);
}

test "Convert Grayscale8 to Color" {
    const original = color.Grayscale8{ .value = 128 };
    const result = original.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 128);
    try helpers.expectEq(result.G, 128);
    try helpers.expectEq(result.B, 128);
    try helpers.expectEq(result.A, 255);
}

test "Convert Grayscale16 to Color" {
    const original = color.Grayscale16{ .value = 21845 };
    const result = original.toColor().toIntegerColor8();

    try helpers.expectEq(result.R, 85);
    try helpers.expectEq(result.G, 85);
    try helpers.expectEq(result.B, 85);
    try helpers.expectEq(result.A, 255);
}

test "From HTMl hex to IntegerColor" {
    const actual = color.IntegerColor8.fromHtmlHex(0x876347);

    try helpers.expectEq(actual.R, 0x87);
    try helpers.expectEq(actual.G, 0x63);
    try helpers.expectEq(actual.B, 0x47);
    try helpers.expectEq(actual.A, 0xFF);
}

test "toColorInt" {
    try helpers.expectEq(color.toColorInt(u8, 0), 0);
    try helpers.expectEq(color.toColorInt(u8, 0.33), 84);
    try helpers.expectEq(color.toColorInt(u8, 1), 255);
    try helpers.expectEq(color.toColorInt(u8, 1.33), 255);
    try helpers.expectEq(color.toColorInt(u8, -0.33), 0);

    try helpers.expectEq(color.toColorInt(u16, 0), 0);
    try helpers.expectEq(color.toColorInt(u16, 0.33), 21627);
    try helpers.expectEq(color.toColorInt(u16, 1), 65535);
    try helpers.expectEq(color.toColorInt(u16, 1.33), 65535);
    try helpers.expectEq(color.toColorInt(u16, -0.33), 0);
}
