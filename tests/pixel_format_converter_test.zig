const std = @import("std");
const testing = std.testing;
const color = @import("../src/color.zig");
const PixelFormatConverter = @import("../src/PixelFormatConverter.zig");
const helpers = @import("helpers.zig");

const red_float32 = color.Colorf32.initRgb(1.0, 0.0, 0.0);
const green_float32 = color.Colorf32.initRgb(0.0, 1.0, 0.0);
const blue_float32 = color.Colorf32.initRgb(0.0, 0.0, 1.0);

fn Colors(comptime T: type) type {
    return struct {
        const RedT = std.meta.fieldInfo(T, .r).type;
        const GreenT = std.meta.fieldInfo(T, .g).type;
        const BlueT = std.meta.fieldInfo(T, .b).type;

        pub const red = T.initRgb(std.math.maxInt(RedT), 0, 0);
        pub const green = T.initRgb(0, std.math.maxInt(GreenT), 0);
        pub const blue = T.initRgb(0, 0, std.math.maxInt(BlueT));
        pub const white = T.initRgb(std.math.maxInt(RedT), std.math.maxInt(GreenT), std.math.maxInt(BlueT));
        pub const black = T.initRgb(0, 0, 0);
    };
}

const Colorsf32 = struct {
    pub const red = color.Colorf32.initRgb(1.0, 0.0, 0.0);
    pub const green = color.Colorf32.initRgb(0.0, 1.0, 0.0);
    pub const blue = color.Colorf32.initRgb(0.0, 0.0, 1.0);
    pub const white = color.Colorf32.initRgb(1.0, 1.0, 1.0);
    pub const black = color.Colorf32.initRgb(0.0, 0.0, 0.0);
};

// mlarouche: Not all conversion are tested, just the most important ones
// If any pixel conversion cause issues, we will add a test for it

test "PixelFormatConverter: convert from indexed1 to indexed2" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = Colors(color.Rgba32).red;
    indexed1_pixels.indexed1.palette[1] = Colors(color.Rgba32).green;
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

    indexed1_pixels.indexed1.palette[0] = Colors(color.Rgba32).red;
    indexed1_pixels.indexed1.palette[1] = Colors(color.Rgba32).green;
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

test "PixelFormatConverter: convert from indexed2 to rgb555" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb555);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb555_pixels.rgb555[0], Colors(color.Rgb555).red);
    try helpers.expectEq(rgb555_pixels.rgb555[1], Colors(color.Rgb555).green);
    try helpers.expectEq(rgb555_pixels.rgb555[2], Colors(color.Rgb555).blue);
    try helpers.expectEq(rgb555_pixels.rgb555[3], Colors(color.Rgb555).white);
}

test "PixelFormatConverter: convert from indexed2 to rgb565" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb565_pixels.rgb565[0], Colors(color.Rgb565).red);
    try helpers.expectEq(rgb565_pixels.rgb565[1], Colors(color.Rgb565).green);
    try helpers.expectEq(rgb565_pixels.rgb565[2], Colors(color.Rgb565).blue);
    try helpers.expectEq(rgb565_pixels.rgb565[3], Colors(color.Rgb565).white);
}

test "PixelFormatConverter: convert from indexed2 to rgb24" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb24);
    defer rgb24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb24_pixels.rgb24[0], Colors(color.Rgb24).red);
    try helpers.expectEq(rgb24_pixels.rgb24[1], Colors(color.Rgb24).green);
    try helpers.expectEq(rgb24_pixels.rgb24[2], Colors(color.Rgb24).blue);
    try helpers.expectEq(rgb24_pixels.rgb24[3], Colors(color.Rgb24).white);
}

test "PixelFormatConverter: convert from indexed2 to rgba32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0], Colors(color.Rgba32).red);
    try helpers.expectEq(rgba32_pixels.rgba32[1], Colors(color.Rgba32).green);
    try helpers.expectEq(rgba32_pixels.rgba32[2], Colors(color.Rgba32).blue);
    try helpers.expectEq(rgba32_pixels.rgba32[3], Colors(color.Rgba32).white);
}

test "PixelFormatConverter: convert from indexed2 to bgr555" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgr555_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgr555);
    defer bgr555_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr555_pixels.bgr555[0], Colors(color.Bgr555).red);
    try helpers.expectEq(bgr555_pixels.bgr555[1], Colors(color.Bgr555).green);
    try helpers.expectEq(bgr555_pixels.bgr555[2], Colors(color.Bgr555).blue);
    try helpers.expectEq(bgr555_pixels.bgr555[3], Colors(color.Bgr555).white);
}

test "PixelFormatConverter: convert from indexed2 to bgr24" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgr24_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgr24);
    defer bgr24_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgr24_pixels.bgr24[0], Colors(color.Bgr24).red);
    try helpers.expectEq(bgr24_pixels.bgr24[1], Colors(color.Bgr24).green);
    try helpers.expectEq(bgr24_pixels.bgr24[2], Colors(color.Bgr24).blue);
    try helpers.expectEq(bgr24_pixels.bgr24[3], Colors(color.Bgr24).white);
}

test "PixelFormatConverter: convert from indexed2 to bgra32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(bgra32_pixels.bgra32[0], Colors(color.Bgra32).red);
    try helpers.expectEq(bgra32_pixels.bgra32[1], Colors(color.Bgra32).green);
    try helpers.expectEq(bgra32_pixels.bgra32[2], Colors(color.Bgra32).blue);
    try helpers.expectEq(bgra32_pixels.bgra32[3], Colors(color.Bgra32).white);
}

test "PixelFormatConverter: convert from indexed2 to rgb48" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgb48_pixelss = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgb48);
    defer rgb48_pixelss.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgb48_pixelss.rgb48[0], Colors(color.Rgb48).red);
    try helpers.expectEq(rgb48_pixelss.rgb48[1], Colors(color.Rgb48).green);
    try helpers.expectEq(rgb48_pixelss.rgb48[2], Colors(color.Rgb48).blue);
    try helpers.expectEq(rgb48_pixelss.rgb48[3], Colors(color.Rgb48).white);
}

test "PixelFormatConverter: convert from indexed2 to rgba64" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba64_pixels.rgba64[0], Colors(color.Rgba64).red);
    try helpers.expectEq(rgba64_pixels.rgba64[1], Colors(color.Rgba64).green);
    try helpers.expectEq(rgba64_pixels.rgba64[2], Colors(color.Rgba64).blue);
    try helpers.expectEq(rgba64_pixels.rgba64[3], Colors(color.Rgba64).white);
}

test "PixelFormatConverter: convert from indexed2 to Colorf32" {
    const indexed2_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(helpers.zigimg_test_allocator);

    indexed2_pixels.indexed2.palette[0] = Colors(color.Rgba32).red;
    indexed2_pixels.indexed2.palette[1] = Colors(color.Rgba32).green;
    indexed2_pixels.indexed2.palette[2] = Colors(color.Rgba32).blue;
    indexed2_pixels.indexed2.palette[3] = Colors(color.Rgba32).white;

    indexed2_pixels.indexed2.indices[0] = 0;
    indexed2_pixels.indexed2.indices[1] = 1;
    indexed2_pixels.indexed2.indices[2] = 2;
    indexed2_pixels.indexed2.indices[3] = 3;

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed2_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(float32_pixels.float32[0], Colorsf32.red);
    try helpers.expectEq(float32_pixels.float32[1], Colorsf32.green);
    try helpers.expectEq(float32_pixels.float32[2], Colorsf32.blue);
    try helpers.expectEq(float32_pixels.float32[3], Colorsf32.white);
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

test "PixelFormatConverter: convvert from rgb555 to rgb565" {
    const rgb555_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .rgb555, 5);
    defer rgb555_pixels.deinit(helpers.zigimg_test_allocator);

    rgb555_pixels.rgb555[0] = color.Rgb555.initRgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.initRgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.initRgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.initRgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.initRgb(0, 0, 0);

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

    rgb555_pixels.rgb555[0] = color.Rgb555.initRgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.initRgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.initRgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.initRgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.initRgb(0, 0, 0);

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

    rgb555_pixels.rgb555[0] = color.Rgb555.initRgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.initRgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.initRgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.initRgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.initRgb(0, 0, 0);

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

    rgb555_pixels.rgb555[0] = color.Rgb555.initRgb(31, 0, 0);
    rgb555_pixels.rgb555[1] = color.Rgb555.initRgb(0, 31, 0);
    rgb555_pixels.rgb555[2] = color.Rgb555.initRgb(0, 0, 31);
    rgb555_pixels.rgb555[3] = color.Rgb555.initRgb(31, 31, 31);
    rgb555_pixels.rgb555[4] = color.Rgb555.initRgb(0, 0, 0);

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
            0 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, 0, 0),
            1 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, column, 0),
            2 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, 0, column),
            3 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, column, 0),
            4 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, 0, column),
            5 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, column, column),
            6 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, column, column),
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
            0 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, 0, 0),
            1 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, column, 0),
            2 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, 0, column),
            3 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, column, 0),
            4 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, 0, column),
            5 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, column, column),
            6 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, column, column),
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
            0 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, 0, 0),
            1 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, column, 0),
            2 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, 0, column),
            3 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, column, 0),
            4 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, 0, column),
            5 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(0, column, column),
            6 => rgba32_pixels.rgba32[index] = color.Rgba32.initRgb(column, column, column),
            else => {},
        }
    }

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &rgba32_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;
    for (0..float32_pixels.float32.len) |index| {
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].r, color.toF32Color(rgba32_pixels.rgba32[index].r), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].g, color.toF32Color(rgba32_pixels.rgba32[index].g), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].b, color.toF32Color(rgba32_pixels.rgba32[index].b), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].a, color.toF32Color(rgba32_pixels.rgba32[index].a), float_tolerance);
    }
}

test "PixelFormatConverter: convert bgra32 to float32" {
    const bgra32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .bgra32, 256 * 7);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..bgra32_pixels.bgra32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: u8 = @truncate(index % 256);

        switch (row) {
            0 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, 0, 0),
            1 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, column, 0),
            2 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, 0, column),
            3 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, column, 0),
            4 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, 0, column),
            5 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(0, column, column),
            6 => bgra32_pixels.bgra32[index] = color.Bgra32.initRgb(column, column, column),
            else => {},
        }
    }

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &bgra32_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    const float_tolerance = 0.0001;
    for (0..float32_pixels.float32.len) |index| {
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].r, color.toF32Color(bgra32_pixels.bgra32[index].r), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].g, color.toF32Color(bgra32_pixels.bgra32[index].g), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].b, color.toF32Color(bgra32_pixels.bgra32[index].b), float_tolerance);
        try helpers.expectApproxEqAbs(float32_pixels.float32[index].a, color.toF32Color(bgra32_pixels.bgra32[index].a), float_tolerance);
    }
}

test "PixelFormatConverter: convert float32 to rgba32" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = color.toF32Color(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, column),
            else => {},
        }
    }

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba32_pixels.rgba32.len) |index| {
        try helpers.expectEq(rgba32_pixels.rgba32[index].r, color.toIntColor(u8, float32_pixels.float32[index].r));
        try helpers.expectEq(rgba32_pixels.rgba32[index].g, color.toIntColor(u8, float32_pixels.float32[index].g));
        try helpers.expectEq(rgba32_pixels.rgba32[index].b, color.toIntColor(u8, float32_pixels.float32[index].b));
        try helpers.expectEq(rgba32_pixels.rgba32[index].a, color.toIntColor(u8, float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to bgra32" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = color.toF32Color(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, column),
            else => {},
        }
    }

    const bgra32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .bgra32);
    defer bgra32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..bgra32_pixels.bgra32.len) |index| {
        try helpers.expectEq(bgra32_pixels.bgra32[index].r, color.toIntColor(u8, float32_pixels.float32[index].r));
        try helpers.expectEq(bgra32_pixels.bgra32[index].g, color.toIntColor(u8, float32_pixels.float32[index].g));
        try helpers.expectEq(bgra32_pixels.bgra32[index].b, color.toIntColor(u8, float32_pixels.float32[index].b));
        try helpers.expectEq(bgra32_pixels.bgra32[index].a, color.toIntColor(u8, float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to rgba64" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = color.toF32Color(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, column),
            else => {},
        }
    }

    const rgba64_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgba64);
    defer rgba64_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgba64_pixels.rgba64.len) |index| {
        try helpers.expectEq(rgba64_pixels.rgba64[index].r, color.toIntColor(u16, float32_pixels.float32[index].r));
        try helpers.expectEq(rgba64_pixels.rgba64[index].g, color.toIntColor(u16, float32_pixels.float32[index].g));
        try helpers.expectEq(rgba64_pixels.rgba64[index].b, color.toIntColor(u16, float32_pixels.float32[index].b));
        try helpers.expectEq(rgba64_pixels.rgba64[index].a, color.toIntColor(u16, float32_pixels.float32[index].a));
    }
}

test "PixelFormatConverter: convert float32 to rgb565" {
    const float32_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .float32, 256 * 7);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..float32_pixels.float32.len) |index| {
        const row: u8 = @truncate(index / 256);
        const column: f32 = color.toF32Color(@as(u8, @truncate(index % 256)));

        switch (row) {
            0 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, 0),
            1 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, 0),
            2 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, 0, column),
            3 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, 0),
            4 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, 0, column),
            5 => float32_pixels.float32[index] = color.Colorf32.initRgb(0, column, column),
            6 => float32_pixels.float32[index] = color.Colorf32.initRgb(column, column, column),
            else => {},
        }
    }

    const rgb565_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &float32_pixels, .rgb565);
    defer rgb565_pixels.deinit(helpers.zigimg_test_allocator);

    for (0..rgb565_pixels.rgb565.len) |index| {
        try helpers.expectEq(rgb565_pixels.rgb565[index].r, color.toIntColor(u5, float32_pixels.float32[index].r));
        try helpers.expectEq(rgb565_pixels.rgb565[index].g, color.toIntColor(u6, float32_pixels.float32[index].g));
        try helpers.expectEq(rgb565_pixels.rgb565[index].b, color.toIntColor(u5, float32_pixels.float32[index].b));
    }
}
