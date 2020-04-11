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

test "Read basn3p04 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn3p04.png");
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
        expectEq(palette_chunk.palette.len, 15);
    }

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Bpp4);

        const color0 = pixels.Bpp4.palette[0].toIntegerColor8();
        const color1 = pixels.Bpp4.palette[1].toIntegerColor8();
        const color2 = pixels.Bpp4.palette[2].toIntegerColor8();
        const color3 = pixels.Bpp4.palette[3].toIntegerColor8();
        const color4 = pixels.Bpp4.palette[4].toIntegerColor8();
        const color5 = pixels.Bpp4.palette[5].toIntegerColor8();
        const color6 = pixels.Bpp4.palette[6].toIntegerColor8();
        const color7 = pixels.Bpp4.palette[7].toIntegerColor8();
        const color8 = pixels.Bpp4.palette[8].toIntegerColor8();
        const color9 = pixels.Bpp4.palette[9].toIntegerColor8();
        const color10 = pixels.Bpp4.palette[10].toIntegerColor8();
        const color11 = pixels.Bpp4.palette[11].toIntegerColor8();
        const color12 = pixels.Bpp4.palette[12].toIntegerColor8();
        const color13 = pixels.Bpp4.palette[13].toIntegerColor8();
        const color14 = pixels.Bpp4.palette[14].toIntegerColor8();

        expectEq(color0.R, 0x22);
        expectEq(color0.G, 0x00);
        expectEq(color0.B, 0xff);

        expectEq(color1.R, 0x00);
        expectEq(color1.G, 0xff);
        expectEq(color1.B, 0xff);

        expectEq(color2.R, 0x88);
        expectEq(color2.G, 0x00);
        expectEq(color2.B, 0xff);

        expectEq(color3.R, 0x22);
        expectEq(color3.G, 0xff);
        expectEq(color3.B, 0x00);

        expectEq(color4.R, 0x00);
        expectEq(color4.G, 0x99);
        expectEq(color4.B, 0xff);

        expectEq(color5.R, 0xff);
        expectEq(color5.G, 0x66);
        expectEq(color5.B, 0x00);

        expectEq(color6.R, 0xdd);
        expectEq(color6.G, 0x00);
        expectEq(color6.B, 0xff);

        expectEq(color7.R, 0x77);
        expectEq(color7.G, 0xff);
        expectEq(color7.B, 0x00);

        expectEq(color8.R, 0xff);
        expectEq(color8.G, 0x00);
        expectEq(color8.B, 0x00);

        expectEq(color9.R, 0x00);
        expectEq(color9.G, 0xff);
        expectEq(color9.B, 0x99);

        expectEq(color10.R, 0xdd);
        expectEq(color10.G, 0xff);
        expectEq(color10.B, 0x00);

        expectEq(color11.R, 0xff);
        expectEq(color11.G, 0x00);
        expectEq(color11.B, 0xbb);

        expectEq(color12.R, 0xff);
        expectEq(color12.G, 0xbb);
        expectEq(color12.B, 0x00);

        expectEq(color13.R, 0x00);
        expectEq(color13.G, 0x44);
        expectEq(color13.B, 0xff);

        expectEq(color14.R, 0x00);
        expectEq(color14.G, 0xff);
        expectEq(color14.B, 0x44);

        expectEq(pixels.Bpp4.indices[0], 8);
        expectEq(pixels.Bpp4.indices[4], 5);
        expectEq(pixels.Bpp4.indices[8], 12);
        expectEq(pixels.Bpp4.indices[12], 10);
        expectEq(pixels.Bpp4.indices[16], 7);
        expectEq(pixels.Bpp4.indices[20], 3);
        expectEq(pixels.Bpp4.indices[24], 14);
        expectEq(pixels.Bpp4.indices[28], 9);

        expectEq(pixels.Bpp4.indices[31 * 32 + 31], 11);
    }
}

test "Read basn3p08 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn3p08.png");
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
        expectEq(palette_chunk.palette.len, 256);
    }

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Bpp8);

        const color0 = pixels.Bpp8.palette[0].toIntegerColor8();
        const color64 = pixels.Bpp8.palette[64].toIntegerColor8();
        const color128 = pixels.Bpp8.palette[128].toIntegerColor8();
        const color192 = pixels.Bpp8.palette[192].toIntegerColor8();
        const color255 = pixels.Bpp8.palette[255].toIntegerColor8();

        expectEq(color0.R, 0x22);
        expectEq(color0.G, 0x44);
        expectEq(color0.B, 0x00);

        expectEq(color64.R, 0x66);
        expectEq(color64.G, 0x00);
        expectEq(color64.B, 0x00);

        expectEq(color128.R, 0xff);
        expectEq(color128.G, 0xff);
        expectEq(color128.B, 0x44);

        expectEq(color192.R, 0xba);
        expectEq(color192.G, 0x00);
        expectEq(color192.B, 0x00);

        expectEq(color255.R, 0xff);
        expectEq(color255.G, 0x33);
        expectEq(color255.B, 0xff);

        expectEq(pixels.Bpp8.indices[0], 165);
        expectEq(pixels.Bpp8.indices[16 * 32], 107);
        expectEq(pixels.Bpp8.indices[16 * 32 + 16], 65);
        expectEq(pixels.Bpp8.indices[31 * 32 + 31], 80);
    }
}

test "Read basn4a08 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn4a08.png");
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
        testing.expect(pixels == .Grayscale8Alpha);

        expectEq(pixels.Grayscale8Alpha[0].value, 255);
        expectEq(pixels.Grayscale8Alpha[0].alpha, 0);

        expectEq(pixels.Grayscale8Alpha[8].value, 255);
        expectEq(pixels.Grayscale8Alpha[8].alpha, 65);

        expectEq(pixels.Grayscale8Alpha[31].value, 255);
        expectEq(pixels.Grayscale8Alpha[31].alpha, 255);

        expectEq(pixels.Grayscale8Alpha[31 * 32 + 31].value, 0);
        expectEq(pixels.Grayscale8Alpha[31 * 32 + 31].alpha, 255);
    }
}

test "Read basn4a16 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn4a16.png");
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
        testing.expect(pixels == .Grayscale16Alpha);

        expectEq(pixels.Grayscale16Alpha[0].value, 0);
        expectEq(pixels.Grayscale16Alpha[0].alpha, 0);

        expectEq(pixels.Grayscale16Alpha[8].value, 33824);
        expectEq(pixels.Grayscale16Alpha[8].alpha, 0);

        expectEq(pixels.Grayscale16Alpha[9 * 32 + 8].value, 8737);
        expectEq(pixels.Grayscale16Alpha[9 * 32 + 8].alpha, 33825);

        expectEq(pixels.Grayscale16Alpha[31].value, 0);
        expectEq(pixels.Grayscale16Alpha[31].alpha, 0);

        expectEq(pixels.Grayscale16Alpha[31 * 32 + 31].value, 0);
        expectEq(pixels.Grayscale16Alpha[31 * 32 + 31].alpha, 0);
    }
}

test "Read basn6a08 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn6a08.png");
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
        testing.expect(pixels == .Rgba32);

        const color0 = pixels.Rgba32[0];
        const color16 = pixels.Rgba32[16];
        const color31 = pixels.Rgba32[31];
        const color16_16 = pixels.Rgba32[16 * 32 + 16];

        expectEq(color0.R, 0xFF);
        expectEq(color0.G, 0x00);
        expectEq(color0.B, 0x08);
        expectEq(color0.A, 0x00);

        expectEq(color16.R, 0xFF);
        expectEq(color16.G, 0x00);
        expectEq(color16.B, 0x08);
        expectEq(color16.A, 131);

        expectEq(color31.R, 0xFF);
        expectEq(color31.G, 0x00);
        expectEq(color31.B, 0x08);
        expectEq(color31.A, 0xFF);

        expectEq(color16_16.R, 0x04);
        expectEq(color16_16.G, 0xFF);
        expectEq(color16_16.B, 0x00);
        expectEq(color16_16.A, 131);
    }
}

test "Read basn6a16 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/basn6a16.png");
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
        testing.expect(pixels == .Rgba64);

        const color0 = pixels.Rgba64[0];
        const color16 = pixels.Rgba64[16];
        const color31 = pixels.Rgba64[31];
        const color16_16 = pixels.Rgba64[16 * 32 + 16];
        const color25_17 = pixels.Rgba64[17 * 32 + 25];

        expectEq(color0.R, 0xFFFF);
        expectEq(color0.G, 0xFFFF);
        expectEq(color0.B, 0x0000);
        expectEq(color0.A, 0x0000);

        expectEq(color16.R, 0x7BDE);
        expectEq(color16.G, 0xFFFF);
        expectEq(color16.B, 0x0000);
        expectEq(color16.A, 0x0000);

        expectEq(color31.R, 0x0000);
        expectEq(color31.G, 0xFFFF);
        expectEq(color31.B, 0x0000);
        expectEq(color31.A, 0x0000);

        expectEq(color16_16.R, 0x0000);
        expectEq(color16_16.G, 0x0000);
        expectEq(color16_16.B, 0xFFFF);
        expectEq(color16_16.A, 0xF7BD);

        expectEq(color25_17.R, 0x0000);
        expectEq(color25_17.G, 0x6BC9);
        expectEq(color25_17.B, 0x9435);
        expectEq(color25_17.A, 0x6319);
    }
}
