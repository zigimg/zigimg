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
