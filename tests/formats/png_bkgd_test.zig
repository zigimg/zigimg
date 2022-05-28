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

test "Read bgai4a08 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgai4a08.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() == null);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale8Alpha);

        try helpers.expectEq(pixels.grayscale8Alpha[0].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale8Alpha[31].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[31].alpha, 255);

        try helpers.expectEq(pixels.grayscale8Alpha[15 * 32 + 15].value, 131);
        try helpers.expectEq(pixels.grayscale8Alpha[15 * 32 + 15].alpha, 123);

        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].alpha, 255);
    }
}

test "Read bgbn4a08 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgbn4a08.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() != null);

    if (pngFile.getBackgroundColorChunk()) |bkgd_chunk| {
        try testing.expect(bkgd_chunk.color == .grayscale);

        try helpers.expectEq(bkgd_chunk.grayscale, 0);
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale8Alpha);

        try helpers.expectEq(pixels.grayscale8Alpha[0].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale8Alpha[31].value, 255);
        try helpers.expectEq(pixels.grayscale8Alpha[31].alpha, 255);

        try helpers.expectEq(pixels.grayscale8Alpha[15 * 32 + 15].value, 131);
        try helpers.expectEq(pixels.grayscale8Alpha[15 * 32 + 15].alpha, 123);

        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale8Alpha[31 * 32 + 31].alpha, 255);
    }
}

test "Read bgai4a16 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgai4a16.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() == null);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale16Alpha);

        try helpers.expectEq(pixels.grayscale16Alpha[0].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[15 * 32 + 15].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[15 * 32 + 15].alpha, 63421);

        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].alpha, 0);
    }
}

test "Read bggn4a16 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bggn4a16.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() != null);

    if (pngFile.getBackgroundColorChunk()) |bkgd_chunk| {
        try testing.expect(bkgd_chunk.color == .grayscale);

        try helpers.expectEq(bkgd_chunk.grayscale, 43908);
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .grayscale16Alpha);

        try helpers.expectEq(pixels.grayscale16Alpha[0].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[0].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31].alpha, 0);

        try helpers.expectEq(pixels.grayscale16Alpha[15 * 32 + 15].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[15 * 32 + 15].alpha, 63421);

        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].value, 0);
        try helpers.expectEq(pixels.grayscale16Alpha[31 * 32 + 31].alpha, 0);
    }
}

test "Read bgan6a08 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgan6a08.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() == null);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba32);

        try helpers.expectEq(pixels.rgba32[0].R, 255);
        try helpers.expectEq(pixels.rgba32[0].G, 0);
        try helpers.expectEq(pixels.rgba32[0].B, 8);
        try helpers.expectEq(pixels.rgba32[0].A, 0);

        try helpers.expectEq(pixels.rgba32[31].R, 255);
        try helpers.expectEq(pixels.rgba32[31].G, 0);
        try helpers.expectEq(pixels.rgba32[31].B, 8);
        try helpers.expectEq(pixels.rgba32[31].A, 255);

        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].R, 32);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].G, 255);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].B, 4);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].A, 123);

        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].R, 0);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].G, 32);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].B, 255);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].A, 255);
    }
}

test "Read bgwn6a08 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgwn6a08.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() != null);

    if (pngFile.getBackgroundColorChunk()) |bkgd_chunk| {
        try testing.expect(bkgd_chunk.color == .true_color);

        try helpers.expectEq(bkgd_chunk.red, 255);
        try helpers.expectEq(bkgd_chunk.green, 255);
        try helpers.expectEq(bkgd_chunk.blue, 255);
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba32);

        try helpers.expectEq(pixels.rgba32[0].R, 255);
        try helpers.expectEq(pixels.rgba32[0].G, 0);
        try helpers.expectEq(pixels.rgba32[0].B, 8);
        try helpers.expectEq(pixels.rgba32[0].A, 0);

        try helpers.expectEq(pixels.rgba32[31].R, 255);
        try helpers.expectEq(pixels.rgba32[31].G, 0);
        try helpers.expectEq(pixels.rgba32[31].B, 8);
        try helpers.expectEq(pixels.rgba32[31].A, 255);

        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].R, 32);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].G, 255);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].B, 4);
        try helpers.expectEq(pixels.rgba32[15 * 32 + 15].A, 123);

        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].R, 0);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].G, 32);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].B, 255);
        try helpers.expectEq(pixels.rgba32[31 * 32 + 31].A, 255);
    }
}

test "Read bgan6a16 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgan6a16.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() == null);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba64);

        try helpers.expectEq(pixels.rgba64[0].R, 65535);
        try helpers.expectEq(pixels.rgba64[0].G, 65535);
        try helpers.expectEq(pixels.rgba64[0].B, 0);
        try helpers.expectEq(pixels.rgba64[0].A, 0);

        try helpers.expectEq(pixels.rgba64[31].R, 0);
        try helpers.expectEq(pixels.rgba64[31].G, 65535);
        try helpers.expectEq(pixels.rgba64[31].B, 0);
        try helpers.expectEq(pixels.rgba64[31].A, 0);

        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].R, 65535);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].G, 65535);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].B, 0);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].A, 63421);

        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].R, 0);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].G, 0);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].B, 65535);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].A, 0);
    }
}

test "Read bgyn6a16 properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/bgyn6a16.png");
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

    try testing.expect(pngFile.getBackgroundColorChunk() != null);

    if (pngFile.getBackgroundColorChunk()) |bkgd_chunk| {
        try testing.expect(bkgd_chunk.color == .true_color);

        try helpers.expectEq(bkgd_chunk.red, 65535);
        try helpers.expectEq(bkgd_chunk.green, 65535);
        try helpers.expectEq(bkgd_chunk.blue, 0);
    }

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == .rgba64);

        try helpers.expectEq(pixels.rgba64[0].R, 65535);
        try helpers.expectEq(pixels.rgba64[0].G, 65535);
        try helpers.expectEq(pixels.rgba64[0].B, 0);
        try helpers.expectEq(pixels.rgba64[0].A, 0);

        try helpers.expectEq(pixels.rgba64[31].R, 0);
        try helpers.expectEq(pixels.rgba64[31].G, 65535);
        try helpers.expectEq(pixels.rgba64[31].B, 0);
        try helpers.expectEq(pixels.rgba64[31].A, 0);

        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].R, 65535);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].G, 65535);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].B, 0);
        try helpers.expectEq(pixels.rgba64[15 * 32 + 15].A, 63421);

        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].R, 0);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].G, 0);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].B, 65535);
        try helpers.expectEq(pixels.rgba64[31 * 32 + 31].A, 0);
    }
}
