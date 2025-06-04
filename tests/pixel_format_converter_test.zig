const std = @import("std");
const testing = std.testing;
const color = @import("../src/color.zig");
const Colors = @import("../src/predefined_colors.zig").Colors;
const PixelFormatConverter = @import("../src/PixelFormatConverter.zig");
const helpers = @import("helpers.zig");

// mlarouche: Not all conversion are tested, just the most important ones
// If any pixel conversion cause issues, we will add a test for it

const toU2 = color.ScaleValue(u2);
const toU3 = color.ScaleValue(u3);
const toU5 = color.ScaleValue(u5);
const toU6 = color.ScaleValue(u6);
const toU8 = color.ScaleValue(u8);
const toU16 = color.ScaleValue(u16);
const toF32 = color.ScaleValue(f32);

test "PixelFormatConverter: convert from indexed1 to indexed2" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = Colors(color.Rgba32).Red;
    indexed1_pixels.indexed1.palette[1] = Colors(color.Rgba32).Green;
    indexed1_pixels.indexed1.indices[0] = 0;
    indexed1_pixels.indexed1.indices[1] = 1;
    indexed1_pixels.indexed1.indices[2] = 1;
    indexed1_pixels.indexed1.indices[3] = 0;

    const indexed2_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed1_pixels, .indexed2);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed2_pixels.indexed2.palette[0], indexed1_pixels.indexed1.palette[0]);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[1], indexed1_pixels.indexed1.palette[1]);

    try helpers.expectEq(indexed2_pixels.indexed2.indices[0], 0);
    try helpers.expectEq(indexed2_pixels.indexed2.indices[1], 1);
    try helpers.expectEq(indexed2_pixels.indexed2.indices[2], 1);
    try helpers.expectEq(indexed2_pixels.indexed2.indices[3], 0);
}

test "PixelFormatConverter: convert from indexed1 to indexed16" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = Colors(color.Rgba32).Red;
    indexed1_pixels.indexed1.palette[1] = Colors(color.Rgba32).Green;
    indexed1_pixels.indexed1.indices[0] = 0;
    indexed1_pixels.indexed1.indices[1] = 1;
    indexed1_pixels.indexed1.indices[2] = 1;
    indexed1_pixels.indexed1.indices[3] = 0;

    const indexed16_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed1_pixels, .indexed16);
    defer indexed16_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[0], indexed1_pixels.indexed1.palette[0]);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[1], indexed1_pixels.indexed1.palette[1]);

    try helpers.expectEq(indexed16_pixels.indexed16.indices[0], 0);
    try helpers.expectEq(indexed16_pixels.indexed16.indices[1], 1);
    try helpers.expectEq(indexed16_pixels.indexed16.indices[2], 1);
    try helpers.expectEq(indexed16_pixels.indexed16.indices[3], 0);
}

test "PixelFormatConverter: convert from indexed2 to indexed1" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const indexed1_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .indexed1);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed1_pixels.indexed1.palette[0].r, 0);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[0].g, 0);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[0].b, 255);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[0].a, 255);

    try helpers.expectEq(indexed1_pixels.indexed1.palette[1].r, 0);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[1].g, 255);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[1].b, 0);
    try helpers.expectEq(indexed1_pixels.indexed1.palette[1].a, 255);

    try helpers.expectEq(indexed1_pixels.indexed1.indices[0], 0);
    try helpers.expectEq(indexed1_pixels.indexed1.indices[1], 1);
    try helpers.expectEq(indexed1_pixels.indexed1.indices[2], 0);
    try helpers.expectEq(indexed1_pixels.indexed1.indices[3], 0);
}

test "PixelFormatConverter: convert from indexed2 to rgb555" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb555);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb555_pixels.rgb555[0], Colors(color.Rgb555).Red);
    try helpers.expectEq(rgb555_pixels.rgb555[1], Colors(color.Rgb555).Green);
    try helpers.expectEq(rgb555_pixels.rgb555[2], Colors(color.Rgb555).Blue);
    try helpers.expectEq(rgb555_pixels.rgb555[3], Colors(color.Rgb555).White);
}

test "PixelFormatConverter: convert from indexed2 to rgb332" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb332_pixels.rgb332[0], Colors(color.Rgb332).Red);
    try helpers.expectEq(rgb332_pixels.rgb332[1], Colors(color.Rgb332).Green);
    try helpers.expectEq(rgb332_pixels.rgb332[2], Colors(color.Rgb332).Blue);
    try helpers.expectEq(rgb332_pixels.rgb332[3], Colors(color.Rgb332).White);
}

test "PixelFormatConverter: convert from indexed2 to rgb565" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0], Colors(color.Rgb565).Red);
    try helpers.expectEq(rgb565_pixels.rgb565[1], Colors(color.Rgb565).Green);
    try helpers.expectEq(rgb565_pixels.rgb565[2], Colors(color.Rgb565).Blue);
    try helpers.expectEq(rgb565_pixels.rgb565[3], Colors(color.Rgb565).White);
}

test "PixelFormatConverter: convert from indexed2 to rgb24" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb24);
    defer rgb24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb24_pixels.rgb24[0], Colors(color.Rgb24).Red);
    try helpers.expectEq(rgb24_pixels.rgb24[1], Colors(color.Rgb24).Green);
    try helpers.expectEq(rgb24_pixels.rgb24[2], Colors(color.Rgb24).Blue);
    try helpers.expectEq(rgb24_pixels.rgb24[3], Colors(color.Rgb24).White);
}

test "PixelFormatConverter: convert from indexed2 to rgba32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0], Colors(color.Rgba32).Red);
    try helpers.expectEq(rgba32_pixels.rgba32[1], Colors(color.Rgba32).Green);
    try helpers.expectEq(rgba32_pixels.rgba32[2], Colors(color.Rgba32).Blue);
    try helpers.expectEq(rgba32_pixels.rgba32[3], Colors(color.Rgba32).White);
}

test "PixelFormatConverter: convert from indexed2 to bgr555" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgr555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgr555);
    defer bgr555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr555_pixels.bgr555[0], Colors(color.Bgr555).Red);
    try helpers.expectEq(bgr555_pixels.bgr555[1], Colors(color.Bgr555).Green);
    try helpers.expectEq(bgr555_pixels.bgr555[2], Colors(color.Bgr555).Blue);
    try helpers.expectEq(bgr555_pixels.bgr555[3], Colors(color.Bgr555).White);
}

test "PixelFormatConverter: convert from indexed2 to bgr24" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgr24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgr24);
    defer bgr24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr24_pixels.bgr24[0], Colors(color.Bgr24).Red);
    try helpers.expectEq(bgr24_pixels.bgr24[1], Colors(color.Bgr24).Green);
    try helpers.expectEq(bgr24_pixels.bgr24[2], Colors(color.Bgr24).Blue);
    try helpers.expectEq(bgr24_pixels.bgr24[3], Colors(color.Bgr24).White);
}

test "PixelFormatConverter: convert from indexed2 to bgra32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgra32_pixels.bgra32[0], Colors(color.Bgra32).Red);
    try helpers.expectEq(bgra32_pixels.bgra32[1], Colors(color.Bgra32).Green);
    try helpers.expectEq(bgra32_pixels.bgra32[2], Colors(color.Bgra32).Blue);
    try helpers.expectEq(bgra32_pixels.bgra32[3], Colors(color.Bgra32).White);
}

test "PixelFormatConverter: convert from indexed2 to rgb48" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb48_pixelss = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb48);
    defer rgb48_pixelss.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb48_pixelss.rgb48[0], Colors(color.Rgb48).Red);
    try helpers.expectEq(rgb48_pixelss.rgb48[1], Colors(color.Rgb48).Green);
    try helpers.expectEq(rgb48_pixelss.rgb48[2], Colors(color.Rgb48).Blue);
    try helpers.expectEq(rgb48_pixelss.rgb48[3], Colors(color.Rgb48).White);
}

test "PixelFormatConverter: convert from indexed2 to rgba64" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba64_pixels.rgba64[0], Colors(color.Rgba64).Red);
    try helpers.expectEq(rgba64_pixels.rgba64[1], Colors(color.Rgba64).Green);
    try helpers.expectEq(rgba64_pixels.rgba64[2], Colors(color.Rgba64).Blue);
    try helpers.expectEq(rgba64_pixels.rgba64[3], Colors(color.Rgba64).White);
}

test "PixelFormatConverter: convert from indexed2 to Colorf32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).Red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).Green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).Blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).White;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(float32_pixels.float32[0], Colors(color.Colorf32).Red);
    try helpers.expectEq(float32_pixels.float32[1], Colors(color.Colorf32).Green);
    try helpers.expectEq(float32_pixels.float32[2], Colors(color.Colorf32).Blue);
    try helpers.expectEq(float32_pixels.float32[3], Colors(color.Colorf32).White);
}

test "PixelFormatConverter: convert from grayscale16Alpha to grayscale8" {
    const grayscale16_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16Alpha, 4);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_alpha_pixels.grayscale16Alpha[0].value = 0;
    grayscale16_alpha_pixels.grayscale16Alpha[0].alpha = 0;

    grayscale16_alpha_pixels.grayscale16Alpha[1].value = 10000;
    grayscale16_alpha_pixels.grayscale16Alpha[1].alpha = 65535;

    grayscale16_alpha_pixels.grayscale16Alpha[2].value = 20000;
    grayscale16_alpha_pixels.grayscale16Alpha[2].alpha = 13107;

    grayscale16_alpha_pixels.grayscale16Alpha[3].value = 65535;
    grayscale16_alpha_pixels.grayscale16Alpha[3].alpha = 10000;

    const grayscale8_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_alpha_pixels, .grayscale8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale8_pixels.grayscale8[0].value, 0);
    try helpers.expectEq(grayscale8_pixels.grayscale8[1].value, 39);
    try helpers.expectEq(grayscale8_pixels.grayscale8[2].value, 16);
    try helpers.expectEq(grayscale8_pixels.grayscale8[3].value, 39);
}

test "PixelFormatConverter: convert from grayscale8Alpha to grayscale16Alpha" {
    const grayscale8_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8Alpha, 4);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_alpha_pixels.grayscale8Alpha[0].value = 0;
    grayscale8_alpha_pixels.grayscale8Alpha[0].alpha = 0;

    grayscale8_alpha_pixels.grayscale8Alpha[1].value = 100;
    grayscale8_alpha_pixels.grayscale8Alpha[1].alpha = 255;

    grayscale8_alpha_pixels.grayscale8Alpha[2].value = 200;
    grayscale8_alpha_pixels.grayscale8Alpha[2].alpha = 20;

    grayscale8_alpha_pixels.grayscale8Alpha[3].value = 255;
    grayscale8_alpha_pixels.grayscale8Alpha[3].alpha = 100;

    const grayscale16_alpha_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_alpha_pixels, .grayscale16Alpha);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].value, 0);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].alpha, 0);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].value, 25700);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].value, 51400);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].alpha, 5140);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].value, 65535);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].alpha, 25700);
}

test "PixelFormatConverter: convert from grayscale2 to grayscale8" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const grayscale8_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .grayscale8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale8_pixels.grayscale8[0].value, 0);
    try helpers.expectEq(grayscale8_pixels.grayscale8[1].value, 85);
    try helpers.expectEq(grayscale8_pixels.grayscale8[2].value, 170);
    try helpers.expectEq(grayscale8_pixels.grayscale8[3].value, 255);
}

test "PixelFormatConverter: convert from grayscale2 to grayscale8Alpha" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const grayscale8_alpha_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .grayscale8Alpha);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[0].value, 0);
    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[0].alpha, 255);

    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[1].value, 85);
    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[1].alpha, 255);

    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[2].value, 170);
    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[2].alpha, 255);

    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[3].value, 255);
    try helpers.expectEq(grayscale8_alpha_pixels.grayscale8Alpha[3].alpha, 255);
}

test "PixelFormatConvertere: convert from grayscale8 to grayscale2" {
    const grayscale8_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8, 4);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_pixels.grayscale8[0].value = 0;
    grayscale8_pixels.grayscale8[1].value = 64;
    grayscale8_pixels.grayscale8[2].value = 128;
    grayscale8_pixels.grayscale8[3].value = 255;

    const grayscale2_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_pixels, .grayscale2);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale2_pixels.grayscale2[0].value, 0);
    try helpers.expectEq(grayscale2_pixels.grayscale2[1].value, 1);
    try helpers.expectEq(grayscale2_pixels.grayscale2[2].value, 2);
    try helpers.expectEq(grayscale2_pixels.grayscale2[3].value, 3);
}

test "PixelFormatConverter: convert from grayscale2 to rgb555" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgb555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgb555);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb555_pixels.rgb555[0].r, 0);
    try helpers.expectEq(rgb555_pixels.rgb555[1].r, 10);
    try helpers.expectEq(rgb555_pixels.rgb555[2].r, 21);
    try helpers.expectEq(rgb555_pixels.rgb555[3].r, 31);
}

test "PixelFormatConverter: convert from grayscale16 to rgb555" {
    const grayscale16_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16, 4);
    defer grayscale16_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_pixels.grayscale16[0].value = 0;
    grayscale16_pixels.grayscale16[1].value = @intFromFloat(@as(f32, @floatFromInt(std.math.maxInt(u16))) * 0.25);
    grayscale16_pixels.grayscale16[2].value = @intFromFloat(@as(f32, @floatFromInt(std.math.maxInt(u16))) * 0.50);
    grayscale16_pixels.grayscale16[3].value = std.math.maxInt(u16);

    const rgb555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_pixels, .rgb555);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb555_pixels.rgb555[0].r, 0);
    try helpers.expectEq(rgb555_pixels.rgb555[1].r, 7);
    try helpers.expectEq(rgb555_pixels.rgb555[2].r, 15);
    try helpers.expectEq(rgb555_pixels.rgb555[3].r, 31);
}

test "PixelFormatConverter: convert from grayscale2 to rgb332" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb332_pixels.rgb332[0].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[1].r, 2);
    try helpers.expectEq(rgb332_pixels.rgb332[1].g, 2);
    try helpers.expectEq(rgb332_pixels.rgb332[1].b, 1);

    try helpers.expectEq(rgb332_pixels.rgb332[2].r, 5);
    try helpers.expectEq(rgb332_pixels.rgb332[2].g, 5);
    try helpers.expectEq(rgb332_pixels.rgb332[2].b, 2);

    try helpers.expectEq(rgb332_pixels.rgb332[3].r, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[3].g, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[3].b, 3);
}

test "PixelFormatConverter: convert from grayscale8Alpha to rgb332" {
    const grayscale8_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8Alpha, 4);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_alpha_pixels.grayscale8Alpha[0].value = 0;
    grayscale8_alpha_pixels.grayscale8Alpha[0].alpha = 0;

    grayscale8_alpha_pixels.grayscale8Alpha[1].value = 100;
    grayscale8_alpha_pixels.grayscale8Alpha[1].alpha = 255;

    grayscale8_alpha_pixels.grayscale8Alpha[2].value = 200;
    grayscale8_alpha_pixels.grayscale8Alpha[2].alpha = 75;

    grayscale8_alpha_pixels.grayscale8Alpha[3].value = 255;
    grayscale8_alpha_pixels.grayscale8Alpha[3].alpha = 100;

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_alpha_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb332_pixels.rgb332[0].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[1].r, 3);
    try helpers.expectEq(rgb332_pixels.rgb332[1].g, 3);
    try helpers.expectEq(rgb332_pixels.rgb332[1].b, 1);

    try helpers.expectEq(rgb332_pixels.rgb332[2].r, 2);
    try helpers.expectEq(rgb332_pixels.rgb332[2].g, 2);
    try helpers.expectEq(rgb332_pixels.rgb332[2].b, 1);

    try helpers.expectEq(rgb332_pixels.rgb332[3].r, 3);
    try helpers.expectEq(rgb332_pixels.rgb332[3].g, 3);
    try helpers.expectEq(rgb332_pixels.rgb332[3].b, 1);
}

test "PixelFormatConverter: convert from grayscale16Alpha to rgb332" {
    const grayscale16_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16Alpha, 4);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_alpha_pixels.grayscale16Alpha[0].value = 0;
    grayscale16_alpha_pixels.grayscale16Alpha[0].alpha = 0;

    grayscale16_alpha_pixels.grayscale16Alpha[1].value = 10000;
    grayscale16_alpha_pixels.grayscale16Alpha[1].alpha = 65535;

    grayscale16_alpha_pixels.grayscale16Alpha[2].value = 20000;
    grayscale16_alpha_pixels.grayscale16Alpha[2].alpha = 43107;

    grayscale16_alpha_pixels.grayscale16Alpha[3].value = 65535;
    grayscale16_alpha_pixels.grayscale16Alpha[3].alpha = 10000;

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_alpha_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb332_pixels.rgb332[0].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[1].r, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[1].g, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[1].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[2].r, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[2].g, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[2].b, 1);

    try helpers.expectEq(rgb332_pixels.rgb332[3].r, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[3].g, 1);
    try helpers.expectEq(rgb332_pixels.rgb332[3].b, 0);
}

test "PixelFormatConverter: convert from grayscale2 to rgb565" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].b, 0);

    try helpers.expectEq(rgb565_pixels.rgb565[1].r, 10);
    try helpers.expectEq(rgb565_pixels.rgb565[1].g, 21);
    try helpers.expectEq(rgb565_pixels.rgb565[1].b, 10);

    try helpers.expectEq(rgb565_pixels.rgb565[2].r, 21);
    try helpers.expectEq(rgb565_pixels.rgb565[2].g, 42);
    try helpers.expectEq(rgb565_pixels.rgb565[2].b, 21);

    try helpers.expectEq(rgb565_pixels.rgb565[3].r, 31);
    try helpers.expectEq(rgb565_pixels.rgb565[3].g, 63);
    try helpers.expectEq(rgb565_pixels.rgb565[3].b, 31);
}

test "PixelFormatConverter: convert from grayscale8Alpha to rgb565" {
    const grayscale8_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8Alpha, 4);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_alpha_pixels.grayscale8Alpha[0].value = 0;
    grayscale8_alpha_pixels.grayscale8Alpha[0].alpha = 0;

    grayscale8_alpha_pixels.grayscale8Alpha[1].value = 100;
    grayscale8_alpha_pixels.grayscale8Alpha[1].alpha = 255;

    grayscale8_alpha_pixels.grayscale8Alpha[2].value = 200;
    grayscale8_alpha_pixels.grayscale8Alpha[2].alpha = 20;

    grayscale8_alpha_pixels.grayscale8Alpha[3].value = 255;
    grayscale8_alpha_pixels.grayscale8Alpha[3].alpha = 100;

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_alpha_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].b, 0);

    try helpers.expectEq(rgb565_pixels.rgb565[1].r, 12);
    try helpers.expectEq(rgb565_pixels.rgb565[1].g, 25);
    try helpers.expectEq(rgb565_pixels.rgb565[1].b, 12);

    try helpers.expectEq(rgb565_pixels.rgb565[2].r, 2);
    try helpers.expectEq(rgb565_pixels.rgb565[2].g, 4);
    try helpers.expectEq(rgb565_pixels.rgb565[2].b, 2);

    try helpers.expectEq(rgb565_pixels.rgb565[3].r, 12);
    try helpers.expectEq(rgb565_pixels.rgb565[3].g, 25);
    try helpers.expectEq(rgb565_pixels.rgb565[3].b, 12);
}

test "PixelFormatConverter: convert from grayscale16Alpha to rgb565" {
    const grayscale16_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16Alpha, 4);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_alpha_pixels.grayscale16Alpha[0].value = 0;
    grayscale16_alpha_pixels.grayscale16Alpha[0].alpha = 0;

    grayscale16_alpha_pixels.grayscale16Alpha[1].value = 10000;
    grayscale16_alpha_pixels.grayscale16Alpha[1].alpha = 65535;

    grayscale16_alpha_pixels.grayscale16Alpha[2].value = 20000;
    grayscale16_alpha_pixels.grayscale16Alpha[2].alpha = 13107;

    grayscale16_alpha_pixels.grayscale16Alpha[3].value = 65535;
    grayscale16_alpha_pixels.grayscale16Alpha[3].alpha = 10000;

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_alpha_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].b, 0);

    try helpers.expectEq(rgb565_pixels.rgb565[1].r, 5);
    try helpers.expectEq(rgb565_pixels.rgb565[1].g, 10);
    try helpers.expectEq(rgb565_pixels.rgb565[1].b, 5);

    try helpers.expectEq(rgb565_pixels.rgb565[2].r, 2);
    try helpers.expectEq(rgb565_pixels.rgb565[2].g, 4);
    try helpers.expectEq(rgb565_pixels.rgb565[2].b, 2);

    try helpers.expectEq(rgb565_pixels.rgb565[3].r, 5);
    try helpers.expectEq(rgb565_pixels.rgb565[3].g, 10);
    try helpers.expectEq(rgb565_pixels.rgb565[3].b, 5);
}

test "PixelFormatConverter: convert from grayscale2 to rgb24" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgb24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgb24);
    defer rgb24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb24_pixels.rgb24[0].r, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[1].r, 85);
    try helpers.expectEq(rgb24_pixels.rgb24[2].r, 170);
    try helpers.expectEq(rgb24_pixels.rgb24[3].r, 255);
}

test "PixelFormatConverter: convert from grayscale2 to rgba32" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0].r, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[1].r, 85);
    try helpers.expectEq(rgba32_pixels.rgba32[2].r, 170);
    try helpers.expectEq(rgba32_pixels.rgba32[3].r, 255);
}

test "PixelFormatConverter: convert from grayscale8Alpha to rgba32" {
    const grayscale8_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8Alpha, 4);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_alpha_pixels.grayscale8Alpha[0].value = 0;
    grayscale8_alpha_pixels.grayscale8Alpha[0].alpha = 0;

    grayscale8_alpha_pixels.grayscale8Alpha[1].value = 100;
    grayscale8_alpha_pixels.grayscale8Alpha[1].alpha = 255;

    grayscale8_alpha_pixels.grayscale8Alpha[2].value = 200;
    grayscale8_alpha_pixels.grayscale8Alpha[2].alpha = 20;

    grayscale8_alpha_pixels.grayscale8Alpha[3].value = 255;
    grayscale8_alpha_pixels.grayscale8Alpha[3].alpha = 100;

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_alpha_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0].r, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[0].g, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[0].b, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[0].a, 0);

    try helpers.expectEq(rgba32_pixels.rgba32[1].r, 100);
    try helpers.expectEq(rgba32_pixels.rgba32[1].g, 100);
    try helpers.expectEq(rgba32_pixels.rgba32[1].b, 100);
    try helpers.expectEq(rgba32_pixels.rgba32[1].a, 255);

    try helpers.expectEq(rgba32_pixels.rgba32[2].r, 200);
    try helpers.expectEq(rgba32_pixels.rgba32[2].g, 200);
    try helpers.expectEq(rgba32_pixels.rgba32[2].b, 200);
    try helpers.expectEq(rgba32_pixels.rgba32[2].a, 20);

    try helpers.expectEq(rgba32_pixels.rgba32[3].r, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].g, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].b, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].a, 100);
}

test "PixelFormatConverter: convert from grayscale2 to bgr555" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const bgr555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .bgr555);
    defer bgr555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr555_pixels.bgr555[0].r, 0);
    try helpers.expectEq(bgr555_pixels.bgr555[1].r, 10);
    try helpers.expectEq(bgr555_pixels.bgr555[2].r, 21);
    try helpers.expectEq(bgr555_pixels.bgr555[3].r, 31);
}

test "PixelFormatConverter: convert from grayscale2 to bgr24" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const bgr24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .bgr24);
    defer bgr24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr24_pixels.bgr24[0].r, 0);
    try helpers.expectEq(bgr24_pixels.bgr24[1].r, 85);
    try helpers.expectEq(bgr24_pixels.bgr24[2].r, 170);
    try helpers.expectEq(bgr24_pixels.bgr24[3].r, 255);
}

test "PixelFormatConverter: convert from grayscale2 to bgra32" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgra32_pixels.bgra32[0].r, 0);
    try helpers.expectEq(bgra32_pixels.bgra32[1].r, 85);
    try helpers.expectEq(bgra32_pixels.bgra32[2].r, 170);
    try helpers.expectEq(bgra32_pixels.bgra32[3].r, 255);
}

test "PixelFormatConverter: convert from grayscale8Alpha to bgra32" {
    const grayscale8_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8Alpha, 4);
    defer grayscale8_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale8_alpha_pixels.grayscale8Alpha[0].value = 0;
    grayscale8_alpha_pixels.grayscale8Alpha[0].alpha = 0;

    grayscale8_alpha_pixels.grayscale8Alpha[1].value = 100;
    grayscale8_alpha_pixels.grayscale8Alpha[1].alpha = 255;

    grayscale8_alpha_pixels.grayscale8Alpha[2].value = 200;
    grayscale8_alpha_pixels.grayscale8Alpha[2].alpha = 20;

    grayscale8_alpha_pixels.grayscale8Alpha[3].value = 255;
    grayscale8_alpha_pixels.grayscale8Alpha[3].alpha = 100;

    const bgra32_pixelss = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_alpha_pixels, .bgra32);
    defer bgra32_pixelss.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgra32_pixelss.bgra32[0].r, 0);
    try helpers.expectEq(bgra32_pixelss.bgra32[0].g, 0);
    try helpers.expectEq(bgra32_pixelss.bgra32[0].b, 0);
    try helpers.expectEq(bgra32_pixelss.bgra32[0].a, 0);

    try helpers.expectEq(bgra32_pixelss.bgra32[1].r, 100);
    try helpers.expectEq(bgra32_pixelss.bgra32[1].g, 100);
    try helpers.expectEq(bgra32_pixelss.bgra32[1].b, 100);
    try helpers.expectEq(bgra32_pixelss.bgra32[1].a, 255);

    try helpers.expectEq(bgra32_pixelss.bgra32[2].r, 200);
    try helpers.expectEq(bgra32_pixelss.bgra32[2].g, 200);
    try helpers.expectEq(bgra32_pixelss.bgra32[2].b, 200);
    try helpers.expectEq(bgra32_pixelss.bgra32[2].a, 20);

    try helpers.expectEq(bgra32_pixelss.bgra32[3].r, 255);
    try helpers.expectEq(bgra32_pixelss.bgra32[3].g, 255);
    try helpers.expectEq(bgra32_pixelss.bgra32[3].b, 255);
    try helpers.expectEq(bgra32_pixelss.bgra32[3].a, 100);
}

test "PixelFormatConverter: convert from grayscale2 to rgb48" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgb48_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgb48);
    defer rgb48_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb48_pixels.rgb48[0].r, 0);
    try helpers.expectEq(rgb48_pixels.rgb48[1].r, 21845);
    try helpers.expectEq(rgb48_pixels.rgb48[2].r, 43690);
    try helpers.expectEq(rgb48_pixels.rgb48[3].r, 65535);
}

test "PixelFormatConverter: convert from grayscale2 to rgba64" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba64_pixels.rgba64[0].r, 0);
    try helpers.expectEq(rgba64_pixels.rgba64[1].r, 21845);
    try helpers.expectEq(rgba64_pixels.rgba64[2].r, 43690);
    try helpers.expectEq(rgba64_pixels.rgba64[3].r, 65535);
}

test "PixelFormatConverter: convert from grayscale16Alpha to rgba64" {
    const grayscale16_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16Alpha, 4);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_alpha_pixels.grayscale16Alpha[0].value = 0;
    grayscale16_alpha_pixels.grayscale16Alpha[0].alpha = 0;

    grayscale16_alpha_pixels.grayscale16Alpha[1].value = 10000;
    grayscale16_alpha_pixels.grayscale16Alpha[1].alpha = 65535;

    grayscale16_alpha_pixels.grayscale16Alpha[2].value = 20000;
    grayscale16_alpha_pixels.grayscale16Alpha[2].alpha = 13107;

    grayscale16_alpha_pixels.grayscale16Alpha[3].value = 65535;
    grayscale16_alpha_pixels.grayscale16Alpha[3].alpha = 10000;

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_alpha_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba64_pixels.rgba64[0].r, 0);
    try helpers.expectEq(rgba64_pixels.rgba64[0].g, 0);
    try helpers.expectEq(rgba64_pixels.rgba64[0].b, 0);
    try helpers.expectEq(rgba64_pixels.rgba64[0].a, 0);

    try helpers.expectEq(rgba64_pixels.rgba64[1].r, 10000);
    try helpers.expectEq(rgba64_pixels.rgba64[1].g, 10000);
    try helpers.expectEq(rgba64_pixels.rgba64[1].b, 10000);
    try helpers.expectEq(rgba64_pixels.rgba64[1].a, 65535);

    try helpers.expectEq(rgba64_pixels.rgba64[2].r, 20000);
    try helpers.expectEq(rgba64_pixels.rgba64[2].g, 20000);
    try helpers.expectEq(rgba64_pixels.rgba64[2].b, 20000);
    try helpers.expectEq(rgba64_pixels.rgba64[2].a, 13107);

    try helpers.expectEq(rgba64_pixels.rgba64[3].r, 65535);
    try helpers.expectEq(rgba64_pixels.rgba64[3].g, 65535);
    try helpers.expectEq(rgba64_pixels.rgba64[3].b, 65535);
    try helpers.expectEq(rgba64_pixels.rgba64[3].a, 10000);
}

test "PixelFormatConverter: convert from grayscale2 to float32" {
    const grayscale2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale2, 4);
    defer grayscale2_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale2_pixels.grayscale2[0].value = 0;
    grayscale2_pixels.grayscale2[1].value = 1;
    grayscale2_pixels.grayscale2[2].value = 2;
    grayscale2_pixels.grayscale2[3].value = 3;

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale2_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;

    try helpers.expectApproxEqAbs(float32_pixels.float32[0].r, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].r, 0.3333, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].r, 0.6666, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].r, 1.0, float_tolerance);
}

test "PixelFormatConverter: convert from grayscale16Alpha to float32" {
    const grayscale16_alpha_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale16Alpha, 4);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    grayscale16_alpha_pixels.grayscale16Alpha[0].value = 0;
    grayscale16_alpha_pixels.grayscale16Alpha[0].alpha = 0;

    grayscale16_alpha_pixels.grayscale16Alpha[1].value = 10000;
    grayscale16_alpha_pixels.grayscale16Alpha[1].alpha = 65535;

    grayscale16_alpha_pixels.grayscale16Alpha[2].value = 20000;
    grayscale16_alpha_pixels.grayscale16Alpha[2].alpha = 13107;

    grayscale16_alpha_pixels.grayscale16Alpha[3].value = 65535;
    grayscale16_alpha_pixels.grayscale16Alpha[3].alpha = 10000;

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale16_alpha_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;

    try helpers.expectApproxEqAbs(float32_pixels.float32[0].r, 0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].g, 0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].b, 0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].a, 0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[1].r, 0.15259, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].g, 0.15259, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].b, 0.15259, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].a, 1.0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[2].r, 0.30518, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].g, 0.30518, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].b, 0.30518, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].a, 0.2, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[3].r, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].g, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].b, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].a, 0.15259, float_tolerance);
}

test "PixelFormatConverter: convvert from rgb555 to rgb332" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.from.rgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.from.rgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.from.rgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.from.rgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.from.rgb(0, 0, 0);

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb555_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb332_pixels.rgb332[0].r, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[0].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[0].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[1].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[1].g, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[1].b, 0);

    try helpers.expectEq(rgb332_pixels.rgb332[2].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[2].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[2].b, 3);

    try helpers.expectEq(rgb332_pixels.rgb332[3].r, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[3].g, 7);
    try helpers.expectEq(rgb332_pixels.rgb332[3].b, 3);

    try helpers.expectEq(rgb332_pixels.rgb332[4].r, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[4].g, 0);
    try helpers.expectEq(rgb332_pixels.rgb332[4].b, 0);
}

test "PixelFormatConverter: convvert from rgb555 to rgb565" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.from.rgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.from.rgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.from.rgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.from.rgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.from.rgb(0, 0, 0);

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb555_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0].r, 31);
    try helpers.expectEq(rgb565_pixels.rgb565[0].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[0].b, 0);

    try helpers.expectEq(rgb565_pixels.rgb565[1].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[1].g, 63);
    try helpers.expectEq(rgb565_pixels.rgb565[1].b, 0);

    try helpers.expectEq(rgb565_pixels.rgb565[2].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[2].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[2].b, 31);

    try helpers.expectEq(rgb565_pixels.rgb565[3].r, 31);
    try helpers.expectEq(rgb565_pixels.rgb565[3].g, 63);
    try helpers.expectEq(rgb565_pixels.rgb565[3].b, 31);

    try helpers.expectEq(rgb565_pixels.rgb565[4].r, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[4].g, 0);
    try helpers.expectEq(rgb565_pixels.rgb565[4].b, 0);
}

test "PixelFormatConverter: convert from rgb555 to rgb24" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.from.rgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.from.rgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.from.rgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.from.rgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.from.rgb(0, 0, 0);

    const rgb24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb555_pixels, .rgb24);
    defer rgb24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb24_pixels.rgb24[0].r, 255);
    try helpers.expectEq(rgb24_pixels.rgb24[0].g, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[0].b, 0);

    try helpers.expectEq(rgb24_pixels.rgb24[1].r, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[1].g, 255);
    try helpers.expectEq(rgb24_pixels.rgb24[1].b, 0);

    try helpers.expectEq(rgb24_pixels.rgb24[2].r, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[2].g, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[2].b, 255);

    try helpers.expectEq(rgb24_pixels.rgb24[3].r, 255);
    try helpers.expectEq(rgb24_pixels.rgb24[3].g, 255);
    try helpers.expectEq(rgb24_pixels.rgb24[3].b, 255);

    try helpers.expectEq(rgb24_pixels.rgb24[4].r, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[4].g, 0);
    try helpers.expectEq(rgb24_pixels.rgb24[4].b, 0);
}

test "PixelFormatConverter: convert from rgb555 to rgba32" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.from.rgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.from.rgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.from.rgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.from.rgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.from.rgb(0, 0, 0);

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb555_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0].r, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[0].g, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[0].b, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[0].a, 255);

    try helpers.expectEq(rgba32_pixels.rgba32[1].r, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[1].g, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[1].b, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[1].a, 255);

    try helpers.expectEq(rgba32_pixels.rgba32[2].r, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[2].g, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[2].b, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[2].a, 255);

    try helpers.expectEq(rgba32_pixels.rgba32[3].r, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].g, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].b, 255);
    try helpers.expectEq(rgba32_pixels.rgba32[3].a, 255);

    try helpers.expectEq(rgba32_pixels.rgba32[4].r, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[4].g, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[4].b, 0);
    try helpers.expectEq(rgba32_pixels.rgba32[4].a, 255);
}

test "PixelFormatConverter: convert from rgb555 to float32" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.from.rgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.from.rgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.from.rgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.from.rgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.from.rgb(0, 0, 0);

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb555_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;

    try helpers.expectApproxEqAbs(float32_pixels.float32[0].r, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].g, 0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].b, 0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[0].a, 1.0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[1].r, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].g, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].b, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[1].a, 1.0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[2].r, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].g, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].b, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[2].a, 1.0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[3].r, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].g, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].b, 1.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[3].a, 1.0, float_tolerance);

    try helpers.expectApproxEqAbs(float32_pixels.float32[4].r, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[4].g, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[4].b, 0.0, float_tolerance);
    try helpers.expectApproxEqAbs(float32_pixels.float32[4].a, 1.0, float_tolerance);
}

test "PixelFormatConverter: convert rgba32 to bgra32" {
    const rgba32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgba32, 256 * 7);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: u8 = @truncate(index % 256);

        switch (row) {
            0 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, 0, 0),
            1 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, column, 0),
            2 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, 0, column),
            3 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, column, 0),
            4 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, 0, column),
            5 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, column, column),
            6 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, column, column),
            else => {},
        }
    }

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba32_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        try helpers.expectEq(bgra32_pixels.bgra32[index].r, rgba32_pixels.rgba32[index].r);
        try helpers.expectEq(bgra32_pixels.bgra32[index].g, rgba32_pixels.rgba32[index].g);
        try helpers.expectEq(bgra32_pixels.bgra32[index].b, rgba32_pixels.rgba32[index].b);
        try helpers.expectEq(bgra32_pixels.bgra32[index].a, rgba32_pixels.rgba32[index].a);
    }
}

test "PixelFormatConverter: convert bgra32 to rgba32" {
    const bgra32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .bgra32, 256 * 7);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..bgra32_pixels.bgra32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: u8 = @truncate(index % 256);

        switch (row) {
            0 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, 0, 0),
            1 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, column, 0),
            2 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, 0, column),
            3 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, column, 0),
            4 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, 0, column),
            5 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, column, column),
            6 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, column, column),
            else => {},
        }
    }

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &bgra32_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        try helpers.expectEq(rgba32_pixels.rgba32[index].r, bgra32_pixels.bgra32[index].r);
        try helpers.expectEq(rgba32_pixels.rgba32[index].g, bgra32_pixels.bgra32[index].g);
        try helpers.expectEq(rgba32_pixels.rgba32[index].b, bgra32_pixels.bgra32[index].b);
        try helpers.expectEq(rgba32_pixels.rgba32[index].a, bgra32_pixels.bgra32[index].a);
    }
}

test "PixelFormatConverter: convert rgba32 to float32" {
    const rgba32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgba32, 256 * 7);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: u8 = @truncate(index % 256);

        switch (row) {
            0 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, 0, 0),
            1 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, column, 0),
            2 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, 0, column),
            3 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, column, 0),
            4 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, 0, column),
            5 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(0, column, column),
            6 => rgba32_pixels.rgba32[index] = color.Rgba32.from.rgb(column, column, column),
            else => {},
        }
    }

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba32_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;
    for (0..float32_pixels.float32.len) |index| {
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].r, toF32(rgba32_pixels.rgba32[index].r), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].g, toF32(rgba32_pixels.rgba32[index].g), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].b, toF32(rgba32_pixels.rgba32[index].b), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].a, toF32(rgba32_pixels.rgba32[index].a), float_tolerance);
    }
}

test "PixelFormatConverter: convert bgra32 to float32" {
    const bgra32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .bgra32, 256 * 7);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..bgra32_pixels.bgra32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: u8 = @truncate(index % 256);

        switch (row) {
            0 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, 0, 0),
            1 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, column, 0),
            2 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, 0, column),
            3 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, column, 0),
            4 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, 0, column),
            5 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(0, column, column),
            6 => bgra32_pixels.bgra32[index] = color.Bgra32.from.rgb(column, column, column),
            else => {},
        }
    }

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &bgra32_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;
    for (0..float32_pixels.float32.len) |index| {
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].r, toF32(bgra32_pixels.bgra32[index].r), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].g, toF32(bgra32_pixels.bgra32[index].g), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].b, toF32(bgra32_pixels.bgra32[index].b), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].a, toF32(bgra32_pixels.bgra32[index].a), float_tolerance);
    }
}

test "PixelFormatConverter: convert float32 to rgba32" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = toF32(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, column),
            else => {},
        }
    }

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        try helpers.expectEq(rgba32_pixels.rgba32[index].r, toU8(float32_pixels.float32[index].r));
        try helpers.expectEq(rgba32_pixels.rgba32[index].g, toU8(float32_pixels.float32[index].g));
        try helpers.expectEq(rgba32_pixels.rgba32[index].b, toU8(float32_pixels.float32[index].b));
        try helpers.expectEq(rgba32_pixels.rgba32[index].a, toU8(float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to bgra32" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = toF32(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, column),
            else => {},
        }
    }

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..bgra32_pixels.bgra32.len) |index| {
        try helpers.expectEq(bgra32_pixels.bgra32[index].r, toU8(float32_pixels.float32[index].r));
        try helpers.expectEq(bgra32_pixels.bgra32[index].g, toU8(float32_pixels.float32[index].g));
        try helpers.expectEq(bgra32_pixels.bgra32[index].b, toU8(float32_pixels.float32[index].b));
        try helpers.expectEq(bgra32_pixels.bgra32[index].a, toU8(float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to rgba64" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = toF32(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, column),
            else => {},
        }
    }

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba64_pixels.rgba64.len) |index| {
        try helpers.expectEq(rgba64_pixels.rgba64[index].r, toU16(float32_pixels.float32[index].r));
        try helpers.expectEq(rgba64_pixels.rgba64[index].g, toU16(float32_pixels.float32[index].g));
        try helpers.expectEq(rgba64_pixels.rgba64[index].b, toU16(float32_pixels.float32[index].b));
        try helpers.expectEq(rgba64_pixels.rgba64[index].a, toU16(float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to rgb332" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = toF32(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, column),
            else => {},
        }
    }

    const rgb332_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgb332);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgb332_pixels.rgb332.len) |index| {
        try helpers.expectEq(rgb332_pixels.rgb332[index].r, toU3(float32_pixels.float32[index].r));
        try helpers.expectEq(rgb332_pixels.rgb332[index].g, toU3(float32_pixels.float32[index].g));
        try helpers.expectEq(rgb332_pixels.rgb332[index].b, toU2(float32_pixels.float32[index].b));
    }
}

test "PixelFormatConverter: convert float32 to rgb565" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = toF32(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.from.rgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.from.rgb(column, column, column),
            else => {},
        }
    }

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgb565_pixels.rgb565.len) |index| {
        try helpers.expectEq(rgb565_pixels.rgb565[index].r, toU5(float32_pixels.float32[index].r));
        try helpers.expectEq(rgb565_pixels.rgb565[index].g, toU6(float32_pixels.float32[index].g));
        try helpers.expectEq(rgb565_pixels.rgb565[index].b, toU5(float32_pixels.float32[index].b));
    }
}

test "PixelFormatConverter: convert float32 to grayscale16Alpha" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 9);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    float32_pixels.float32[0] = color.Colorf32.from.rgb(1.0, 0.0, 0.0);
    float32_pixels.float32[1] = color.Colorf32.from.rgb(0.0, 1.0, 0.0);
    float32_pixels.float32[2] = color.Colorf32.from.rgb(0.0, 0.0, 1.0);

    float32_pixels.float32[3] = color.Colorf32.from.rgb(1.0, 0.0, 1.0);
    float32_pixels.float32[4] = color.Colorf32.from.rgb(1.0, 1.0, 0.0);
    float32_pixels.float32[5] = color.Colorf32.from.rgb(0.0, 1.0, 1.0);

    float32_pixels.float32[6] = color.Colorf32.from.rgb(1.0, 1.0, 1.0);
    float32_pixels.float32[7] = color.Colorf32.from.rgb(0.0, 0.0, 0.0);

    float32_pixels.float32[8] = color.Colorf32.from.rgba(0.2, 0.1, 0.8, 0.4);

    const grayscale16_alpha_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .grayscale16Alpha);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].value, 13926);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].value, 46884);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].value, 4725);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].value, 18651);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[4].value, 60810);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[4].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[5].value, 51609);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[5].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[6].value, 65535);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[6].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[7].value, 0);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[7].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[8].value, 11254);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[8].alpha, 26214);
}

test "PixelFormatConverter: convert float32 to grayscale8" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 9);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    float32_pixels.float32[0] = color.Colorf32.from.rgb(1.0, 0.0, 0.0);
    float32_pixels.float32[1] = color.Colorf32.from.rgb(0.0, 1.0, 0.0);
    float32_pixels.float32[2] = color.Colorf32.from.rgb(0.0, 0.0, 1.0);

    float32_pixels.float32[3] = color.Colorf32.from.rgb(1.0, 0.0, 1.0);
    float32_pixels.float32[4] = color.Colorf32.from.rgb(1.0, 1.0, 0.0);
    float32_pixels.float32[5] = color.Colorf32.from.rgb(0.0, 1.0, 1.0);

    float32_pixels.float32[6] = color.Colorf32.from.rgb(1.0, 1.0, 1.0);
    float32_pixels.float32[7] = color.Colorf32.from.rgb(0.0, 0.0, 0.0);

    float32_pixels.float32[8] = color.Colorf32.from.rgba(0.2, 0.1, 0.8, 0.4);

    const grayscale8_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .grayscale8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale8_pixels.grayscale8[0].value, 54);

    try helpers.expectEq(grayscale8_pixels.grayscale8[1].value, 182);

    try helpers.expectEq(grayscale8_pixels.grayscale8[2].value, 18);

    try helpers.expectEq(grayscale8_pixels.grayscale8[3].value, 73);

    try helpers.expectEq(grayscale8_pixels.grayscale8[4].value, 237);

    try helpers.expectEq(grayscale8_pixels.grayscale8[5].value, 201);

    try helpers.expectEq(grayscale8_pixels.grayscale8[6].value, 255);

    try helpers.expectEq(grayscale8_pixels.grayscale8[7].value, 0);

    try helpers.expectEq(grayscale8_pixels.grayscale8[8].value, 18);
}

test "PixelFormatConverter: convert rgba64 to grayscale16Alpha" {
    const rgba64_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgba64, 9);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    rgba64_pixels.rgba64[0] = color.Rgba64.from.rgb(65535, 0, 0);
    rgba64_pixels.rgba64[1] = color.Rgba64.from.rgb(0, 65535, 0);
    rgba64_pixels.rgba64[2] = color.Rgba64.from.rgb(0, 0, 65535);

    rgba64_pixels.rgba64[3] = color.Rgba64.from.rgb(65535, 0, 65535);
    rgba64_pixels.rgba64[4] = color.Rgba64.from.rgb(65535, 65535, 0);
    rgba64_pixels.rgba64[5] = color.Rgba64.from.rgb(0, 65535, 65535);

    rgba64_pixels.rgba64[6] = color.Rgba64.from.rgb(65535, 65535, 65535);
    rgba64_pixels.rgba64[7] = color.Rgba64.from.rgb(0, 0, 0);

    rgba64_pixels.rgba64[8] = color.Rgba64.from.rgba(13107, 6553, 52428, 26214);

    const grayscale16_alpha_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba64_pixels, .grayscale16Alpha);
    defer grayscale16_alpha_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].value, 13926);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[0].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].value, 46884);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[1].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].value, 4725);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[2].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].value, 18651);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[3].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[4].value, 60810);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[4].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[5].value, 51609);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[5].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[6].value, 65535);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[6].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[7].value, 0);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[7].alpha, 65535);

    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[8].value, 11253);
    try helpers.expectEq(grayscale16_alpha_pixels.grayscale16Alpha[8].alpha, 26214);
}

test "PixelFormatConverter: convert rgba32 to grayscale8" {
    const rgba32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgba32, 9);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    rgba32_pixels.rgba32[0] = color.Rgba32.from.rgb(255, 0, 0);
    rgba32_pixels.rgba32[1] = color.Rgba32.from.rgb(0, 255, 0);
    rgba32_pixels.rgba32[2] = color.Rgba32.from.rgb(0, 0, 255);

    rgba32_pixels.rgba32[3] = color.Rgba32.from.rgb(255, 0, 255);
    rgba32_pixels.rgba32[4] = color.Rgba32.from.rgb(255, 255, 0);
    rgba32_pixels.rgba32[5] = color.Rgba32.from.rgb(0, 255, 255);

    rgba32_pixels.rgba32[6] = color.Rgba32.from.rgb(255, 255, 255);
    rgba32_pixels.rgba32[7] = color.Rgba32.from.rgb(0, 0, 0);

    rgba32_pixels.rgba32[8] = color.Rgba32.from.rgba(51, 25, 204, 102);

    const grayscale8_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba32_pixels, .grayscale8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(grayscale8_pixels.grayscale8[0].value, 54);

    try helpers.expectEq(grayscale8_pixels.grayscale8[1].value, 182);

    try helpers.expectEq(grayscale8_pixels.grayscale8[2].value, 18);

    try helpers.expectEq(grayscale8_pixels.grayscale8[3].value, 73);

    try helpers.expectEq(grayscale8_pixels.grayscale8[4].value, 237);

    try helpers.expectEq(grayscale8_pixels.grayscale8[5].value, 201);

    try helpers.expectEq(grayscale8_pixels.grayscale8[6].value, 255);

    try helpers.expectEq(grayscale8_pixels.grayscale8[7].value, 0);

    try helpers.expectEq(grayscale8_pixels.grayscale8[8].value, 17);
}

test "PixelFormatConverter: convert float32 to indexed16" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 32 * 8);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => float32_pixels.float32[index] = Colors(color.Colorf32).Red,
            1 => float32_pixels.float32[index] = Colors(color.Colorf32).Green,
            2 => float32_pixels.float32[index] = Colors(color.Colorf32).Blue,
            3 => float32_pixels.float32[index] = Colors(color.Colorf32).Yellow,
            4 => float32_pixels.float32[index] = Colors(color.Colorf32).Magenta,
            5 => float32_pixels.float32[index] = Colors(color.Colorf32).Cyan,
            6 => float32_pixels.float32[index] = Colors(color.Colorf32).White,
            7 => float32_pixels.float32[index] = Colors(color.Colorf32).Black,
            else => {},
        }
    }

    const indexed16_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .indexed16);
    defer indexed16_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[0].r, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[0].g, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[0].b, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[0].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[1].r, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[1].g, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[1].b, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[1].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[2].r, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[2].g, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[2].b, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[2].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[3].r, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[3].g, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[3].b, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[3].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[4].r, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[4].g, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[4].b, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[4].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[5].r, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[5].g, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[5].b, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[5].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[6].r, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[6].g, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[6].b, 0);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[6].a, 255);

    try helpers.expectEq(indexed16_pixels.indexed16.palette[7].r, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[7].g, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[7].b, 255);
    try helpers.expectEq(indexed16_pixels.indexed16.palette[7].a, 255);

    for (0..indexed16_pixels.indexed16.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 4),
            1 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 2),
            2 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 1),
            3 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 6),
            4 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 5),
            5 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 3),
            6 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 7),
            7 => try helpers.expectEq(indexed16_pixels.indexed16.indices[index], 0),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert float32 to indexed4" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 32 * 8);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => float32_pixels.float32[index] = Colors(color.Colorf32).Red,
            1 => float32_pixels.float32[index] = Colors(color.Colorf32).Green,
            2 => float32_pixels.float32[index] = Colors(color.Colorf32).Blue,
            3 => float32_pixels.float32[index] = Colors(color.Colorf32).Yellow,
            4 => float32_pixels.float32[index] = Colors(color.Colorf32).Magenta,
            5 => float32_pixels.float32[index] = Colors(color.Colorf32).Cyan,
            6 => float32_pixels.float32[index] = Colors(color.Colorf32).White,
            7 => float32_pixels.float32[index] = Colors(color.Colorf32).Black,
            else => {},
        }
    }

    const indexed4_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .indexed4);
    defer indexed4_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].a, 255);

    for (0..indexed4_pixels.indexed4.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 4),
            1 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 2),
            2 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 1),
            3 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 6),
            4 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 5),
            5 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 3),
            6 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 7),
            7 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 0),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert rgba32 to indexed4" {
    const rgba32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgba32, 32 * 8);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Red,
            1 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Green,
            2 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Blue,
            3 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Yellow,
            4 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Magenta,
            5 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Cyan,
            6 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).White,
            7 => rgba32_pixels.rgba32[index] = Colors(color.Rgba32).Black,
            else => {},
        }
    }

    const indexed4_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba32_pixels, .indexed4);
    defer indexed4_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].a, 255);

    for (0..indexed4_pixels.indexed4.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 4),
            1 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 2),
            2 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 1),
            3 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 6),
            4 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 5),
            5 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 3),
            6 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 7),
            7 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 0),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert rgb332 to indexed4" {
    const rgb332_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb332, 32 * 8);
    defer rgb332_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgb332_pixels.rgb332.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Red,
            1 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Green,
            2 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Blue,
            3 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Yellow,
            4 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Magenta,
            5 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Cyan,
            6 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).White,
            7 => rgb332_pixels.rgb332[index] = Colors(color.Rgb332).Black,
            else => {},
        }
    }

    const indexed4_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb332_pixels, .indexed4);
    defer indexed4_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].a, 255);

    for (0..indexed4_pixels.indexed4.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 4),
            1 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 2),
            2 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 1),
            3 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 6),
            4 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 5),
            5 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 3),
            6 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 7),
            7 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 0),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert rgb565 to indexed4" {
    const rgb565_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb565, 32 * 8);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgb565_pixels.rgb565.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Red,
            1 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Green,
            2 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Blue,
            3 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Yellow,
            4 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Magenta,
            5 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Cyan,
            6 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).White,
            7 => rgb565_pixels.rgb565[index] = Colors(color.Rgb565).Black,
            else => {},
        }
    }

    const indexed4_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgb565_pixels, .indexed4);
    defer indexed4_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[0].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[1].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[2].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].r, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[3].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[4].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].g, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[5].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].b, 0);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[6].a, 255);

    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].r, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].g, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].b, 255);
    try helpers.expectEq(indexed4_pixels.indexed4.palette[7].a, 255);

    for (0..indexed4_pixels.indexed4.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 4),
            1 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 2),
            2 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 1),
            3 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 6),
            4 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 5),
            5 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 3),
            6 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 7),
            7 => try helpers.expectEq(indexed4_pixels.indexed4.indices[index], 0),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert grayscale8 to indexed8" {
    const grayscale8_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8, 32 * 8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..grayscale8_pixels.grayscale8.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => grayscale8_pixels.grayscale8[index].value = 0,
            1 => grayscale8_pixels.grayscale8[index].value = 32,
            2 => grayscale8_pixels.grayscale8[index].value = 64,
            3 => grayscale8_pixels.grayscale8[index].value = 96,
            4 => grayscale8_pixels.grayscale8[index].value = 128,
            5 => grayscale8_pixels.grayscale8[index].value = 160,
            6 => grayscale8_pixels.grayscale8[index].value = 192,
            7 => grayscale8_pixels.grayscale8[index].value = 224,
            else => {},
        }
    }

    const indexed8_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_pixels, .indexed8);
    defer indexed8_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[0].r, 0);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[0].g, 0);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[0].b, 0);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[0].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[1].r, 32);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[1].g, 32);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[1].b, 32);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[1].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[2].r, 64);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[2].g, 64);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[2].b, 64);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[2].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[3].r, 96);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[3].g, 96);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[3].b, 96);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[3].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[4].r, 128);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[4].g, 128);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[4].b, 128);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[4].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[5].r, 160);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[5].g, 160);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[5].b, 160);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[5].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[6].r, 192);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[6].g, 192);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[6].b, 192);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[6].a, 255);

    try helpers.expectEq(indexed8_pixels.indexed8.palette[7].r, 224);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[7].g, 224);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[7].b, 224);
    try helpers.expectEq(indexed8_pixels.indexed8.palette[7].a, 255);

    for (0..indexed8_pixels.indexed8.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 0),
            1 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 1),
            2 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 2),
            3 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 3),
            4 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 4),
            5 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 5),
            6 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 6),
            7 => try helpers.expectEq(indexed8_pixels.indexed8.indices[index], 7),
            else => {},
        }
    }
}

test "PixelFormatConverter: convert grayscale8 to indexed2" {
    const grayscale8_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .grayscale8, 32 * 8);
    defer grayscale8_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..grayscale8_pixels.grayscale8.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => grayscale8_pixels.grayscale8[index].value = 32,
            1 => grayscale8_pixels.grayscale8[index].value = 64,
            2 => grayscale8_pixels.grayscale8[index].value = 96,
            3 => grayscale8_pixels.grayscale8[index].value = 128,
            4 => grayscale8_pixels.grayscale8[index].value = 160,
            5 => grayscale8_pixels.grayscale8[index].value = 192,
            6 => grayscale8_pixels.grayscale8[index].value = 224,
            7 => grayscale8_pixels.grayscale8[index].value = 255,
            else => {},
        }
    }

    const indexed2_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &grayscale8_pixels, .indexed2);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(indexed2_pixels.indexed2.palette[0].r, 32);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[0].g, 32);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[0].b, 32);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[0].a, 255);

    try helpers.expectEq(indexed2_pixels.indexed2.palette[1].r, 80);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[1].g, 80);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[1].b, 80);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[1].a, 255);

    try helpers.expectEq(indexed2_pixels.indexed2.palette[2].r, 144);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[2].g, 144);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[2].b, 144);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[2].a, 255);

    try helpers.expectEq(indexed2_pixels.indexed2.palette[3].r, 223);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[3].g, 223);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[3].b, 223);
    try helpers.expectEq(indexed2_pixels.indexed2.palette[3].a, 255);

    for (0..indexed2_pixels.indexed2.indices.len) |index| {
        const row: u8 = @truncate(index / 32);

        switch (row) {
            0 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 0),
            1 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 1),
            2 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 1),
            3 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 2),
            4 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 2),
            5 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 3),
            6 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 3),
            7 => try helpers.expectEq(indexed2_pixels.indexed2.indices[index], 3),
            else => {},
        }
    }
}
