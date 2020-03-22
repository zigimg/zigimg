const ImageInStream = zigimg.ImageInStream;
const ImageSeekStream = zigimg.ImageSeekStream;
const PixelFormat = zigimg.PixelFormat;
const assert = std.debug.assert;
const bmp = zigimg.bmp;
const color = zigimg.color;
const errors = zigimg.errors;
const std = @import("std");
const testing = std.testing;
const zigimg = @import("zigimg");
usingnamespace @import("../helpers.zig");

const MemoryRGBABitmap = @embedFile("../fixtures/bmp/windows_rgba_v5.bmp");

fn verifyBitmapRGBAV5(theBitmap: bmp.Bitmap, pixelsOpt: ?color.ColorStorage) void {
    expectEq(theBitmap.fileHeader.size, 153738);
    expectEq(theBitmap.fileHeader.reserved, 0);
    expectEq(theBitmap.fileHeader.pixelOffset, 138);
    expectEq(theBitmap.width(), 240);
    expectEq(theBitmap.height(), 160);

    expectEqSlice(u8, @tagName(theBitmap.infoHeader), "V5");

    _ = switch (theBitmap.infoHeader) {
        .V5 => |v5Header| {
            expectEq(v5Header.headerSize, bmp.BitmapInfoHeaderV5.HeaderSize);
            expectEq(v5Header.width, 240);
            expectEq(v5Header.height, 160);
            expectEq(v5Header.colorPlane, 1);
            expectEq(v5Header.bitCount, 32);
            expectEq(v5Header.compressionMethod, bmp.CompressionMethod.Bitfields);
            expectEq(v5Header.imageRawSize, 240 * 160 * 4);
            expectEq(v5Header.horizontalResolution, 2835);
            expectEq(v5Header.verticalResolution, 2835);
            expectEq(v5Header.paletteSize, 0);
            expectEq(v5Header.importantColors, 0);
            expectEq(v5Header.redMask, 0x00ff0000);
            expectEq(v5Header.greenMask, 0x0000ff00);
            expectEq(v5Header.blueMask, 0x000000ff);
            expectEq(v5Header.alphaMask, 0xff000000);
            expectEq(v5Header.colorSpace, bmp.BitmapColorSpace.sRgb);
            expectEq(v5Header.cieEndPoints.red.x, 0);
            expectEq(v5Header.cieEndPoints.red.y, 0);
            expectEq(v5Header.cieEndPoints.red.z, 0);
            expectEq(v5Header.cieEndPoints.green.x, 0);
            expectEq(v5Header.cieEndPoints.green.y, 0);
            expectEq(v5Header.cieEndPoints.green.z, 0);
            expectEq(v5Header.cieEndPoints.blue.x, 0);
            expectEq(v5Header.cieEndPoints.blue.y, 0);
            expectEq(v5Header.cieEndPoints.blue.z, 0);
            expectEq(v5Header.gammaRed, 0);
            expectEq(v5Header.gammaGreen, 0);
            expectEq(v5Header.gammaBlue, 0);
            expectEq(v5Header.intent, bmp.BitmapIntent.Graphics);
            expectEq(v5Header.profileData, 0);
            expectEq(v5Header.profileSize, 0);
            expectEq(v5Header.reserved, 0);
        },
        else => unreachable,
    };

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Argb32);

        expectEq(pixels.len(), 240 * 160);

        const firstPixel = pixels.Argb32[0];
        expectEq(firstPixel.R, 0xFF);
        expectEq(firstPixel.G, 0xFF);
        expectEq(firstPixel.B, 0xFF);
        expectEq(firstPixel.A, 0xFF);

        const secondPixel = pixels.Argb32[1];
        expectEq(secondPixel.R, 0xFF);
        expectEq(secondPixel.G, 0x00);
        expectEq(secondPixel.B, 0x00);
        expectEq(secondPixel.A, 0xFF);

        const thirdPixel = pixels.Argb32[2];
        expectEq(thirdPixel.R, 0x00);
        expectEq(thirdPixel.G, 0xFF);
        expectEq(thirdPixel.B, 0x00);
        expectEq(thirdPixel.A, 0xFF);

        const fourthPixel = pixels.Argb32[3];
        expectEq(fourthPixel.R, 0x00);
        expectEq(fourthPixel.G, 0x00);
        expectEq(fourthPixel.B, 0xFF);
        expectEq(fourthPixel.A, 0xFF);

        const coloredPixel = pixels.Argb32[(22 * 240) + 16];
        expectEq(coloredPixel.R, 195);
        expectEq(coloredPixel.G, 195);
        expectEq(coloredPixel.B, 255);
        expectEq(coloredPixel.A, 255);
    }
}

test "Read simple version 4 24-bit RGB bitmap" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/bmp/simple_v4.bmp");
    defer file.close();

    var theBitmap = bmp.Bitmap{};

    var stream_source = std.io.StreamSource{ .file = file };

    var pixelsOpt: ?color.ColorStorage = null;
    try theBitmap.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(theBitmap.width(), 8);
    expectEq(theBitmap.height(), 1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
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

test "Read a valid version 5 RGBA bitmap from file" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/bmp/windows_rgba_v5.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var theBitmap = bmp.Bitmap{};

    var pixelsOpt: ?color.ColorStorage = null;
    try theBitmap.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    verifyBitmapRGBAV5(theBitmap, pixelsOpt);
}

test "Read a valid version 5 RGBA bitmap from memory" {
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(MemoryRGBABitmap) };

    var theBitmap = bmp.Bitmap{};

    var pixelsOpt: ?color.ColorStorage = null;
    try theBitmap.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    verifyBitmapRGBAV5(theBitmap, pixelsOpt);
}

test "Should error when reading an invalid file" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/bmp/notbmp.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var theBitmap = bmp.Bitmap{};

    var pixels: ?color.ColorStorage = null;
    const invalidFile = theBitmap.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixels);
    expectError(invalidFile, errors.ImageError.InvalidMagicHeader);
}
