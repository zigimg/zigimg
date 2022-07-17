const ImageStream = image.ImageStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const qoi = @import("../../src/formats/qoi.zig");
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const ImageReadError = errors.ImageReadError;
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

const zero_raw_file = helpers.fixtures_path ++ "qoi/zero.raw";
const zero_qoi_file = helpers.fixtures_path ++ "qoi/zero.qoi";

test "Should error on non QOI images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var qoi_file = qoi.QOI{};

    var pixels_opt: ?color.PixelStorage = null;
    const invalid_file = qoi_file.read(helpers.zigimg_test_allocator, &stream_source, &pixels_opt);
    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalid_file, ImageReadError.InvalidData);
}

test "Read zero.qoi file" {
    const file = try helpers.testOpenFile(zero_qoi_file);
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var qoi_file = qoi.QOI{};

    var pixels_opt: ?color.PixelStorage = null;
    try qoi_file.read(helpers.zigimg_test_allocator, &stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(qoi_file.width(), 512);
    try helpers.expectEq(qoi_file.height(), 512);
    try helpers.expectEq(try qoi_file.pixelFormat(), .rgba32);
    try testing.expect(qoi_file.header.colorspace == .srgb);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .rgba32);

        var buffer: [1025 * 1024]u8 = undefined;
        var zero_raw_pixels = try helpers.testReadFile(zero_raw_file, buffer[0..]);
        try testing.expectEqualSlices(u8, zero_raw_pixels, std.mem.sliceAsBytes(pixels.rgba32));
    }
}

test "Write qoi file" {
    const source_image = try image.Image.create(helpers.zigimg_test_allocator, 512, 512, PixelFormat.rgba32);
    defer source_image.deinit();

    var buffer: [1025 * 1024]u8 = undefined;
    var zero_raw_pixels = try helpers.testReadFile(zero_raw_file, buffer[0..]);
    std.mem.copy(u8, std.mem.sliceAsBytes(source_image.pixels.?.rgba32), std.mem.bytesAsSlice(u8, zero_raw_pixels));

    var image_buffer: [100 * 1024]u8 = undefined;
    var zero_qoi = try helpers.testReadFile(zero_qoi_file, buffer[0..]);

    const result_image = try source_image.writeToMemory(image_buffer[0..], .qoi, image.ImageEncoderOptions.None);

    try testing.expectEqualSlices(u8, zero_qoi[0..], result_image);
}
