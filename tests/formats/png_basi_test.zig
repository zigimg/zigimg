const ImageReader = image.ImageReader;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const png = @import("../../src/formats/png.zig");
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

test "Read basi0g01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi0g01.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale1);

        try helpers.expectEq(pixels.grayscale1[0].value, 1);
        try helpers.expectEq(pixels.grayscale1[31].value, 0);
        try helpers.expectEq(pixels.grayscale1[4 * 32 + 3].value, 1);
        try helpers.expectEq(pixels.grayscale1[4 * 32 + 4].value, 0);
        try helpers.expectEq(pixels.grayscale1[18 * 32 + 19].value, 0);
        try helpers.expectEq(pixels.grayscale1[18 * 32 + 20].value, 1);
        try helpers.expectEq(pixels.grayscale1[31 * 32 + 31].value, 0);
    }
}

test "Read basi0g02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi0g02.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale2);

        try helpers.expectEq(pixels.grayscale2[0].value, 0);
        try helpers.expectEq(pixels.grayscale2[4].value, 1);
        try helpers.expectEq(pixels.grayscale2[8].value, 2);
        try helpers.expectEq(pixels.grayscale2[12].value, 3);
        try helpers.expectEq(pixels.grayscale2[16 * 32 + 16].value, 0);
        try helpers.expectEq(pixels.grayscale2[31 * 32 + 31].value, 2);
    }
}

test "Read basi0g04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi0g04.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale4);

        try helpers.expectEq(pixels.grayscale4[0].value, 0);
        try helpers.expectEq(pixels.grayscale4[4].value, 1);
        try helpers.expectEq(pixels.grayscale4[8].value, 2);
        try helpers.expectEq(pixels.grayscale4[12].value, 3);
        try helpers.expectEq(pixels.grayscale4[16].value, 4);
        try helpers.expectEq(pixels.grayscale4[20].value, 5);
        try helpers.expectEq(pixels.grayscale4[24].value, 6);
        try helpers.expectEq(pixels.grayscale4[28].value, 7);
        try helpers.expectEq(pixels.grayscale4[31 * 32 + 31].value, 14);
    }
}

test "Read basi0g08 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi0g08.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale8);

        var i: usize = 0;
        while (i < 256) : (i += 1) {
            try helpers.expectEq(pixels.grayscale8[i].value, @intCast(u8, i));
        }

        while (i < 510) : (i += 1) {
            try helpers.expectEq(pixels.grayscale8[i].value, @intCast(u8, 510 - i));
        }
    }
}

test "Read basi0g16 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi0g16.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale16);

        try helpers.expectEq(pixels.grayscale16[0].value, 0);
        try helpers.expectEq(pixels.grayscale16[31].value, 47871);
    }
}

test "Read basi2c08 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi2c08.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgb24);

        try helpers.expectEq(pixels.rgb24[0].R, 0xFF);
        try helpers.expectEq(pixels.rgb24[0].G, 0xFF);
        try helpers.expectEq(pixels.rgb24[0].B, 0xFF);

        try helpers.expectEq(pixels.rgb24[7 * 32 + 31].R, 0xFF);
        try helpers.expectEq(pixels.rgb24[7 * 32 + 31].G, 0xFF);
        try helpers.expectEq(pixels.rgb24[7 * 32 + 31].B, 0);

        try helpers.expectEq(pixels.rgb24[15 * 32 + 31].R, 0xFF);
        try helpers.expectEq(pixels.rgb24[15 * 32 + 31].G, 0);
        try helpers.expectEq(pixels.rgb24[15 * 32 + 31].B, 0xFF);

        try helpers.expectEq(pixels.rgb24[23 * 32 + 31].R, 0x0);
        try helpers.expectEq(pixels.rgb24[23 * 32 + 31].G, 0xFF);
        try helpers.expectEq(pixels.rgb24[23 * 32 + 31].B, 0xFF);

        try helpers.expectEq(pixels.rgb24[31 * 32 + 31].R, 0x0);
        try helpers.expectEq(pixels.rgb24[31 * 32 + 31].G, 0x0);
        try helpers.expectEq(pixels.rgb24[31 * 32 + 31].B, 0x0);
    }
}

test "Read basi2c16 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi2c16.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgb48);

        try helpers.expectEq(pixels.rgb48[0].R, 0xFFFF);
        try helpers.expectEq(pixels.rgb48[0].G, 0xFFFF);
        try helpers.expectEq(pixels.rgb48[0].B, 0);

        try helpers.expectEq(pixels.rgb48[16 * 32 + 16].R, 0x7bde);
        try helpers.expectEq(pixels.rgb48[16 * 32 + 16].G, 0x7bde);
        try helpers.expectEq(pixels.rgb48[16 * 32 + 16].B, 0x842);

        try helpers.expectEq(pixels.rgb48[31 * 32 + 31].R, 0);
        try helpers.expectEq(pixels.rgb48[31 * 32 + 31].G, 0);
        try helpers.expectEq(pixels.rgb48[31 * 32 + 31].B, 0xFFFF);
    }
}

test "Read basi3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi3p01.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    var palette_chunk_opt = pngFile.getPalette();

    try testing.expect(palette_chunk_opt != null);

    if (palette_chunk_opt) |palette_chunk| {
        const first_color = palette_chunk.palette[0].toIntegerColor8();
        const second_color = palette_chunk.palette[1].toIntegerColor8();

        try helpers.expectEq(first_color.R, 0xee);
        try helpers.expectEq(first_color.G, 0xff);
        try helpers.expectEq(first_color.B, 0x22);

        try helpers.expectEq(second_color.R, 0x22);
        try helpers.expectEq(second_color.G, 0x66);
        try helpers.expectEq(second_color.B, 0xff);
    }

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .indexed1);
        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const first_color = pixels.indexed1.palette[0].toIntegerColor8();
        const second_color = pixels.indexed1.palette[1].toIntegerColor8();

        try helpers.expectEq(first_color.R, 0xee);
        try helpers.expectEq(first_color.G, 0xff);
        try helpers.expectEq(first_color.B, 0x22);

        try helpers.expectEq(second_color.R, 0x22);
        try helpers.expectEq(second_color.G, 0x66);
        try helpers.expectEq(second_color.B, 0xff);

        var i: usize = 0;
        while (i < pixels.indexed1.indices.len) : (i += 1) {
            const x = i % 32;
            const y = i / 32;

            const temp1 = (x / 4);
            const temp2 = (y / 4);

            const final_pixel: u1 = @intCast(u1, (temp1 + temp2) & 1);

            try helpers.expectEq(pixels.indexed1.indices[i], final_pixel);
        }
    }
}

test "Read basi3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi3p02.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    var palette_chunk_opt = pngFile.getPalette();

    try testing.expect(palette_chunk_opt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .indexed2);
        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toIntegerColor8();
        const color1 = pixels.indexed2.palette[1].toIntegerColor8();
        const color2 = pixels.indexed2.palette[2].toIntegerColor8();
        const color3 = pixels.indexed2.palette[3].toIntegerColor8();

        try helpers.expectEq(color0.R, 0x00);
        try helpers.expectEq(color0.G, 0xff);
        try helpers.expectEq(color0.B, 0x00);

        try helpers.expectEq(color1.R, 0xff);
        try helpers.expectEq(color1.G, 0x00);
        try helpers.expectEq(color1.B, 0x00);

        try helpers.expectEq(color2.R, 0xff);
        try helpers.expectEq(color2.G, 0xff);
        try helpers.expectEq(color2.B, 0x00);

        try helpers.expectEq(color3.R, 0x00);
        try helpers.expectEq(color3.G, 0x00);
        try helpers.expectEq(color3.B, 0xff);

        try helpers.expectEq(pixels.indexed2.indices[0], 3);
        try helpers.expectEq(pixels.indexed2.indices[4], 1);
        try helpers.expectEq(pixels.indexed2.indices[8], 2);
        try helpers.expectEq(pixels.indexed2.indices[12], 0);

        try helpers.expectEq(pixels.indexed2.indices[31 * 32 + 31], 3);
    }
}

test "Read basi3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi3p04.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    var palette_chunk_opt = pngFile.getPalette();

    try testing.expect(palette_chunk_opt != null);

    if (palette_chunk_opt) |palette_chunk| {
        try helpers.expectEq(palette_chunk.palette.len, 15);
    }

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .indexed4);

        const color0 = pixels.indexed4.palette[0].toIntegerColor8();
        const color1 = pixels.indexed4.palette[1].toIntegerColor8();
        const color2 = pixels.indexed4.palette[2].toIntegerColor8();
        const color3 = pixels.indexed4.palette[3].toIntegerColor8();
        const color4 = pixels.indexed4.palette[4].toIntegerColor8();
        const color5 = pixels.indexed4.palette[5].toIntegerColor8();
        const color6 = pixels.indexed4.palette[6].toIntegerColor8();
        const color7 = pixels.indexed4.palette[7].toIntegerColor8();
        const color8 = pixels.indexed4.palette[8].toIntegerColor8();
        const color9 = pixels.indexed4.palette[9].toIntegerColor8();
        const color10 = pixels.indexed4.palette[10].toIntegerColor8();
        const color11 = pixels.indexed4.palette[11].toIntegerColor8();
        const color12 = pixels.indexed4.palette[12].toIntegerColor8();
        const color13 = pixels.indexed4.palette[13].toIntegerColor8();
        const color14 = pixels.indexed4.palette[14].toIntegerColor8();

        try helpers.expectEq(color0.R, 0x22);
        try helpers.expectEq(color0.G, 0x00);
        try helpers.expectEq(color0.B, 0xff);

        try helpers.expectEq(color1.R, 0x00);
        try helpers.expectEq(color1.G, 0xff);
        try helpers.expectEq(color1.B, 0xff);

        try helpers.expectEq(color2.R, 0x88);
        try helpers.expectEq(color2.G, 0x00);
        try helpers.expectEq(color2.B, 0xff);

        try helpers.expectEq(color3.R, 0x22);
        try helpers.expectEq(color3.G, 0xff);
        try helpers.expectEq(color3.B, 0x00);

        try helpers.expectEq(color4.R, 0x00);
        try helpers.expectEq(color4.G, 0x99);
        try helpers.expectEq(color4.B, 0xff);

        try helpers.expectEq(color5.R, 0xff);
        try helpers.expectEq(color5.G, 0x66);
        try helpers.expectEq(color5.B, 0x00);

        try helpers.expectEq(color6.R, 0xdd);
        try helpers.expectEq(color6.G, 0x00);
        try helpers.expectEq(color6.B, 0xff);

        try helpers.expectEq(color7.R, 0x77);
        try helpers.expectEq(color7.G, 0xff);
        try helpers.expectEq(color7.B, 0x00);

        try helpers.expectEq(color8.R, 0xff);
        try helpers.expectEq(color8.G, 0x00);
        try helpers.expectEq(color8.B, 0x00);

        try helpers.expectEq(color9.R, 0x00);
        try helpers.expectEq(color9.G, 0xff);
        try helpers.expectEq(color9.B, 0x99);

        try helpers.expectEq(color10.R, 0xdd);
        try helpers.expectEq(color10.G, 0xff);
        try helpers.expectEq(color10.B, 0x00);

        try helpers.expectEq(color11.R, 0xff);
        try helpers.expectEq(color11.G, 0x00);
        try helpers.expectEq(color11.B, 0xbb);

        try helpers.expectEq(color12.R, 0xff);
        try helpers.expectEq(color12.G, 0xbb);
        try helpers.expectEq(color12.B, 0x00);

        try helpers.expectEq(color13.R, 0x00);
        try helpers.expectEq(color13.G, 0x44);
        try helpers.expectEq(color13.B, 0xff);

        try helpers.expectEq(color14.R, 0x00);
        try helpers.expectEq(color14.G, 0xff);
        try helpers.expectEq(color14.B, 0x44);

        try helpers.expectEq(pixels.indexed4.indices[0], 8);
        try helpers.expectEq(pixels.indexed4.indices[4], 5);
        try helpers.expectEq(pixels.indexed4.indices[8], 12);
        try helpers.expectEq(pixels.indexed4.indices[12], 10);
        try helpers.expectEq(pixels.indexed4.indices[16], 7);
        try helpers.expectEq(pixels.indexed4.indices[20], 3);
        try helpers.expectEq(pixels.indexed4.indices[24], 14);
        try helpers.expectEq(pixels.indexed4.indices[28], 9);

        try helpers.expectEq(pixels.indexed4.indices[31 * 32 + 31], 11);
    }
}

test "Read basi3p08 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi3p08.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    var palette_chunk_opt = pngFile.getPalette();

    try testing.expect(palette_chunk_opt != null);

    if (palette_chunk_opt) |palette_chunk| {
        try helpers.expectEq(palette_chunk.palette.len, 256);
    }

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .indexed8);

        const color0 = pixels.indexed8.palette[0].toIntegerColor8();
        const color64 = pixels.indexed8.palette[64].toIntegerColor8();
        const color128 = pixels.indexed8.palette[128].toIntegerColor8();
        const color192 = pixels.indexed8.palette[192].toIntegerColor8();
        const color255 = pixels.indexed8.palette[255].toIntegerColor8();

        try helpers.expectEq(color0.R, 0x22);
        try helpers.expectEq(color0.G, 0x44);
        try helpers.expectEq(color0.B, 0x00);

        try helpers.expectEq(color64.R, 0x66);
        try helpers.expectEq(color64.G, 0x00);
        try helpers.expectEq(color64.B, 0x00);

        try helpers.expectEq(color128.R, 0xff);
        try helpers.expectEq(color128.G, 0xff);
        try helpers.expectEq(color128.B, 0x44);

        try helpers.expectEq(color192.R, 0xba);
        try helpers.expectEq(color192.G, 0x00);
        try helpers.expectEq(color192.B, 0x00);

        try helpers.expectEq(color255.R, 0xff);
        try helpers.expectEq(color255.G, 0x33);
        try helpers.expectEq(color255.B, 0xff);

        try helpers.expectEq(pixels.indexed8.indices[0], 165);
        try helpers.expectEq(pixels.indexed8.indices[16 * 32], 107);
        try helpers.expectEq(pixels.indexed8.indices[16 * 32 + 16], 65);
        try helpers.expectEq(pixels.indexed8.indices[31 * 32 + 31], 80);
    }
}

test "Read basi4a08 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi4a08.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale8Alpha);

        try helpers.expectEq(pixels.grayscale8Alpha[0].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale8Alpha[8].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[8].alpha, 65);

        try helpers.expectEq(pixels.grayscale8Alpha[31].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[31].alpha, 255);

        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].alpha, 255);
    }
}

test "Read basi4a16 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi4a16.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale16Alpha);

        try helpers.expectEq(pixels.grayscale16Alpha[0].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[8].value, 33824);
        try helpers.expectEq(pixels.grayscale16Alpha[8].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[9 * 32 + 8].value, 8737);
        try helpers.expectEq(pixels.grayscale16Alpha[9 * 32 + 8].alpha, 33825);

        try helpers.expectEq(pixels.grayscale16Alpha[31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].alpha, 0);
    }
}

test "Read basi6a08 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi6a08.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba32);

        const color0 = pixels.rgba32[0];
        const color16 = pixels.rgba32[16];
        const color31 = pixels.rgba32[31];
        const color16_16 = pixels.rgba32[16 * 32 + 16];

        try helpers.expectEq(color0.R, 0xFF);
        try helpers.expectEq(color0.G, 0x00);
        try helpers.expectEq(color0.B, 0x08);
        try helpers.expectEq(color0.A, 0x00);

        try helpers.expectEq(color16.R, 0xFF);
        try helpers.expectEq(color16.G, 0x00);
        try helpers.expectEq(color16.B, 0x08);
        try helpers.expectEq(color16.A, 131);

        try helpers.expectEq(color31.R, 0xFF);
        try helpers.expectEq(color31.G, 0x00);
        try helpers.expectEq(color31.B, 0x08);
        try helpers.expectEq(color31.A, 0xFF);

        try helpers.expectEq(color16_16.R, 0x04);
        try helpers.expectEq(color16_16.G, 0xFF);
        try helpers.expectEq(color16_16.B, 0x00);
        try helpers.expectEq(color16_16.A, 131);
    }
}

test "Read basi6a16 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/basi6a16.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pngFile = png.PNG.init(helpers.zigimg_test_allocator);
    defer pngFile.deinit();

    var pixelsOpt: ?color.PixelStorage = null;
    try pngFile.read(stream_source.reader(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba64);

        const color0 = pixels.rgba64[0];
        const color16 = pixels.rgba64[16];
        const color31 = pixels.rgba64[31];
        const color16_16 = pixels.rgba64[16 * 32 + 16];
        const color25_17 = pixels.rgba64[17 * 32 + 25];

        try helpers.expectEq(color0.R, 0xFFFF);
        try helpers.expectEq(color0.G, 0xFFFF);
        try helpers.expectEq(color0.B, 0x0000);
        try helpers.expectEq(color0.A, 0x0000);

        try helpers.expectEq(color16.R, 0x7BDE);
        try helpers.expectEq(color16.G, 0xFFFF);
        try helpers.expectEq(color16.B, 0x0000);
        try helpers.expectEq(color16.A, 0x0000);

        try helpers.expectEq(color31.R, 0x0000);
        try helpers.expectEq(color31.G, 0xFFFF);
        try helpers.expectEq(color31.B, 0x0000);
        try helpers.expectEq(color31.A, 0x0000);

        try helpers.expectEq(color16_16.R, 0x0000);
        try helpers.expectEq(color16_16.G, 0x0000);
        try helpers.expectEq(color16_16.B, 0xFFFF);
        try helpers.expectEq(color16_16.A, 0xF7BD);

        try helpers.expectEq(color25_17.R, 0x0000);
        try helpers.expectEq(color25_17.G, 0x6BC9);
        try helpers.expectEq(color25_17.B, 0x9435);
        try helpers.expectEq(color25_17.A, 0x6319);
    }
}
