const PixelFormat = zigimg.PixelFormat;
const sgi = zigimg.formats.sgi;
const color = zigimg.color;
const zigimg = @import("../../zigimg.zig");
const Image = zigimg.Image;
const std = @import("std");
const testing = std.testing;
const helpers = @import("../helpers.zig");

test "Should error on non SGI images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var sgi_file = sgi.SGI{};

    const invalid_file = sgi_file.read(&stream_source, helpers.zigimg_test_allocator);
    try helpers.expectError(invalid_file, Image.ReadError.InvalidData);
}

test "SGI 24-bit uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-rgb24.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

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

test "SGI grayscale uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-blackwhite.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[141].value, 255);
    try helpers.expectEq(pixels.grayscale8[1_716].value, 0);
}

test "SGI 32-bit RGBA uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-rgba.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);
    try testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "SGI RGB48be uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-rgb48be.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);
    try testing.expect(pixels == .rgb48);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb48[index].to.u32Rgb(), hex_color);
    }
}

test "SGI grayscale rle compressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-gray-rle.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 1250);
    try helpers.expectEq(the_bitmap.height(), 438);
    try testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[141].value, 255);
    try helpers.expectEq(pixels.grayscale8[1_716].value, 0);
}

test "SGI 24-bit rle compressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-24bit-rle.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

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

test "SGI RGB48be rle uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-rgb48be-rle.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);
    try testing.expect(pixels == .rgb48);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb48[index].to.u32Rgb(), hex_color);
    }
}

test "SGI 32-bit RGBA rle compressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "sgi/sample-rgba-rle.sgi");
    defer file.close();

    var the_bitmap = sgi.SGI{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);
    try testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}
