const ImageInStream = zigimg.ImageInStream;
const ImageSeekStream = zigimg.ImageSeekStream;
const PixelFormat = zigimg.PixelFormat;
const assert = std.debug.assert;
const color = zigimg.color;
const errors = zigimg.errors;
const png = zigimg.png;
const std = @import("std");
const testing = std.testing;
const zigimg = @import("zigimg");
usingnamespace @import("../helpers.zig");

const TestInput = struct {
    x: u32 = 0,
    y: u32 = 0,
    hex: u32 = 0,
};

test "Read leroycep1 properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/leroycep1.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.ColorStorage = null;
    try pngFile.read(stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pngFile.header.width, 17);
    expectEq(pngFile.header.height, 12);
    expectEq(pngFile.header.color_type, png.ColorType.Truecolor);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Rgb24);

        const test_inputs = [_]TestInput{
            .{
                .x = 7,
                .hex = 0x062fc2,
            },
            .{
                .x = 8,
                .hex = 0x4c68cf,
            },
            .{
                .x = 7,
                .y = 1,
                .hex = 0x8798d9,
            },
            .{
                .x = 9,
                .y = 2,
                .hex = 0xebebeb,
            },
        };

        for (test_inputs) |input| {
            const expected_color = color.IntegerColor8.fromHtmlHex(input.hex);

            const index = pngFile.header.width * input.y + input.x;

            expectEq(pixels.Rgb24[index].toColor().toIntegerColor8(), expected_color);
        }
    }
}

test "Read leroycep2 properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/leroycep2.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.ColorStorage = null;
    try pngFile.read(stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pngFile.header.width, 37);
    expectEq(pngFile.header.height, 39);
    expectEq(pngFile.header.color_type, png.ColorType.TruecolorAlpha);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Rgba32);

        const test_inputs = [_]TestInput{
            .{
                .x = 8,
                .y = 9,
                .hex = 0xb37e6d,
            },
            .{
                .x = 10,
                .y = 24,
                .hex = 0x914f28,
            },
            .{
                .x = 16,
                .y = 15,
                .hex = 0x914f28,
            },
            .{
                .x = 22,
                .y = 33,
                .hex = 0x412b0f,
            },
        };

        for (test_inputs) |input| {
            const expected_color = color.IntegerColor8.fromHtmlHex(input.hex);

            const index = pngFile.header.width * input.y + input.x;

            expectEq(pixels.Rgba32[index].toColor().toIntegerColor8(), expected_color);
        }
    }
}

test "Read leroycep3 properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/leroycep3.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.ColorStorage = null;
    try pngFile.read(stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pngFile.header.width, 10);
    expectEq(pngFile.header.height, 10);
    expectEq(pngFile.header.color_type, png.ColorType.Truecolor);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Rgb24);

        const test_inputs = [_]TestInput{
            .{
                .x = 3,
                .hex = 0xc3600b,
            },
            .{
                .x = 4,
                .hex = 0xd6a275,
            },
            .{
                .x = 5,
                .hex = 0xd9ab85,
            },
            .{
                .x = 5,
                .y = 2,
                .hex = 0xebebeb,
            },
        };

        for (test_inputs) |input| {
            const expected_color = color.IntegerColor8.fromHtmlHex(input.hex);

            const index = pngFile.header.width * input.y + input.x;

            expectEq(pixels.Rgb24[index].toColor().toIntegerColor8(), expected_color);
        }
    }
}

test "Read leroycep4 properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/leroycep4.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.ColorStorage = null;
    try pngFile.read(stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pngFile.header.width, 10);
    expectEq(pngFile.header.height, 10);
    expectEq(pngFile.header.color_type, png.ColorType.Truecolor);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Rgb24);

        const test_inputs = [_]TestInput{
            .{
                .x = 3,
                .hex = 0x88fb86,
            },
            .{
                .x = 4,
                .hex = 0xbbf3ba,
            },
            .{
                .x = 4,
                .y = 4,
                .hex = 0x2d452c,
            },
            .{
                .x = 5,
                .y = 4,
                .hex = 0x3d6d3c,
            },
            .{
                .x = 4,
                .y = 3,
                .hex = 0xebebeb,
            },
        };

        for (test_inputs) |input| {
            const expected_color = color.IntegerColor8.fromHtmlHex(input.hex);

            const index = pngFile.header.width * input.y + input.x;

            expectEq(pixels.Rgb24[index].toColor().toIntegerColor8(), expected_color);
        }
    }
}
