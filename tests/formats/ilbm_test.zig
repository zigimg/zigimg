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
