const std = @import("std");
const testing = std.testing;
const color = @import("../src/color.zig");
const PixelFormatConverter = @import("../src/PixelFormatConverter.zig");
const helpers = @import("helpers.zig");

const red_rgba32 = color.Rgba32.initRgb(255, 0, 0);
const green_rgba32 = color.Rgba32.initRgb(0, 255, 0);
const blue_rgba32 = color.Rgba32.initRgb(0, 0, 255);

const red_float32 = color.Colorf32.initRgb(1.0, 0.0, 0.0);
const green_float32 = color.Colorf32.initRgb(0.0, 1.0, 0.0);
const blue_float32 = color.Colorf32.initRgb(0.0, 0.0, 1.0);

test "PixelFormatConverter: convert from indexed1 to indexed2" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = red_rgba32;
    indexed1_pixels.indexed1.palette[1] = green_rgba32;
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

    indexed1_pixels.indexed1.palette[0] = red_rgba32;
    indexed1_pixels.indexed1.palette[1] = green_rgba32;
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

test "PixelFormatConverter: convert from indexed1 to rgba32" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = red_rgba32;
    indexed1_pixels.indexed1.palette[1] = green_rgba32;
    indexed1_pixels.indexed1.indices[0] = 0;
    indexed1_pixels.indexed1.indices[1] = 1;
    indexed1_pixels.indexed1.indices[2] = 1;
    indexed1_pixels.indexed1.indices[3] = 0;

    const rgba32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed1_pixels, .rgba32);
    defer rgba32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(rgba32_pixels.rgba32[0], red_rgba32);
    try helpers.expectEq(rgba32_pixels.rgba32[1], green_rgba32);
    try helpers.expectEq(rgba32_pixels.rgba32[2], green_rgba32);
    try helpers.expectEq(rgba32_pixels.rgba32[3], red_rgba32);
}

test "PixelFormatConverter: convert from indexed1 to Colorf32" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = red_rgba32;
    indexed1_pixels.indexed1.palette[1] = green_rgba32;
    indexed1_pixels.indexed1.indices[0] = 0;
    indexed1_pixels.indexed1.indices[1] = 1;
    indexed1_pixels.indexed1.indices[2] = 1;
    indexed1_pixels.indexed1.indices[3] = 0;

    const float32_pixels = try PixelFormatConverter.convert(helpers.zigimg_test_allocator, &indexed1_pixels, .float32);
    defer float32_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(float32_pixels.float32[0], red_float32);
    try helpers.expectEq(float32_pixels.float32[1], green_float32);
    try helpers.expectEq(float32_pixels.float32[2], green_float32);
    try helpers.expectEq(float32_pixels.float32[3], red_float32);
}
