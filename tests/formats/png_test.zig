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

test "Should error on non PNG images" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.ColorStorage = null;
    const invalidFile = pngFile.read(stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);
    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectError(invalidFile, errors.ImageError.InvalidMagicHeader);
}

test "Read PNG header properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g01.png");
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

    expectEq(pngFile.header.width, 32);
    expectEq(pngFile.header.height, 32);
    expectEq(pngFile.header.bit_depth, 1);
    testing.expect(pngFile.header.color_type == .Grayscale);
    expectEq(pngFile.header.compression_method, 0);
    expectEq(pngFile.header.filter_method, 0);
    testing.expect(pngFile.header.interlace_method == .Standard);

    testing.expect(pngFile.pixel_format == .Grayscale1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale1);
    }
}

test "Read gAMA chunk properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g01.png");
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

    const gammaChunkOpt = pngFile.findFirstChunk("gAMA");

    testing.expect(gammaChunkOpt != null);

    if (gammaChunkOpt) |gammaChunk| {
        expectEq(gammaChunk.gAMA.toGammaExponent(), 1.0);
    }
}

test "Read basn0g01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g01.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale1);

        expectEq(pixels.Grayscale1[0].value, 1);
        expectEq(pixels.Grayscale1[31].value, 0);
        expectEq(pixels.Grayscale1[4 * 32 + 3].value, 1);
        expectEq(pixels.Grayscale1[4 * 32 + 4].value, 0);
        expectEq(pixels.Grayscale1[18 * 32 + 19].value, 0);
        expectEq(pixels.Grayscale1[18 * 32 + 20].value, 1);
        expectEq(pixels.Grayscale1[31 * 32 + 31].value, 0);
    }
}

test "Read basn0g02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g02.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale2);

        expectEq(pixels.Grayscale2[0].value, 0);
        expectEq(pixels.Grayscale2[4].value, 1);
        expectEq(pixels.Grayscale2[8].value, 2);
        expectEq(pixels.Grayscale2[12].value, 3);
        expectEq(pixels.Grayscale2[16 * 32 + 16].value, 0);
        expectEq(pixels.Grayscale2[31 * 32 + 31].value, 2);
    }
}

test "Read basn0g04 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g04.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale4);

        expectEq(pixels.Grayscale4[0].value, 0);
        expectEq(pixels.Grayscale4[4].value, 1);
        expectEq(pixels.Grayscale4[8].value, 2);
        expectEq(pixels.Grayscale4[12].value, 3);
        expectEq(pixels.Grayscale4[16].value, 4);
        expectEq(pixels.Grayscale4[20].value, 5);
        expectEq(pixels.Grayscale4[24].value, 6);
        expectEq(pixels.Grayscale4[28].value, 7);
        expectEq(pixels.Grayscale4[31 * 32 + 31].value, 14);
    }
}

test "Read basn0g08 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g08.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale8);

        var i: usize = 0;
        while (i < 256) : (i += 1) {
            expectEq(pixels.Grayscale8[i].value, @intCast(u8, i));
        }

        while (i < 510) : (i += 1) {
            expectEq(pixels.Grayscale8[i].value, @intCast(u8, 510 - i));
        }
    }
}

test "Read basn0g16 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn0g16.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale16);

        expectEq(pixels.Grayscale16[0].value, 0);
        expectEq(pixels.Grayscale16[31].value, 47871);
    }
}

test "Read basn2c08 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn2c08.png");
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

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Rgb24);

        expectEq(pixels.Rgb24[0].R, 0xFF);
        expectEq(pixels.Rgb24[0].G, 0xFF);
        expectEq(pixels.Rgb24[0].B, 0xFF);

        expectEq(pixels.Rgb24[7 * 32 + 31].R, 0xFF);
        expectEq(pixels.Rgb24[7 * 32 + 31].G, 0xFF);
        expectEq(pixels.Rgb24[7 * 32 + 31].B, 0);

        expectEq(pixels.Rgb24[15 * 32 + 31].R, 0xFF);
        expectEq(pixels.Rgb24[15 * 32 + 31].G, 0);
        expectEq(pixels.Rgb24[15 * 32 + 31].B, 0xFF);

        expectEq(pixels.Rgb24[23 * 32 + 31].R, 0x0);
        expectEq(pixels.Rgb24[23 * 32 + 31].G, 0xFF);
        expectEq(pixels.Rgb24[23 * 32 + 31].B, 0xFF);

        expectEq(pixels.Rgb24[31 * 32 + 31].R, 0x0);
        expectEq(pixels.Rgb24[31 * 32 + 31].G, 0x0);
        expectEq(pixels.Rgb24[31 * 32 + 31].B, 0x0);
    }
}
