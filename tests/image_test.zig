const std = @import("std");
const Image = zigimg.Image;
const color = zigimg.color;
const Colors = zigimg.Colors;
const PixelFormat = zigimg.PixelFormat;
const zigimg = @import("zigimg");
const helpers = @import("helpers.zig");

test "Create Image indexed1" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.indexed1);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.indexed1);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .indexed1);
    try std.testing.expect(pixels.indexed1.palette.len == 2);
    try std.testing.expect(pixels.indexed1.indices.len == 24 * 32);
}

test "Create Image indexed2" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.indexed2);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.indexed2);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .indexed2);
    try std.testing.expect(pixels.indexed2.palette.len == 4);
    try std.testing.expect(pixels.indexed2.indices.len == 24 * 32);
}

test "Create Image indexed4" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.indexed4);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.indexed4);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .indexed4);
    try std.testing.expect(pixels.indexed4.palette.len == 16);
    try std.testing.expect(pixels.indexed4.indices.len == 24 * 32);
}

test "Create Image indexed8" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.indexed8);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.indexed8);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .indexed8);
    try std.testing.expect(pixels.indexed8.palette.len == 256);
    try std.testing.expect(pixels.indexed8.indices.len == 24 * 32);
}

test "Create Image indexed16" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.indexed16);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.indexed16);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .indexed16);
    try std.testing.expect(pixels.indexed16.palette.len == 65536);
    try std.testing.expect(pixels.indexed16.indices.len == 24 * 32);
}

test "Create Image Rgb24" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb24);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgb24);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgb24);
    try std.testing.expect(pixels.rgb24.len == 24 * 32);
}

test "Create Image Rgba32" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgba32);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgba32);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgba32);
    try std.testing.expect(pixels.rgba32.len == 24 * 32);
}

test "Create Image Rgb332" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb332);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgb332);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgb332);
    try std.testing.expect(pixels.rgb332.len == 24 * 32);
}

test "Create Image Rgb565" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb565);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgb565);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgb565);
    try std.testing.expect(pixels.rgb565.len == 24 * 32);
}

test "Create Image Rgb555" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb555);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgb555);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgb555);
    try std.testing.expect(pixels.rgb555.len == 24 * 32);
}

test "Create Image Bgra32" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.bgra32);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.bgra32);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .bgra32);
    try std.testing.expect(pixels.bgra32.len == 24 * 32);
}

test "Create Image float32" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.float32);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.float32);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .float32);
    try std.testing.expect(pixels.float32.len == 24 * 32);
}

test "Should detect BMP properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "bmp/simple_v4.bmp",
        helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .bmp);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect Memory BMP properly" {
    var MemoryRGBABitmap: [200 * 1024]u8 = undefined;
    const buffer = try helpers.testReadFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", MemoryRGBABitmap[0..]);

    const format = try Image.detectFormatFromMemory(buffer);
    try std.testing.expect(format == .bmp);

    var test_image = try Image.fromMemory(helpers.zigimg_test_allocator, buffer);
    defer test_image.deinit(helpers.zigimg_test_allocator);
}

test "Should detect GIF properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "gif/depth1.gif",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .gif);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect PCX properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "pcx/test-bpp1.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp4.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp8.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp24.pcx",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .pcx);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect PBM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "netpbm/pbm_ascii.pbm",
        helpers.fixtures_path ++ "netpbm/pbm_binary.pbm",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .pbm);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect PGM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "netpbm/pgm_ascii_grayscale8.pgm",
        helpers.fixtures_path ++ "netpbm/pgm_binary_grayscale8.pgm",
        helpers.fixtures_path ++ "netpbm/pgm_ascii_grayscale16.pgm",
        helpers.fixtures_path ++ "netpbm/pgm_binary_grayscale16.pgm",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .pgm);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect PPM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "netpbm/ppm_ascii_rgb24.ppm",
        helpers.fixtures_path ++ "netpbm/ppm_binary_rgb24.ppm",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .ppm);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect PNG properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "png/basn0g01.png",
        helpers.fixtures_path ++ "png/basi0g01.png",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .png);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect TGA properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "tga/cbw8.tga",
        helpers.fixtures_path ++ "tga/ccm8.tga",
        helpers.fixtures_path ++ "tga/ctc24.tga",
        helpers.fixtures_path ++ "tga/ubw8.tga",
        helpers.fixtures_path ++ "tga/ucm8.tga",
        helpers.fixtures_path ++ "tga/utc16.tga",
        helpers.fixtures_path ++ "tga/utc24.tga",
        helpers.fixtures_path ++ "tga/utc32.tga",
        helpers.fixtures_path ++ "tga/stopsignsmall.tga",
        helpers.fixtures_path ++ "tga/stopsignsmallcompressed.tga",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .tga);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect QOI properly" {
    const image_tests = &[_][]const u8{helpers.fixtures_path ++ "qoi/zero.qoi"};

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .qoi);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect JPEG properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "jpeg/tuba.jpg",
        helpers.fixtures_path ++ "jpeg/huff_simple0.jpg",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .jpeg);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect Farbfeld properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "farbfeld/dragon.ff",
        helpers.fixtures_path ++ "farbfeld/yellow-1x1-semitransparent.png.ff",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .farbfeld);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect IFF/PBM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "ilbm/sample-pbm.iff",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .iff);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect RAS properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "ras/sample-rgb24.ras",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .ras);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect SGI properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "sgi/sample-rgb24.sgi",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .sgi);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect TIFF properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "tiff/sample-monob-raw.tiff",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .tiff);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should detect XBM properly" {
    const image_tests = &[_][]const u8{
        // good files
        helpers.fixtures_path ++ "xbm/fancyclock.xbm",
        helpers.fixtures_path ++ "xbm/penguin.xbm",
        helpers.fixtures_path ++ "xbm/blarg.xbm",

        // good but malformed files
        helpers.fixtures_path ++ "xbm/no_labels.xbm",
        helpers.fixtures_path ++ "xbm/missing_array_var.xbm",
        helpers.fixtures_path ++ "xbm/no_trailing.xbm",
    };

    for (image_tests) |image_path| {
        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        const format = try Image.detectFormatFromFilePath(image_path, read_buffer[0..]);
        try std.testing.expect(format == .xbm);

        var test_image = try helpers.testImageFromFile(image_path, read_buffer[0..]);
        defer test_image.deinit(helpers.zigimg_test_allocator);
    }
}

test "Should error on invalid file" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    const invalidFile = helpers.testImageFromFile("tests/helpers.zig", read_buffer[0..]);
    try helpers.expectError(invalidFile, Image.Error.Unsupported);
}

test "Should read a 24-bit bitmap" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 8);
    try helpers.expectEq(test_image.height, 1);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .bgr24);

    const red = pixels.bgr24[0];
    try helpers.expectEq(red.r, 0xFF);
    try helpers.expectEq(red.g, 0x00);
    try helpers.expectEq(red.b, 0x00);

    const green = pixels.bgr24[1];
    try helpers.expectEq(green.r, 0x00);
    try helpers.expectEq(green.g, 0xFF);
    try helpers.expectEq(green.b, 0x00);

    const blue = pixels.bgr24[2];
    try helpers.expectEq(blue.r, 0x00);
    try helpers.expectEq(blue.g, 0x00);
    try helpers.expectEq(blue.b, 0xFF);

    const cyan = pixels.bgr24[3];
    try helpers.expectEq(cyan.r, 0x00);
    try helpers.expectEq(cyan.g, 0xFF);
    try helpers.expectEq(cyan.b, 0xFF);

    const magenta = pixels.bgr24[4];
    try helpers.expectEq(magenta.r, 0xFF);
    try helpers.expectEq(magenta.g, 0x00);
    try helpers.expectEq(magenta.b, 0xFF);

    const yellow = pixels.bgr24[5];
    try helpers.expectEq(yellow.r, 0xFF);
    try helpers.expectEq(yellow.g, 0xFF);
    try helpers.expectEq(yellow.b, 0x00);

    const black = pixels.bgr24[6];
    try helpers.expectEq(black.r, 0x00);
    try helpers.expectEq(black.g, 0x00);
    try helpers.expectEq(black.b, 0x00);

    const white = pixels.bgr24[7];
    try helpers.expectEq(white.r, 0xFF);
    try helpers.expectEq(white.g, 0xFF);
    try helpers.expectEq(white.b, 0xFF);
}

test "Test Colorf32 iterator" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    const expectedColors = [_]color.Colorf32{
        color.Colorf32.from.rgb(1.0, 0.0, 0.0),
        color.Colorf32.from.rgb(0.0, 1.0, 0.0),
        color.Colorf32.from.rgb(0.0, 0.0, 1.0),
        color.Colorf32.from.rgb(0.0, 1.0, 1.0),
        color.Colorf32.from.rgb(1.0, 0.0, 1.0),
        color.Colorf32.from.rgb(1.0, 1.0, 0.0),
        color.Colorf32.from.rgb(0.0, 0.0, 0.0),
        color.Colorf32.from.rgb(1.0, 1.0, 1.0),
    };

    try helpers.expectEq(test_image.width, 8);
    try helpers.expectEq(test_image.height, 1);

    var it = test_image.iterator();
    var i: usize = 0;
    while (it.next()) |actual| {
        const expected = expectedColors[i];
        try helpers.expectEq(actual.r, expected.r);
        try helpers.expectEq(actual.g, expected.g);
        try helpers.expectEq(actual.b, expected.b);
        i += 1;
    }
}

test "Convert Image from rgb24 to float32 (Colorf32)" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    const expected_colors = [_]color.Colorf32{
        color.Colorf32.from.rgb(1.0, 0.0, 0.0),
        color.Colorf32.from.rgb(0.0, 1.0, 0.0),
        color.Colorf32.from.rgb(0.0, 0.0, 1.0),
        color.Colorf32.from.rgb(0.0, 1.0, 1.0),
        color.Colorf32.from.rgb(1.0, 0.0, 1.0),
        color.Colorf32.from.rgb(1.0, 1.0, 0.0),
        color.Colorf32.from.rgb(0.0, 0.0, 0.0),
        color.Colorf32.from.rgb(1.0, 1.0, 1.0),
    };

    try helpers.expectEq(test_image.width, 8);
    try helpers.expectEq(test_image.height, 1);

    try test_image.convert(helpers.zigimg_test_allocator, .float32);

    for (0..expected_colors.len) |index| {
        const actual = test_image.pixels.float32[index];
        const expected = expected_colors[index];

        try helpers.expectEq(actual.r, expected.r);
        try helpers.expectEq(actual.g, expected.g);
        try helpers.expectEq(actual.b, expected.b);
    }
}

test "Should return a valid byte slice with rawByte()" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    const slice = test_image.rawBytes();

    try helpers.expectEq(slice.len, 24);
    try helpers.expectEqSlice(u8, slice, &[_]u8{
        0,
        0,
        255,
        0,
        255,
        0,
        255,
        0,
        0,
        255,
        255,
        0,
        255,
        0,
        255,
        0,
        255,
        255,
        0,
        0,
        0,
        255,
        255,
        255,
    });
}

test "Should return a valid row size with rowByteSize()" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    const row_size = test_image.rowByteSize();

    try helpers.expectEq(row_size, 960);
}

test "Should return a valid byte size with imageByteSize()" {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", read_buffer[0..]);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    const image_size = test_image.imageByteSize();

    try helpers.expectEq(image_size, 153600);
}

test "Should import raw pixels and take ownership of the pixel data" {
    const color_data: []const color.Rgb24 = &.{
        Colors(color.Rgb24).Red,
        Colors(color.Rgb24).Green,
        Colors(color.Rgb24).Blue,
        Colors(color.Rgb24).Cyan,
        Colors(color.Rgb24).Magenta,
        Colors(color.Rgb24).Yellow,
        Colors(color.Rgb24).Black,
        Colors(color.Rgb24).White,
    };

    const pixel_data = std.mem.sliceAsBytes(color_data);
    const image = try Image.fromRawPixelsOwned(8, 1, pixel_data, .rgb24);

    try helpers.expectEq(std.meta.activeTag(image.pixels), .rgb24);
    try helpers.expectEq(image.width, 8);
    try helpers.expectEq(image.height, 1);

    try helpers.expectEq(image.pixels.rgb24[0], Colors(color.Rgb24).Red);
    try helpers.expectEq(image.pixels.rgb24[1], Colors(color.Rgb24).Green);
    try helpers.expectEq(image.pixels.rgb24[2], Colors(color.Rgb24).Blue);
    try helpers.expectEq(image.pixels.rgb24[3], Colors(color.Rgb24).Cyan);
    try helpers.expectEq(image.pixels.rgb24[4], Colors(color.Rgb24).Magenta);
    try helpers.expectEq(image.pixels.rgb24[5], Colors(color.Rgb24).Yellow);
    try helpers.expectEq(image.pixels.rgb24[6], Colors(color.Rgb24).Black);
    try helpers.expectEq(image.pixels.rgb24[7], Colors(color.Rgb24).White);
}

test "Should import raw pixels and create a copy of pixel data" {
    const color_data: []const color.Rgb24 = &.{
        Colors(color.Rgb24).Red,
        Colors(color.Rgb24).Green,
        Colors(color.Rgb24).Blue,
        Colors(color.Rgb24).Cyan,
        Colors(color.Rgb24).Magenta,
        Colors(color.Rgb24).Yellow,
        Colors(color.Rgb24).Black,
        Colors(color.Rgb24).White,
    };

    const pixel_data = std.mem.sliceAsBytes(color_data);
    var image = try Image.fromRawPixels(helpers.zigimg_test_allocator, 8, 1, pixel_data, .rgb24);
    defer image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(std.meta.activeTag(image.pixels), .rgb24);
    try helpers.expectEq(image.width, 8);
    try helpers.expectEq(image.height, 1);

    try helpers.expectEq(image.pixels.rgb24[0], Colors(color.Rgb24).Red);
    try helpers.expectEq(image.pixels.rgb24[1], Colors(color.Rgb24).Green);
    try helpers.expectEq(image.pixels.rgb24[2], Colors(color.Rgb24).Blue);
    try helpers.expectEq(image.pixels.rgb24[3], Colors(color.Rgb24).Cyan);
    try helpers.expectEq(image.pixels.rgb24[4], Colors(color.Rgb24).Magenta);
    try helpers.expectEq(image.pixels.rgb24[5], Colors(color.Rgb24).Yellow);
    try helpers.expectEq(image.pixels.rgb24[6], Colors(color.Rgb24).Black);
    try helpers.expectEq(image.pixels.rgb24[7], Colors(color.Rgb24).White);
}

test "Image to Managed" {
    var test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb24);
    defer test_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.rgb24);

    const pixels = test_image.pixels;

    try std.testing.expect(pixels == .rgb24);
    try std.testing.expect(pixels.rgb24.len == 24 * 32);

    var managed_image = test_image.toManaged(helpers.zigimg_test_allocator);

    try helpers.expectEq(managed_image.width, 24);
    try helpers.expectEq(managed_image.height, 32);
    try helpers.expectEq(managed_image.pixelFormat(), PixelFormat.rgb24);

    const managed_pixels = managed_image.pixels;

    try std.testing.expect(managed_pixels == .rgb24);
    try std.testing.expect(managed_pixels.rgb24.len == 24 * 32);
}

test "Managed to Image" {
    var managed_image = try Image.Managed.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.rgb24);
    defer managed_image.deinit();

    try helpers.expectEq(managed_image.width, 24);
    try helpers.expectEq(managed_image.height, 32);
    try helpers.expectEq(managed_image.pixelFormat(), PixelFormat.rgb24);

    const pixels = managed_image.pixels;

    try std.testing.expect(pixels == .rgb24);
    try std.testing.expect(pixels.rgb24.len == 24 * 32);

    var image = managed_image.toUnmanaged();

    try helpers.expectEq(image.width, 24);
    try helpers.expectEq(image.height, 32);
    try helpers.expectEq(image.pixelFormat(), PixelFormat.rgb24);

    const managed_pixels = image.pixels;

    try std.testing.expect(managed_pixels == .rgb24);
    try std.testing.expect(managed_pixels.rgb24.len == 24 * 32);
}
