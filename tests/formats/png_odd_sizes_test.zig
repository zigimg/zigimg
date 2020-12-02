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

test "Read s01i3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s01i3p01.png");
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

    expectEq(pngFile.header.width, 1);
    expectEq(pngFile.header.height, 1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 0);
        expectEq(firstColor.B, 255);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0);
        expectEq(secondColor.G, 0);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices[0], 0);
    }
}

test "Read s01n3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s01n3p01.png");
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

    expectEq(pngFile.header.width, 1);
    expectEq(pngFile.header.height, 1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 0);
        expectEq(firstColor.B, 255);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0);
        expectEq(secondColor.G, 0);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices[0], 0);
    }
}

test "Read s02i3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s02i3p01.png");
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

    expectEq(pngFile.header.width, 2);
    expectEq(pngFile.header.height, 2);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 255);
        expectEq(firstColor.B, 255);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0);
        expectEq(secondColor.G, 0);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 4);
        expectEq(pixels.Bpp1.indices[0], 0);
        expectEq(pixels.Bpp1.indices[1], 0);
        expectEq(pixels.Bpp1.indices[2], 0);
        expectEq(pixels.Bpp1.indices[3], 0);
    }
}

test "Read s02n3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s02n3p01.png");
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

    expectEq(pngFile.header.width, 2);
    expectEq(pngFile.header.height, 2);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 255);
        expectEq(firstColor.B, 255);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0);
        expectEq(secondColor.G, 0);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 4);
        expectEq(pixels.Bpp1.indices[0], 0);
        expectEq(pixels.Bpp1.indices[1], 0);
        expectEq(pixels.Bpp1.indices[2], 0);
        expectEq(pixels.Bpp1.indices[3], 0);
    }
}

test "Read s03i3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s03i3p01.png");
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

    expectEq(pngFile.header.width, 3);
    expectEq(pngFile.header.height, 3);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 255);
        expectEq(firstColor.B, 0);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0xFF);
        expectEq(secondColor.G, 0x77);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 3 * 3);
        var index: usize = 0;
        while (index < 3 * 3) : (index += 1) {
            if (index == 1 * pngFile.header.width + 1) {
                expectEq(pixels.Bpp1.indices[index], 1);
            } else {
                expectEq(pixels.Bpp1.indices[index], 0);
            }
        }
    }
}

test "Read s03n3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s03n3p01.png");
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

    expectEq(pngFile.header.width, 3);
    expectEq(pngFile.header.height, 3);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 0);
        expectEq(firstColor.G, 255);
        expectEq(firstColor.B, 0);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 0xFF);
        expectEq(secondColor.G, 0x77);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 3 * 3);
        var index: usize = 0;
        while (index < 3 * 3) : (index += 1) {
            if (index == 1 * pngFile.header.width + 1) {
                expectEq(pixels.Bpp1.indices[index], 1);
            } else {
                expectEq(pixels.Bpp1.indices[index], 0);
            }
        }
    }
}

test "Read s04i3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s04i3p01.png");
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

    expectEq(pngFile.header.width, 4);
    expectEq(pngFile.header.height, 4);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 255);
        expectEq(firstColor.G, 0);
        expectEq(firstColor.B, 119);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 255);
        expectEq(secondColor.G, 255);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 4 * 4);

        const expected = [_]u8{
            1, 1, 1, 1,
            1, 0, 0, 1,
            1, 0, 0, 1,
            1, 1, 1, 1,
        };
        var index: usize = 0;
        while (index < 4 * 4) : (index += 1) {
            expectEq(pixels.Bpp1.indices[index], @intCast(u1, expected[index]));
        }
    }
}

test "Read s04n3p01 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s04n3p01.png");
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

    expectEq(pngFile.header.width, 4);
    expectEq(pngFile.header.height, 4);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp1);

        expectEq(pixels.Bpp1.palette.len, 2);

        const firstColor = pixels.Bpp1.palette[0].toIntegerColor8();
        expectEq(firstColor.R, 255);
        expectEq(firstColor.G, 0);
        expectEq(firstColor.B, 119);

        const secondColor = pixels.Bpp1.palette[1].toIntegerColor8();
        expectEq(secondColor.R, 255);
        expectEq(secondColor.G, 255);
        expectEq(secondColor.B, 0);

        expectEq(pixels.Bpp1.indices.len, 4 * 4);

        const expected = [_]u8{
            1, 1, 1, 1,
            1, 0, 0, 1,
            1, 0, 0, 1,
            1, 1, 1, 1,
        };
        var index: usize = 0;
        while (index < 4 * 4) : (index += 1) {
            expectEq(pixels.Bpp1.indices[index], @intCast(u1, expected[index]));
        }
    }
}

test "Read s05i3p02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s05i3p02.png");
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

    expectEq(pngFile.header.width, 5);
    expectEq(pngFile.header.height, 5);

    const total_size = 5 * 5;

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp2);

        expectEq(pixels.Bpp2.palette.len, 4);

        const color0 = pixels.Bpp2.palette[0].toIntegerColor8();
        expectEq(color0.R, 0);
        expectEq(color0.G, 255);
        expectEq(color0.B, 255);

        const color1 = pixels.Bpp2.palette[1].toIntegerColor8();
        expectEq(color1.R, 119);
        expectEq(color1.G, 0);
        expectEq(color1.B, 255);

        const color2 = pixels.Bpp2.palette[2].toIntegerColor8();
        expectEq(color2.R, 255);
        expectEq(color2.G, 0);
        expectEq(color2.B, 0);

        expectEq(pixels.Bpp2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2,
            2, 1, 1, 1, 2,
            2, 1, 0, 1, 2,
            2, 1, 1, 1, 2,
            2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            expectEq(pixels.Bpp2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s05n3p02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s05n3p02.png");
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

    expectEq(pngFile.header.width, 5);
    expectEq(pngFile.header.height, 5);

    const total_size = 5 * 5;

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp2);

        expectEq(pixels.Bpp2.palette.len, 4);

        const color0 = pixels.Bpp2.palette[0].toIntegerColor8();
        expectEq(color0.R, 0);
        expectEq(color0.G, 255);
        expectEq(color0.B, 255);

        const color1 = pixels.Bpp2.palette[1].toIntegerColor8();
        expectEq(color1.R, 119);
        expectEq(color1.G, 0);
        expectEq(color1.B, 255);

        const color2 = pixels.Bpp2.palette[2].toIntegerColor8();
        expectEq(color2.R, 255);
        expectEq(color2.G, 0);
        expectEq(color2.B, 0);

        expectEq(pixels.Bpp2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2,
            2, 1, 1, 1, 2,
            2, 1, 0, 1, 2,
            2, 1, 1, 1, 2,
            2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            expectEq(pixels.Bpp2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s06i3p02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s06i3p02.png");
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

    expectEq(pngFile.header.width, 6);
    expectEq(pngFile.header.height, 6);

    const total_size = 6 * 6;

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp2);

        expectEq(pixels.Bpp2.palette.len, 4);

        const color0 = pixels.Bpp2.palette[0].toIntegerColor8();
        expectEq(color0.R, 0);
        expectEq(color0.G, 255);
        expectEq(color0.B, 0);

        const color1 = pixels.Bpp2.palette[1].toIntegerColor8();
        expectEq(color1.R, 0);
        expectEq(color1.G, 119);
        expectEq(color1.B, 255);

        const color2 = pixels.Bpp2.palette[2].toIntegerColor8();
        expectEq(color2.R, 255);
        expectEq(color2.G, 0);
        expectEq(color2.B, 255);

        expectEq(pixels.Bpp2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2, 2,
            2, 1, 1, 1, 1, 2,
            2, 1, 0, 0, 1, 2,
            2, 1, 0, 0, 1, 2,
            2, 1, 1, 1, 1, 2,
            2, 2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            expectEq(pixels.Bpp2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s06n3p02 data properly" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/png/s06n3p02.png");
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

    expectEq(pngFile.header.width, 6);
    expectEq(pngFile.header.height, 6);

    const total_size = 6 * 6;

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == PixelFormat.Bpp2);

        expectEq(pixels.Bpp2.palette.len, 4);

        const color0 = pixels.Bpp2.palette[0].toIntegerColor8();
        expectEq(color0.R, 0);
        expectEq(color0.G, 255);
        expectEq(color0.B, 0);

        const color1 = pixels.Bpp2.palette[1].toIntegerColor8();
        expectEq(color1.R, 0);
        expectEq(color1.G, 119);
        expectEq(color1.B, 255);

        const color2 = pixels.Bpp2.palette[2].toIntegerColor8();
        expectEq(color2.R, 255);
        expectEq(color2.G, 0);
        expectEq(color2.B, 255);

        expectEq(pixels.Bpp2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2, 2,
            2, 1, 1, 1, 1, 2,
            2, 1, 0, 0, 1, 2,
            2, 1, 0, 0, 1, 2,
            2, 1, 1, 1, 1, 2,
            2, 2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            expectEq(pixels.Bpp2.indices[index], @intCast(u2, expected[index]));
        }
    }
}