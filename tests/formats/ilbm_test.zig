const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const ilbm = @import("../../src/formats/ilbm.zig");
const color = @import("../../src/color.zig");
const ImageReadError = Image.ReadError;
const std = @import("std");
const testing = std.testing;
const Image = @import("../../src/Image.zig");
const helpers = @import("../helpers.zig");

test "ILBM indexed8 PBM (chunky Deluxe Paint DOS file)" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-pbm.iff");
    defer file.close();

    var the_bitmap = ilbm.ILBM{};

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

test "ILBM indexed8 8 bitplanes" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ilbm-8bit-compressed.iff");
    defer file.close();

    var the_bitmap = ilbm.ILBM{};

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

test "ILBM indexed8 8 bitplanes uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-ilbm-8bit-uncompressed.iff");
    defer file.close();

    var the_bitmap = ilbm.ILBM{};

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
