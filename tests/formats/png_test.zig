const ImageStream = image.ImageStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const ImageReadError = errors.ImageReadError;
const png = @import("../../src/formats/png.zig");
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

test "Should error on non PNG images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var png_file = png.PNG.init(helpers.zigimg_test_allocator);
    defer png_file.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    const invalidFile = png_file.read(&stream_source, &pixelsOpt);
    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalidFile, ImageReadError.InvalidData);
}

test "Read PNG header properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basn0g01.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var png_file = png.PNG.init(helpers.zigimg_test_allocator);
    defer png_file.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try png_file.read(&stream_source, &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(png_file.header.width, 32);
    try helpers.expectEq(png_file.header.height, 32);
    try helpers.expectEq(png_file.header.bit_depth, 1);
    try testing.expect(png_file.header.color_type == .grayscale);
    try helpers.expectEq(png_file.header.compression_method, 0);
    try helpers.expectEq(png_file.header.filter_method, 0);
    try testing.expect(png_file.header.interlace_method == .standard);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale1);
    }
}

test "Read gAMA chunk properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basn0g01.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var png_file = png.PNG.init(helpers.zigimg_test_allocator);
    defer png_file.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try png_file.read(&stream_source, &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    const gammaChunkOpt = png_file.findFirstChunk("gAMA");

    try testing.expect(gammaChunkOpt != null);

    if (gammaChunkOpt) |gammaChunk| {
        try helpers.expectEq(gammaChunk.gAMA.toGammaExponent(), 1.0);
    }
}

test "Png Suite" {
    _ = @import("png_basn_test.zig");
    _ = @import("png_basi_test.zig");
    _ = @import("png_odd_sizes_test.zig");
    _ = @import("png_bkgd_test.zig");
}

test "Misc tests" {
    _ = @import("png_misc_test.zig");
}
