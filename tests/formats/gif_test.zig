const PixelFormat = zigimg.PixelFormat;
const gif = zigimg.gif;
const color = zigimg.color;
const errors = zigimg.errors;
const zigimg = @import("../../zigimg.zig");
const Image = zigimg.Image;
const std = @import("std");
const testing = std.testing;
const helpers = @import("../helpers.zig");

test "Run GIF test suite" {}

test "Read depth1 GIF image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "gif/depth1.gif");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var gif_file = gif.GIF{};

    var pixels_opt: ?color.PixelStorage = null;
    try gif_file.read(helpers.zigimg_test_allocator, &stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(gif_file.header.width, 1);
    try helpers.expectEq(gif_file.header.height, 1);
    // try helpers.expectEq(try gif_file.pixelFormat(), .Grayscale8);
}

test "Should error on non GIF images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var gif_file = gif.GIF{};

    var pixels_opt: ?color.PixelStorage = null;
    const invalid_file = gif_file.read(helpers.zigimg_test_allocator, &stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalid_file, Image.ReadError.InvalidData);
}
