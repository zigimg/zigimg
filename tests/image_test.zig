const assert = std.debug.assert;
const std = @import("std");
const testing = std.testing;
const Image = @import("../src/image.zig").Image;
const color = @import("../src/color.zig");
const PixelFormat = @import("../src/pixel_format.zig").PixelFormat;
const helpers = @import("helpers.zig");

test "Create Image Indexed1" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Indexed1, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Indexed1);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Indexed1);
        try testing.expect(pixels.Indexed1.palette.len == 2);
        try testing.expect(pixels.Indexed1.indices.len == 24 * 32);
    }
}

test "Create Image Indexed2" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Indexed2, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Indexed2);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Indexed2);
        try testing.expect(pixels.Indexed2.palette.len == 4);
        try testing.expect(pixels.Indexed2.indices.len == 24 * 32);
    }
}

test "Create Image Indexed4" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Indexed4, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Indexed4);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Indexed4);
        try testing.expect(pixels.Indexed4.palette.len == 16);
        try testing.expect(pixels.Indexed4.indices.len == 24 * 32);
    }
}

test "Create Image Indexed8" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Indexed8, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Indexed8);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Indexed8);
        try testing.expect(pixels.Indexed8.palette.len == 256);
        try testing.expect(pixels.Indexed8.indices.len == 24 * 32);
    }
}

test "Create Image Indexed16" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Indexed16, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Indexed16);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Indexed16);
        try testing.expect(pixels.Indexed16.palette.len == 65536);
        try testing.expect(pixels.Indexed16.indices.len == 24 * 32);
    }
}

test "Create Image Rgb24" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Rgb24, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Rgb24);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Rgb24);
        try testing.expect(pixels.Rgb24.len == 24 * 32);
    }
}

test "Create Image Rgba32" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Rgba32, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Rgba32);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Rgba32);
        try testing.expect(pixels.Rgba32.len == 24 * 32);
    }
}

test "Create Image Rgb565" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Rgb565, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Rgb565);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Rgb565);
        try testing.expect(pixels.Rgb565.len == 24 * 32);
    }
}

test "Create Image Rgb555" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Rgb555, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Rgb555);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Rgb555);
        try testing.expect(pixels.Rgb555.len == 24 * 32);
    }
}

test "Create Image Bgra32" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Bgra32, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Bgra32);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Bgra32);
        try testing.expect(pixels.Bgra32.len == 24 * 32);
    }
}

test "Create Image Float32" {
    const test_image = try Image.create(helpers.zigimg_test_allocator, 24, 32, PixelFormat.Float32, .Raw);
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 24);
    try helpers.expectEq(test_image.height, 32);
    try helpers.expectEq(test_image.pixelFormat(), PixelFormat.Float32);
    try testing.expect(test_image.pixels != null);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Float32);
        try testing.expect(pixels.Float32.len == 24 * 32);
    }
}

test "Should detect BMP properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "bmp/simple_v4.bmp",
        helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Bmp);
    }
}

test "Should detect Memory BMP properly" {
    var MemoryRGBABitmap: [200 * 1024]u8 = undefined;
    var buffer = try helpers.testReadFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", MemoryRGBABitmap[0..]);

    const test_image = try Image.fromMemory(helpers.zigimg_test_allocator, buffer);
    defer test_image.deinit();
    try testing.expect(test_image.image_format == .Bmp);
}

test "Should detect PCX properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "pcx/test-bpp1.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp4.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp8.pcx",
        helpers.fixtures_path ++ "pcx/test-bpp24.pcx",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Pcx);
    }
}

test "Should detect PBM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "netpbm/pbm_ascii.pbm",
        helpers.fixtures_path ++ "netpbm/pbm_binary.pbm",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Pbm);
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
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Pgm);
    }
}

test "Should detect PPM properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "netpbm/ppm_ascii_rgb24.ppm",
        helpers.fixtures_path ++ "netpbm/ppm_binary_rgb24.ppm",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Ppm);
    }
}

test "Should detect PNG properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "png/basn0g01.png",
        helpers.fixtures_path ++ "png/basi0g01.png",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Png);
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
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Tga);
    }
}

test "Should detect QOI properly" {
    const image_tests = &[_][]const u8{helpers.fixtures_path ++ "qoi/zero.qoi"};

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Qoi);
    }
}

test "Should detect JPEG properly" {
    const image_tests = &[_][]const u8{
        helpers.fixtures_path ++ "jpeg/tuba.jpg",
        helpers.fixtures_path ++ "jpeg/huff_simple0.jpg",
    };

    for (image_tests) |image_path| {
        const test_image = try helpers.testImageFromFile(image_path);
        defer test_image.deinit();
        try testing.expect(test_image.image_format == .Jpeg);
    }
}

test "Should error on invalid file" {
    var invalidFile = helpers.testImageFromFile("tests/helpers.zig");
    try helpers.expectError(invalidFile, error.ImageFormatInvalid);
}

test "Should read a 24-bit bitmap" {
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer test_image.deinit();

    try helpers.expectEq(test_image.width, 8);
    try helpers.expectEq(test_image.height, 1);

    if (test_image.pixels) |pixels| {
        try testing.expect(pixels == .Bgr24);

        const red = pixels.Bgr24[0];
        try helpers.expectEq(red.R, 0xFF);
        try helpers.expectEq(red.G, 0x00);
        try helpers.expectEq(red.B, 0x00);

        const green = pixels.Bgr24[1];
        try helpers.expectEq(green.R, 0x00);
        try helpers.expectEq(green.G, 0xFF);
        try helpers.expectEq(green.B, 0x00);

        const blue = pixels.Bgr24[2];
        try helpers.expectEq(blue.R, 0x00);
        try helpers.expectEq(blue.G, 0x00);
        try helpers.expectEq(blue.B, 0xFF);

        const cyan = pixels.Bgr24[3];
        try helpers.expectEq(cyan.R, 0x00);
        try helpers.expectEq(cyan.G, 0xFF);
        try helpers.expectEq(cyan.B, 0xFF);

        const magenta = pixels.Bgr24[4];
        try helpers.expectEq(magenta.R, 0xFF);
        try helpers.expectEq(magenta.G, 0x00);
        try helpers.expectEq(magenta.B, 0xFF);

        const yellow = pixels.Bgr24[5];
        try helpers.expectEq(yellow.R, 0xFF);
        try helpers.expectEq(yellow.G, 0xFF);
        try helpers.expectEq(yellow.B, 0x00);

        const black = pixels.Bgr24[6];
        try helpers.expectEq(black.R, 0x00);
        try helpers.expectEq(black.G, 0x00);
        try helpers.expectEq(black.B, 0x00);

        const white = pixels.Bgr24[7];
        try helpers.expectEq(white.R, 0xFF);
        try helpers.expectEq(white.G, 0xFF);
        try helpers.expectEq(white.B, 0xFF);
    }
}

test "Test Color iterator" {
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer test_image.deinit();

    const expectedColors = [_]color.Color{
        color.Color.initRGB(1.0, 0.0, 0.0),
        color.Color.initRGB(0.0, 1.0, 0.0),
        color.Color.initRGB(0.0, 0.0, 1.0),
        color.Color.initRGB(0.0, 1.0, 1.0),
        color.Color.initRGB(1.0, 0.0, 1.0),
        color.Color.initRGB(1.0, 1.0, 0.0),
        color.Color.initRGB(0.0, 0.0, 0.0),
        color.Color.initRGB(1.0, 1.0, 1.0),
    };

    try helpers.expectEq(test_image.width, 8);
    try helpers.expectEq(test_image.height, 1);

    var it = test_image.iterator();
    var i: usize = 0;
    while (it.next()) |actual| {
        const expected = expectedColors[i];
        try helpers.expectEq(actual.R, expected.R);
        try helpers.expectEq(actual.G, expected.G);
        try helpers.expectEq(actual.B, expected.B);
        i += 1;
    }
}

test "Should return a valid byte slice with rawByte()" {
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer test_image.deinit();

    const slice = try test_image.rawBytes();

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
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp");
    defer test_image.deinit();

    const row_size = try test_image.rowByteSize();

    try helpers.expectEq(row_size, 960);
}

test "Should return a valid byte size with imageByteSize()" {
    var test_image = try helpers.testImageFromFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp");
    defer test_image.deinit();

    const image_size = try test_image.imageByteSize();

    try helpers.expectEq(image_size, 153600);
}
