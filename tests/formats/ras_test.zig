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

test "Sun-Raster 24bit RGB24 uncompressed" {
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
        try helpers.expectEq(pixels.rgb24[index].toU32Rgb(), hex_color);
    }
}

test "Sun-Raster 24bit BGR24 uncompressed" {
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
        try helpers.expectEq(pixels.bgr24[index].toU32Rgb(), hex_color);
    }
}
