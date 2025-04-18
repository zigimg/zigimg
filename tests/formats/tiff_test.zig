const PixelFormat = zigimg.PixelFormat;
const tiff = zigimg.formats.tiff;
const color = zigimg.color;
const zigimg = @import("../../zigimg.zig");
const Image = zigimg.Image;
const std = @import("std");
const testing = std.testing;
const helpers = @import("../helpers.zig");

test "Should error on non TIFF images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var sgi_file = tiff.TIFF{};

    const invalid_file = sgi_file.read(&stream_source, helpers.zigimg_test_allocator);
    try helpers.expectError(invalid_file, Image.ReadError.InvalidData);
}

test "TIFF/LE monochrome black uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-raw.tiff");
    defer file.close();

    var the_bitmap = tiff.TIFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 640);
    try helpers.expectEq(the_bitmap.height(), 426);
    try testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[2].value, 0);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 0);
}

test "TIFF/LE grayscale8 uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-grayscale8-raw.tiff");
    defer file.close();

    var the_bitmap = tiff.TIFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 128);
    try helpers.expectEq(the_bitmap.height(), 128);
    try testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[0].value, 76);
    try helpers.expectEq(pixels.grayscale8[8].value, 149);
    try helpers.expectEq(pixels.grayscale8[90].value, 0);
    try helpers.expectEq(pixels.grayscale8[128 * 66 + 72].value, 149);
}

test "TIFF/LE 8-bit with colormap uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-pal8-raw.tiff");
    defer file.close();

    var the_bitmap = tiff.TIFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 128);
    try helpers.expectEq(the_bitmap.height(), 128);
    try testing.expect(pixels == .indexed8);

    const palette64 = pixels.indexed8.palette[64];

    try helpers.expectEq(palette64.r, 255);
    try helpers.expectEq(palette64.g, 0);
    try helpers.expectEq(palette64.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[0], 64);
    try helpers.expectEq(pixels.indexed8.indices[12], 128);
}

test "TIFF/LE 24-bit uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-raw.tiff");
    defer file.close();

    var the_bitmap = tiff.TIFF{};

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
