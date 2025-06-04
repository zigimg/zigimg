const PixelFormat = zigimg.PixelFormat;
const ras = zigimg.formats.ras;
const color = zigimg.color;
const zigimg = @import("../../zigimg.zig");
const Image = zigimg.Image;
const std = @import("std");
const testing = std.testing;
const helpers = @import("../helpers.zig");

test "Should error on non RAS images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var ras_file = ras.RAS{};

    const invalid_file = ras_file.read(&stream_source, helpers.zigimg_test_allocator);
    try helpers.expectError(invalid_file, Image.ReadError.InvalidData);
}

test "Sun-Raster 24-bit RGB24 uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-rgb24.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 664);
    try helpers.expectEq(the_bitmap.height(), 248);
    try testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "Sun-Raster 24-bit BGR24 uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-bgr24.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 664);
    try helpers.expectEq(the_bitmap.height(), 248);
    try testing.expect(pixels == .bgr24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21292e,
        0xdeb231,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.bgr24[index].to.u32Rgb(), hex_color);
    }
}

test "Sun-Raster 32-bit xRGB uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-xrgb32.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 25_100, 125_060, 261_940 };
    const expected_colors = [_]u32{ 0x0, 0xf7a41d, 0x121212 };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "Sun-Raster 8-bit with palette uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-8bit.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .indexed8);

    const palette2 = pixels.indexed8.palette[2];

    try helpers.expectEq(palette2.r, 72);
    try helpers.expectEq(palette2.g, 0);
    try helpers.expectEq(palette2.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[141], 255);
    try helpers.expectEq(pixels.indexed8.indices[25975], 255);
}

test "Sun-Raster 8-bit grayscale uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-8bit-grayscale.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[141].value, 255);
    try helpers.expectEq(pixels.grayscale8[191_545].value, 173);
}

test "Sun-Raster 1-bit black & white uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-blackwhite.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[141].value, 1);
    try helpers.expectEq(pixels.grayscale1[1_716].value, 0);
}

test "Sun-Raster bgr24 rle compressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-24bit-bgr-rle.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 664);
    try helpers.expectEq(the_bitmap.height(), 248);
    try testing.expect(pixels == .bgr24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.bgr24[index].to.u32Rgb(), hex_color);
    }
}
