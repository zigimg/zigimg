const ImageInStream = zigimg.ImageInStream;
const ImageSeekStream = zigimg.ImageSeekStream;
const PixelFormat = zigimg.PixelFormat;
const assert = std.debug.assert;
const color = zigimg.color;
const errors = zigimg.errors;
const std = @import("std");
const testing = std.testing;
const netpbm = zigimg.netpbm;
const zigimg = @import("zigimg");
usingnamespace @import("../helpers.zig");

test "Load ASCII PBM image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pbm_ascii.pbm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pbmFile = netpbm.PBM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pbmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pbmFile.header.width, 8);
    expectEq(pbmFile.header.height, 16);
    expectEq(pbmFile.pixel_format, PixelFormat.Grayscale1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale1);

        expectEq(pixels.Grayscale1[0].value, 0);
        expectEq(pixels.Grayscale1[1].value, 1);
        expectEq(pixels.Grayscale1[15 * 8 + 7].value, 1);
    }
}

test "Load binary PBM image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pbm_binary.pbm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pbmFile = netpbm.PBM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pbmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pbmFile.header.width, 8);
    expectEq(pbmFile.header.height, 16);
    expectEq(pbmFile.pixel_format, PixelFormat.Grayscale1);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale1);

        expectEq(pixels.Grayscale1[0].value, 0);
        expectEq(pixels.Grayscale1[1].value, 1);
        expectEq(pixels.Grayscale1[15 * 8 + 7].value, 1);
    }
}

test "Load ASCII PGM 8-bit grayscale image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pgm_ascii_grayscale8.pgm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pgmFile = netpbm.PGM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pgmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pgmFile.header.width, 16);
    expectEq(pgmFile.header.height, 24);
    expectEq(pgmFile.pixel_format, PixelFormat.Grayscale8);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale8);

        expectEq(pixels.Grayscale8[0].value, 2);
        expectEq(pixels.Grayscale8[1].value, 5);
        expectEq(pixels.Grayscale8[383].value, 196);
    }
}

test "Load Binary PGM 8-bit grayscale image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pgm_binary_grayscale8.pgm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pgmFile = netpbm.PGM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pgmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pgmFile.header.width, 16);
    expectEq(pgmFile.header.height, 24);
    expectEq(pgmFile.pixel_format, PixelFormat.Grayscale8);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale8);

        expectEq(pixels.Grayscale8[0].value, 2);
        expectEq(pixels.Grayscale8[1].value, 5);
        expectEq(pixels.Grayscale8[383].value, 196);
    }
}

test "Load ASCII PGM 16-bit grayscale image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pgm_ascii_grayscale16.pgm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pgmFile = netpbm.PGM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pgmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pgmFile.header.width, 8);
    expectEq(pgmFile.header.height, 16);
    expectEq(pgmFile.pixel_format, PixelFormat.Grayscale8);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale8);

        expectEq(pixels.Grayscale8[0].value, 13);
        expectEq(pixels.Grayscale8[1].value, 16);
        expectEq(pixels.Grayscale8[127].value, 237);
    }
}

test "Load Binary PGM 16-bit grayscale image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/pgm_binary_grayscale16.pgm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var pgmFile = netpbm.PGM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try pgmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(pgmFile.header.width, 8);
    expectEq(pgmFile.header.height, 16);
    expectEq(pgmFile.pixel_format, PixelFormat.Grayscale8);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Grayscale8);

        expectEq(pixels.Grayscale8[0].value, 13);
        expectEq(pixels.Grayscale8[1].value, 16);
        expectEq(pixels.Grayscale8[127].value, 237);
    }
}

test "Load ASCII PPM image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/ppm_ascii_rgb24.ppm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var ppmFile = netpbm.PPM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try ppmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(ppmFile.header.width, 27);
    expectEq(ppmFile.header.height, 27);
    expectEq(ppmFile.pixel_format, PixelFormat.Rgb24);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Rgb24);

        expectEq(pixels.Rgb24[0].R, 0x34);
        expectEq(pixels.Rgb24[0].G, 0x53);
        expectEq(pixels.Rgb24[0].B, 0x9f);

        expectEq(pixels.Rgb24[1].R, 0x32);
        expectEq(pixels.Rgb24[1].G, 0x5b);
        expectEq(pixels.Rgb24[1].B, 0x96);

        expectEq(pixels.Rgb24[26].R, 0xa8);
        expectEq(pixels.Rgb24[26].G, 0x5a);
        expectEq(pixels.Rgb24[26].B, 0x78);

        expectEq(pixels.Rgb24[27].R, 0x2e);
        expectEq(pixels.Rgb24[27].G, 0x54);
        expectEq(pixels.Rgb24[27].B, 0x99);

        expectEq(pixels.Rgb24[26 * 27 + 26].R, 0x88);
        expectEq(pixels.Rgb24[26 * 27 + 26].G, 0xb7);
        expectEq(pixels.Rgb24[26 * 27 + 26].B, 0x55);
    }
}

test "Load binary PPM image" {
    const file = try testOpenFile(zigimg_test_allocator, "tests/fixtures/netpbm/ppm_binary_rgb24.ppm");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var ppmFile = netpbm.PPM{};

    var pixelsOpt: ?color.ColorStorage = null;
    try ppmFile.read(zigimg_test_allocator, stream_source.inStream(), stream_source.seekableStream(), &pixelsOpt);

    defer {
        if (pixelsOpt) |pixels| {
            pixels.deinit(zigimg_test_allocator);
        }
    }

    expectEq(ppmFile.header.width, 27);
    expectEq(ppmFile.header.height, 27);
    expectEq(ppmFile.pixel_format, PixelFormat.Rgb24);

    testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        testing.expect(pixels == .Rgb24);

        expectEq(pixels.Rgb24[0].R, 0x34);
        expectEq(pixels.Rgb24[0].G, 0x53);
        expectEq(pixels.Rgb24[0].B, 0x9f);

        expectEq(pixels.Rgb24[1].R, 0x32);
        expectEq(pixels.Rgb24[1].G, 0x5b);
        expectEq(pixels.Rgb24[1].B, 0x96);

        expectEq(pixels.Rgb24[26].R, 0xa8);
        expectEq(pixels.Rgb24[26].G, 0x5a);
        expectEq(pixels.Rgb24[26].B, 0x78);

        expectEq(pixels.Rgb24[27].R, 0x2e);
        expectEq(pixels.Rgb24[27].G, 0x54);
        expectEq(pixels.Rgb24[27].B, 0x99);

        expectEq(pixels.Rgb24[26 * 27 + 26].R, 0x88);
        expectEq(pixels.Rgb24[26 * 27 + 26].G, 0xb7);
        expectEq(pixels.Rgb24[26 * 27 + 26].B, 0x55);
    }
}
