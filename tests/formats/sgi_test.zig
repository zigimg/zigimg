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
        try helpers.expectEq(pixels.rgb24[index].toU32Rgb(), hex_color);
    }
}
