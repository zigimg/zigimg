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

test "RAS test file" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ras/sample-640x426.ras");
    defer file.close();

    var the_bitmap = ras.RAS{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);
}
// test "IFF-PBM indexed8 (chunky Deluxe Paint DOS file)" {
//     const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/sample-pbm.iff");
//     defer file.close();

//     var the_bitmap = iff.IFF{};

//     var stream_source = std.io.StreamSource{ .file = file };

//     const pixels = try the_bitmap.read(&stream_source, helpers.zigimg_test_allocator);
//     defer pixels.deinit(helpers.zigimg_test_allocator);

//     try helpers.expectEq(the_bitmap.width(), 380);
//     try helpers.expectEq(the_bitmap.height(), 133);
//     try testing.expect(pixels == .indexed8);

//     try helpers.expectEq(pixels.indexed8.indices[0], 0);
//     try helpers.expectEq(pixels.indexed8.indices[141], 58);

//     const palette0 = pixels.indexed8.palette[0];

//     try helpers.expectEq(palette0.r, 255);
//     try helpers.expectEq(palette0.g, 255);
//     try helpers.expectEq(palette0.b, 255);

//     const palette58 = pixels.indexed8.palette[58];

//     try helpers.expectEq(palette58.r, 251);
//     try helpers.expectEq(palette58.g, 209);
//     try helpers.expectEq(palette58.b, 148);
// }
