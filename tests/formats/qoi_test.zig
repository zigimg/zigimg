const ImageReader = image.ImageReader;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const qoi = @import("../../src/formats/qoi.zig");
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

const zero_raw_pixels = @embedFile("../../../test-suite/tests/fixtures/qoi/zero.raw");
const zero_qoi = @embedFile("../../../test-suite/tests/fixtures/qoi/zero.qoi");

test "Should error on non QOI images" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var qoi_file = qoi.QOI{};

    var pixels_opt: ?color.ColorStorage = null;
    const invalid_file = qoi_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels_opt);
    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalid_file, errors.ImageError.InvalidMagicHeader);
}

test "Read zero.qoi file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/qoi/zero.qoi");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var qoi_file = qoi.QOI{};

    var pixels_opt: ?color.ColorStorage = null;
    try qoi_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(qoi_file.width(), 512);
    try helpers.expectEq(qoi_file.height(), 512);
    try helpers.expectEq(try qoi_file.pixelFormat(), .Rgba32);
    try testing.expect(qoi_file.header.colorspace == .sRGB);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .Rgba32);

        try testing.expectEqualSlices(u8, zero_raw_pixels, std.mem.sliceAsBytes(pixels.Rgba32));
    }
}

test "Write qoi file" {
    const source_image = try image.Image.create(helpers.zigimg_test_allocator, 512, 512, PixelFormat.Rgba32, .Qoi);
    defer source_image.deinit();

    std.mem.copy(u8, std.mem.sliceAsBytes(source_image.pixels.?.Rgba32), std.mem.bytesAsSlice(u8, zero_raw_pixels));

    var image_buffer: [std.mem.len(zero_qoi)]u8 = undefined;

    const result_image = try source_image.writeToMemory(image_buffer[0..], .Qoi, image.ImageEncoderOptions.None);

    try testing.expectEqualSlices(u8, zero_qoi[0..], result_image);
}
