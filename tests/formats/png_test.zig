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

test "Read basn2c16 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn2c16.png");
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
        testing.expect(pixels == .Rgb48);

        expectEq(pixels.Rgb48[0].R, 0xFFFF);
        expectEq(pixels.Rgb48[0].G, 0xFFFF);
        expectEq(pixels.Rgb48[0].B, 0);

        expectEq(pixels.Rgb48[16 * 32 + 16].R, 0x7bde);
        expectEq(pixels.Rgb48[16 * 32 + 16].G, 0x7bde);
        expectEq(pixels.Rgb48[16 * 32 + 16].B, 0x842);

        expectEq(pixels.Rgb48[31 * 32 + 31].R, 0);
        expectEq(pixels.Rgb48[31 * 32 + 31].G, 0);
        expectEq(pixels.Rgb48[31 * 32 + 31].B, 0xFFFF);
    }
}

test "Read basn3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn3p01.png");
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

    var palette_chunk_opt = pngFile.getPalette();

    testing.expect(palette_chunk_opt != null);

    if (palette_chunk_opt) |palette_chunk| {
        const first_color = palette_chunk.palette[0].toIntegerColor8();
        const second_color = palette_chunk.palette[1].toIntegerColor8();

        expectEq(first_color.R, 0xee);
        expectEq(first_color.G, 0xff);
        expectEq(first_color.B, 0x22);

        expectEq(second_color.R, 0x22);
        expectEq(second_color.G, 0x66);
        expectEq(second_color.B, 0xff);
    }

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Bpp1);
        expectEq(pixels.Bpp1.palette.len, 2);

        const first_color = pixels.Bpp1.palette[0].toIntegerColor8();
        const second_color = pixels.Bpp1.palette[1].toIntegerColor8();

        expectEq(first_color.R, 0xee);
        expectEq(first_color.G, 0xff);
        expectEq(first_color.B, 0x22);

        expectEq(second_color.R, 0x22);
        expectEq(second_color.G, 0x66);
        expectEq(second_color.B, 0xff);

        var i: usize = 0;
        while (i < pixels.Bpp1.indices.len) : (i += 1) {
            const x = i % 32;
            const y = i / 32;

            const temp1 = (x / 4);
            const temp2 = (y / 4);

            const final_pixel: u1 = @intCast(u1, (temp1 + temp2) & 1);

            expectEq(pixels.Bpp1.indices[i], final_pixel);
        }
    }
}

test "Read basn3p02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn3p02.png");
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

    var palette_chunk_opt = pngFile.getPalette();

    testing.expect(palette_chunk_opt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Bpp2);
        expectEq(pixels.Bpp2.palette.len, 4);

        const color0 = pixels.Bpp2.palette[0].toIntegerColor8();
        const color1 = pixels.Bpp2.palette[1].toIntegerColor8();
        const color2 = pixels.Bpp2.palette[2].toIntegerColor8();
        const color3 = pixels.Bpp2.palette[3].toIntegerColor8();

        expectEq(color0.R, 0x00);
        expectEq(color0.G, 0xff);
        expectEq(color0.B, 0x00);

        expectEq(color1.R, 0xff);
        expectEq(color1.G, 0x00);
        expectEq(color1.B, 0x00);

        expectEq(color2.R, 0xff);
        expectEq(color2.G, 0xff);
        expectEq(color2.B, 0x00);

        expectEq(color3.R, 0x00);
        expectEq(color3.G, 0x00);
        expectEq(color3.B, 0xff);

        expectEq(pixels.Bpp2.indices[0], 3);
        expectEq(pixels.Bpp2.indices[4], 1);
        expectEq(pixels.Bpp2.indices[8], 2);
        expectEq(pixels.Bpp2.indices[12], 0);

        expectEq(pixels.Bpp2.indices[31 * 32 + 31], 3);
    }
}
