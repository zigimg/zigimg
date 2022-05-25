const ImageReader = image.ImageReader;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const tga = @import("../../src/formats/tga.zig");
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

test "Should error on non TGA images" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    const invalidFile = tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);
    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalidFile, errors.ImageError.InvalidMagicHeader);
}

test "Read ubw8 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/ubw8.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Grayscale8);

    const expected_strip = [_]u8{ 76, 149, 178, 0, 76, 149, 178, 254, 76, 149, 178, 0, 76, 149, 178, 254 };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Grayscale8);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Grayscale8[stride + x].value, expected_strip[strip_index]);
            }
        }
    }
}

test "Read ucm8 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/ucm8.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Bpp8);

    const expected_strip = [_]u8{ 64, 128, 192, 0, 64, 128, 192, 255, 64, 128, 192, 0, 64, 128, 192, 255 };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Bpp8);

        try helpers.expectEq(pixels.Bpp8.indices.len, 128 * 128);

        try helpers.expectEq(pixels.Bpp8.palette[0].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x000000));
        try helpers.expectEq(pixels.Bpp8.palette[64].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0xff0000));
        try helpers.expectEq(pixels.Bpp8.palette[128].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x00ff00));
        try helpers.expectEq(pixels.Bpp8.palette[192].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x0000ff));
        try helpers.expectEq(pixels.Bpp8.palette[255].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0xffffff));

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Bpp8.indices[stride + x], expected_strip[strip_index]);
            }
        }
    }
}

test "Read utc16 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/utc16.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgb555);

    const expected_strip = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff, 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgb555);

        try helpers.expectEq(pixels.Rgb555.len, 128 * 128);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Rgb555[stride + x].toColor().toIntegerColor8(), color.IntegerColor8.fromHtmlHex(expected_strip[strip_index]));
            }
        }
    }
}

test "Read utc24 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/utc24.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgb24);

    const expected_strip = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff, 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgb24);

        try helpers.expectEq(pixels.Rgb24.len, 128 * 128);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Rgb24[stride + x].toColor().toIntegerColor8(), color.IntegerColor8.fromHtmlHex(expected_strip[strip_index]));
            }
        }
    }
}

test "Read utc32 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/utc32.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgba32);

    const expected_strip = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff, 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgba32);

        try helpers.expectEq(pixels.Rgba32.len, 128 * 128);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Rgba32[stride + x].toColor().toIntegerColor8(), color.IntegerColor8.fromHtmlHex(expected_strip[strip_index]));
            }
        }
    }
}

test "Read cbw8 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/cbw8.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Grayscale8);

    const expected_strip = [_]u8{ 76, 149, 178, 0, 76, 149, 178, 254, 76, 149, 178, 0, 76, 149, 178, 254 };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Grayscale8);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Grayscale8[stride + x].value, expected_strip[strip_index]);
            }
        }
    }
}

test "Read ccm8 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/ccm8.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Bpp8);

    const expected_strip = [_]u8{ 64, 128, 192, 0, 64, 128, 192, 255, 64, 128, 192, 0, 64, 128, 192, 255 };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Bpp8);

        try helpers.expectEq(pixels.Bpp8.indices.len, 128 * 128);

        try helpers.expectEq(pixels.Bpp8.palette[0].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x000000));
        try helpers.expectEq(pixels.Bpp8.palette[64].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0xff0000));
        try helpers.expectEq(pixels.Bpp8.palette[128].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x00ff00));
        try helpers.expectEq(pixels.Bpp8.palette[192].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0x0000ff));
        try helpers.expectEq(pixels.Bpp8.palette[255].toIntegerColor8(), color.IntegerColor8.fromHtmlHex(0xffffff));

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Bpp8.indices[stride + x], expected_strip[strip_index]);
            }
        }
    }
}

test "Read ctc24 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/ctc24.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 128);
    try helpers.expectEq(tga_file.height(), 128);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgb24);

    const expected_strip = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff, 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xff0000, 0x00ff00, 0x0000ff, 0xffffff };

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgb24);

        try helpers.expectEq(pixels.Rgb24.len, 128 * 128);

        const width = tga_file.width();
        const height = tga_file.height();

        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;

            const stride = y * width;

            while (x < width) : (x += 1) {
                const strip_index = x / 8;

                try helpers.expectEq(pixels.Rgb24[stride + x].toColor().toIntegerColor8(), color.IntegerColor8.fromHtmlHex(expected_strip[strip_index]));
            }
        }
    }
}

test "Read matte-01 TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/matte-01.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 1280);
    try helpers.expectEq(tga_file.height(), 720);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgba32);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgba32);

        try helpers.expectEq(pixels.Rgba32.len, 1280 * 720);

        const test_inputs = [_]helpers.TestInput{
            .{
                .x = 0,
                .y = 0,
                .hex = 0x3b5f38,
            },
            .{
                .x = 608,
                .y = 357,
                .hex = 0x8e6c57,
            },
            .{
                .x = 972,
                .y = 679,
                .hex = 0xa46c41,
            },
        };

        for (test_inputs) |input| {
            const expected_color = color.IntegerColor8.fromHtmlHex(input.hex);

            const index = tga_file.header.width * input.y + input.x;

            try helpers.expectEq(pixels.Rgba32[index].toColor().toIntegerColor8(), expected_color);
        }
    }
}

test "Read font TGA file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/tests/fixtures/tga/font.tga");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var tga_file = tga.TGA{};

    var pixelsOpt: ?color.ColorStorage = null;
    try tga_file.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(tga_file.width(), 192);
    try helpers.expectEq(tga_file.height(), 256);
    try helpers.expectEq(try tga_file.pixelFormat(), .Rgba32);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .Rgba32);

        try helpers.expectEq(pixels.Rgba32.len, 192 * 256);

        const width = tga_file.width();

        try helpers.expectEq(pixels.Rgba32[64 * width + 16].toColor().toIntegerColor8(), color.IntegerColor8.initRGBA(0, 0, 0, 0));
        try helpers.expectEq(pixels.Rgba32[64 * width + 17].toColor().toIntegerColor8(), color.IntegerColor8.initRGBA(209, 209, 209, 255));
        try helpers.expectEq(pixels.Rgba32[65 * width + 17].toColor().toIntegerColor8(), color.IntegerColor8.initRGBA(255, 255, 255, 255));
    }
}
