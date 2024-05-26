const std = @import("std");
const testing = std.testing;
const color = @import("../src/color.zig");
const PixelFormatConverter = @import("../src/PixelFormatConverter.zig");
const helpers = @import("helpers.zig");

test "PixelFormatConverter: convert from indexed1 to indexed2" {
    const indexed1_pixels = try color.PixelStorage.init(helpers.zigimg_test_allocator, .indexed1, 4);
    defer indexed1_pixels.deinit(helpers.zigimg_test_allocator);

    indexed1_pixels.indexed1.palette[0] = color.Rgba32.initRgb(255, 0, 0);
    indexed1_pixels.indexed1.palette[1] = color.Rgba32.initRgb(0, 255, 0);
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

    indexed1_pixels.indexed1.palette[0] = color.Rgba32.initRgb(255, 0, 0);
    indexed1_pixels.indexed1.palette[1] = color.Rgba32.initRgb(0, 255, 0);
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
