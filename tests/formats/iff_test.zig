const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const iff = @import("../../src/formats/iff.zig");
const color = @import("../../src/color.zig");
const ImageReadError = Image.ReadError;
const std = @import("std");
const testing = std.testing;
const Image = @import("../../src/Image.zig");
const helpers = @import("../helpers.zig");

test "IFF-PBM indexed8 (chunky Deluxe Paint DOS file)" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-pbm.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 380);
    try helpers.expectEq(the_bitmap.height(), 133);
    try testing.expect(pixels == .indexed8);

    try helpers.expectEq(pixels.indexed8.indices[0], 0);
    try helpers.expectEq(pixels.indexed8.indices[141], 58);

    const palette0 = pixels.indexed8.palette[0];

    try helpers.expectEq(palette0.r, 255);
    try helpers.expectEq(palette0.g, 255);
    try helpers.expectEq(palette0.b, 255);

    const palette58 = pixels.indexed8.palette[58];

    try helpers.expectEq(palette58.r, 251);
    try helpers.expectEq(palette58.g, 209);
    try helpers.expectEq(palette58.b, 148);
}

test "IFF-ILBM indexed8 8 bitplanes" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ilbm-8bit-compressed.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 380);
    try helpers.expectEq(the_bitmap.height(), 200);
    try testing.expect(pixels == .indexed8);

    const palette2 = pixels.indexed8.palette[2];

    try helpers.expectEq(palette2.r, 247);
    try helpers.expectEq(palette2.g, 164);
    try helpers.expectEq(palette2.b, 29);

    try helpers.expectEq(pixels.indexed8.indices[141], 58);
    try helpers.expectEq(pixels.indexed8.indices[25975], 2);
}

test "IFF-ILBM indexed8 8 bitplanes uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ilbm-8bit-uncompressed.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 380);
    try helpers.expectEq(the_bitmap.height(), 200);
    try testing.expect(pixels == .indexed8);

    const palette2 = pixels.indexed8.palette[2];

    try helpers.expectEq(palette2.r, 247);
    try helpers.expectEq(palette2.g, 164);
    try helpers.expectEq(palette2.b, 29);

    try helpers.expectEq(pixels.indexed8.indices[141], 58);
    try helpers.expectEq(pixels.indexed8.indices[25975], 2);
}

test "IFF-ILBM indexed8 6 bitplanes EHB" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ehb.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 320);
    try helpers.expectEq(the_bitmap.height(), 256);
    try testing.expect(pixels == .indexed8);

    const palette2 = pixels.indexed8.palette[2];

    try helpers.expectEq(palette2.r, 34);
    try helpers.expectEq(palette2.g, 17);
    try helpers.expectEq(palette2.b, 34);

    const palette45 = pixels.indexed8.palette[45];

    try helpers.expectEq(palette45.r, 153);
    try helpers.expectEq(palette45.g, 170);
    try helpers.expectEq(palette45.b, 153);

    try helpers.expectEq(pixels.indexed8.indices[141], 21);
    try helpers.expectEq(pixels.indexed8.indices[25975], 61);
}

test "IFF-ILBM indexed8 4 bitplanes HAM" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ham.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 640);
    try helpers.expectEq(the_bitmap.height(), 480);

    try testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 26_505, 193_174, 244_089 };
    const expected_colors = [_]u32{
        0x91885f,
        0x44502b,
        0x808060,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "IFF-ILBM indexed8 6 bitplanes HAM8" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ham8.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 640);
    try helpers.expectEq(the_bitmap.height(), 480);

    try testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 26_505, 193_174, 244_089 };
    const expected_colors = [_]u32{
        0x8a9379,
        0x40441d,
        0x888068,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "IFF-ILBM 24bit" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-24bit.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 640);
    try helpers.expectEq(the_bitmap.height(), 480);

    try testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 26_505, 193_174, 244_089 };
    const expected_colors = [_]u32{
        0x8c9378,
        0x454115,
        0x888068,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "IFF-ILBM indexed8 4 bitplanes Atari ST" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ilbm-4bit-compressed-atari.iff");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 320);
    try helpers.expectEq(the_bitmap.height(), 200);
    try testing.expect(pixels == .indexed8);

    const palette4 = pixels.indexed8.palette[4];

    try helpers.expectEq(palette4.r, 255);
    try helpers.expectEq(palette4.g, 146);
    try helpers.expectEq(palette4.b, 0);

    const palette6 = pixels.indexed8.palette[6];

    try helpers.expectEq(palette6.r, 183);
    try helpers.expectEq(palette6.g, 183);
    try helpers.expectEq(palette6.b, 183);

    try helpers.expectEq(pixels.indexed8.indices[29_898], 5);
    try helpers.expectEq(pixels.indexed8.indices[31_207], 6);
}

test "IFF-ACBM indexed8 3 bitplanes uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-8bit.acbm");
    defer file.close();

    var the_bitmap = iff.IFF{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 320);
    try helpers.expectEq(the_bitmap.height(), 200);
    try testing.expect(pixels == .indexed8);

    const palette0 = pixels.indexed8.palette[0];

    try helpers.expectEq(palette0.r, 204);
    try helpers.expectEq(palette0.g, 204);
    try helpers.expectEq(palette0.b, 204);

    const palette2 = pixels.indexed8.palette[2];

    try helpers.expectEq(palette2.r, 255);
    try helpers.expectEq(palette2.g, 255);
    try helpers.expectEq(palette2.b, 255);

    try helpers.expectEq(pixels.indexed8.indices[141], 0);
    try helpers.expectEq(pixels.indexed8.indices[15975], 6);
}
