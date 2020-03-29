const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const Image = @import("zigimg").Image;
const color = @import("zigimg").color;
const PixelFormat = @import("zigimg").PixelFormat;
usingnamespace @import("helpers.zig");

test "Create Image Bpp1" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Bpp1);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Bpp1);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Bpp1);
        testing.expect(pixels.Bpp1.palette.len == 2);
        testing.expect(pixels.Bpp1.indices.len == 24 * 32);
    }
}

test "Create Image Bpp2" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Bpp2);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Bpp2);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Bpp2);
        testing.expect(pixels.Bpp2.palette.len == 4);
        testing.expect(pixels.Bpp2.indices.len == 24 * 32);
    }
}

test "Create Image Bpp4" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Bpp4);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Bpp4);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Bpp4);
        testing.expect(pixels.Bpp4.palette.len == 16);
        testing.expect(pixels.Bpp4.indices.len == 24 * 32);
    }
}

test "Create Image Bpp8" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Bpp8);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Bpp8);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Bpp8);
        testing.expect(pixels.Bpp8.palette.len == 256);
        testing.expect(pixels.Bpp8.indices.len == 24 * 32);
    }
}

test "Create Image Bpp16" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Bpp16);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Bpp16);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Bpp16);
        testing.expect(pixels.Bpp16.palette.len == 65536);
        testing.expect(pixels.Bpp16.indices.len == 24 * 32);
    }
}

test "Create Image Rgb24" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Rgb24);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Rgb24);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Rgb24);
        testing.expect(pixels.Rgb24.len == 24 * 32);
    }
}

test "Create Image Rgba32" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Rgba32);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Rgba32);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Rgba32);
        testing.expect(pixels.Rgba32.len == 24 * 32);
    }
}

test "Create Image Rgb565" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Rgb565);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Rgb565);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Rgb565);
        testing.expect(pixels.Rgb565.len == 24 * 32);
    }
}

test "Create Image Rgb555" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Rgb555);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Rgb555);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Rgb555);
        testing.expect(pixels.Rgb555.len == 24 * 32);
    }
}

test "Create Image Argb32" {
    const image = try Image.create(zigimg_test_allocator, 24, 32, PixelFormat.Argb32);
    defer image.deinit();

    expectEq(image.width, 24);
    expectEq(image.height, 32);
    expectEq(image.pixel_format, PixelFormat.Argb32);
    testing.expect(image.pixels != null);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Argb32);
        testing.expect(pixels.Argb32.len == 24 * 32);
    }
}

const MemoryRGBABitmap = @embedFile("fixtures/bmp/windows_rgba_v5.bmp");

test "Should detect BMP properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/bmp/simple_v4.bmp",
        "tests/fixtures/bmp/windows_rgba_v5.bmp",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Bmp);
    }
}

test "Should detect PCX properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/pcx/test-bpp1.pcx",
        "tests/fixtures/pcx/test-bpp4.pcx",
        "tests/fixtures/pcx/test-bpp8.pcx",
        "tests/fixtures/pcx/test-bpp24.pcx",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Pcx);
    }
}

test "Should detect PBM properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/netpbm/pbm_ascii.pbm",
        "tests/fixtures/netpbm/pbm_binary.pbm",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Pbm);
    }
}

test "Should detect PGM properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/netpbm/pgm_ascii_grayscale8.pgm",
        "tests/fixtures/netpbm/pgm_binary_grayscale8.pgm",
        "tests/fixtures/netpbm/pgm_ascii_grayscale16.pgm",
        "tests/fixtures/netpbm/pgm_binary_grayscale16.pgm",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Pgm);
    }
}

test "Should detect PPM properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/netpbm/ppm_ascii_rgb24.ppm",
        "tests/fixtures/netpbm/ppm_binary_rgb24.ppm",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Ppm);
    }
}

test "Should detect PNG properly" {
    const imageTests = &[_][]const u8{
        "tests/fixtures/png/basn0g01.png",
        //"tests/fixtures/png/basi0g01.png",
    };

    for (imageTests) |image_path| {
        const image = try Image.fromFilePath(zigimg_test_allocator, image_path);
        defer image.deinit();
        testing.expect(image.image_format == .Png);
    }
}

test "Should error on invalid path" {
    var invalidPath = Image.fromFilePath(zigimg_test_allocator, "notapathdummy");
    expectError(invalidPath, error.FileNotFound);
}

test "Should error on invalid file" {
    var invalidFile = Image.fromFilePath(zigimg_test_allocator, "tests/helpers.zig");
    expectError(invalidFile, error.ImageFormatInvalid);
}

test "Should read a 24-bit bitmap" {
    var image = try Image.fromFilePath(zigimg_test_allocator, "tests/fixtures/bmp/simple_v4.bmp");
    defer image.deinit();

    expectEq(image.width, 8);
    expectEq(image.height, 1);

    if (image.pixels) |pixels| {
        testing.expect(pixels == .Rgb24);

        const red = pixels.Rgb24[0];
        expectEq(red.R, 0xFF);
        expectEq(red.G, 0x00);
        expectEq(red.B, 0x00);

        const green = pixels.Rgb24[1];
        expectEq(green.R, 0x00);
        expectEq(green.G, 0xFF);
        expectEq(green.B, 0x00);

        const blue = pixels.Rgb24[2];
        expectEq(blue.R, 0x00);
        expectEq(blue.G, 0x00);
        expectEq(blue.B, 0xFF);

        const cyan = pixels.Rgb24[3];
        expectEq(cyan.R, 0x00);
        expectEq(cyan.G, 0xFF);
        expectEq(cyan.B, 0xFF);

        const magenta = pixels.Rgb24[4];
        expectEq(magenta.R, 0xFF);
        expectEq(magenta.G, 0x00);
        expectEq(magenta.B, 0xFF);

        const yellow = pixels.Rgb24[5];
        expectEq(yellow.R, 0xFF);
        expectEq(yellow.G, 0xFF);
        expectEq(yellow.B, 0x00);

        const black = pixels.Rgb24[6];
        expectEq(black.R, 0x00);
        expectEq(black.G, 0x00);
        expectEq(black.B, 0x00);

        const white = pixels.Rgb24[7];
        expectEq(white.R, 0xFF);
        expectEq(white.G, 0xFF);
        expectEq(white.B, 0xFF);
    }
}

test "Test Color iterator" {
    var image = try Image.fromFilePath(zigimg_test_allocator, "tests/fixtures/bmp/simple_v4.bmp");
    defer image.deinit();

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

    expectEq(image.width, 8);
    expectEq(image.height, 1);

    var it = image.iterator();
    var i: usize = 0;
    while (it.next()) |actual| {
        const expected = expectedColors[i];
        expectEq(actual.R, expected.R);
        expectEq(actual.G, expected.G);
        expectEq(actual.B, expected.B);
        i += 1;
    }
}
