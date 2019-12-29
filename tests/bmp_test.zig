const bmp = @import("zigimg").bmp;
const HeapAllocator = @import("std").heap.HeapAllocator;
const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const color = @import("zigimg").color;
const errors = @import("zigimg").errors;
usingnamespace @import("helpers.zig");
usingnamespace @import("zigimg").pixel_format;

const MemoryRGBABitmap = @embedFile("fixtures/bmp/windows_rgba_v5.bmp");

var heapAlloc = HeapAllocator.init();
var heap_allocator = &heapAlloc.allocator;

fn verifyBitmapRGBAV5(theBitmap: *bmp.Bitmap) void {
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

    if (theBitmap.pixels) |pixels| {
        expectEq(pixels.len, 240 * 160);

        const firstPixel = pixels[0];
        expectEq(firstPixel.R, 0xFF);
        expectEq(firstPixel.G, 0xFF);
        expectEq(firstPixel.B, 0xFF);
        expectEq(firstPixel.A, 0xFF);

        const secondPixel = pixels[1];
        expectEq(secondPixel.R, 0xFF);
        expectEq(secondPixel.G, 0x00);
        expectEq(secondPixel.B, 0x00);
        expectEq(secondPixel.A, 0xFF);

        const thirdPixel = pixels[2];
        expectEq(thirdPixel.R, 0x00);
        expectEq(thirdPixel.G, 0xFF);
        expectEq(thirdPixel.B, 0x00);
        expectEq(thirdPixel.A, 0xFF);

        const fourthPixel = pixels[3];
        expectEq(fourthPixel.R, 0x00);
        expectEq(fourthPixel.G, 0x00);
        expectEq(fourthPixel.B, 0xFF);
        expectEq(fourthPixel.A, 0xFF);

        const coloredPixel = pixels[(22 * 240) + 16];
        expectEq(coloredPixel.R, 195);
        expectEq(coloredPixel.G, 195);
        expectEq(coloredPixel.B, 255);
        expectEq(coloredPixel.A, 255);
    } else {
        assert(false);
    }
}

test "Init and deinit bitmap should work" {
    var theBitmap = bmp.Bitmap.init(heap_allocator);
    try theBitmap.allocPixels(32);
    theBitmap.deinit();
    expectEq(theBitmap.pixels, null);
}

test "Read simple version 4 24-bit RGB bitmap" {
    var theBitmap = try bmp.Bitmap.fromFile(heap_allocator, "tests/fixtures/bmp/simple_v4.bmp");
    expectEq(theBitmap.width(), 8);
    expectEq(theBitmap.height(), 1);

    defer theBitmap.deinit();
    if (theBitmap.pixels) |pixels| {
        const red = pixels[0];
        expectEq(red.R, 0xFF);
        expectEq(red.G, 0x00);
        expectEq(red.B, 0x00);
        expectEq(red.A, 0xFF);

        const green = pixels[1];
        expectEq(green.R, 0x00);
        expectEq(green.G, 0xFF);
        expectEq(green.B, 0x00);
        expectEq(green.A, 0xFF);

        const blue = pixels[2];
        expectEq(blue.R, 0x00);
        expectEq(blue.G, 0x00);
        expectEq(blue.B, 0xFF);
        expectEq(blue.A, 0xFF);

        const cyan = pixels[3];
        expectEq(cyan.R, 0x00);
        expectEq(cyan.G, 0xFF);
        expectEq(cyan.B, 0xFF);
        expectEq(cyan.A, 0xFF);

        const magenta = pixels[4];
        expectEq(magenta.R, 0xFF);
        expectEq(magenta.G, 0x00);
        expectEq(magenta.B, 0xFF);
        expectEq(magenta.A, 0xFF);

        const yellow = pixels[5];
        expectEq(yellow.R, 0xFF);
        expectEq(yellow.G, 0xFF);
        expectEq(yellow.B, 0x00);
        expectEq(yellow.A, 0xFF);

        const black = pixels[6];
        expectEq(black.R, 0x00);
        expectEq(black.G, 0x00);
        expectEq(black.B, 0x00);
        expectEq(black.A, 0xFF);

        const white = pixels[7];
        expectEq(white.R, 0xFF);
        expectEq(white.G, 0xFF);
        expectEq(white.B, 0xFF);
        expectEq(white.A, 0xFF);
    } else {
        assert(false);
    }
}

test "Read a valid version 5 RGBA bitmap from file" {
    var theBitmap = try bmp.Bitmap.fromFile(heap_allocator, "tests/fixtures/bmp/windows_rgba_v5.bmp");
    defer theBitmap.deinit();
    verifyBitmapRGBAV5(&theBitmap);
}

test "Read a valid version 5 RGBA bitmap from memory" {
    var theBitmap = try bmp.Bitmap.fromMemory(heap_allocator, MemoryRGBABitmap);
    defer theBitmap.deinit();
    verifyBitmapRGBAV5(&theBitmap);
}

test "Should error when reading an invalid file" {
    var invalidFile = bmp.Bitmap.fromFile(heap_allocator, "tests/fixtures/bmp/notbmp.png");
    expectError(invalidFile, errors.ImageError.InvalidMagicHeader);
}

test "Should error on invalid path" {
    var invalidPath = bmp.Bitmap.fromFile(heap_allocator, "notapathdummy");
    expectError(invalidPath, error.FileNotFound);
}
