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

test "Read s01i3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s01i3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 1);
    try helpers.expectEq(pngFile.header.height, 1);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 0);
        try helpers.expectEq(firstColor.b, 255);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0);
        try helpers.expectEq(secondColor.g, 0);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices[0], 0);
    }
}

test "Read s01n3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s01n3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 1);
    try helpers.expectEq(pngFile.header.height, 1);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 0);
        try helpers.expectEq(firstColor.b, 255);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0);
        try helpers.expectEq(secondColor.g, 0);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices[0], 0);
    }
}

test "Read s02i3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s02i3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 2);
    try helpers.expectEq(pngFile.header.height, 2);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 255);
        try helpers.expectEq(firstColor.b, 255);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0);
        try helpers.expectEq(secondColor.g, 0);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 4);
        try helpers.expectEq(pixels.indexed1.indices[0], 0);
        try helpers.expectEq(pixels.indexed1.indices[1], 0);
        try helpers.expectEq(pixels.indexed1.indices[2], 0);
        try helpers.expectEq(pixels.indexed1.indices[3], 0);
    }
}

test "Read s02n3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s02n3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 2);
    try helpers.expectEq(pngFile.header.height, 2);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 255);
        try helpers.expectEq(firstColor.b, 255);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0);
        try helpers.expectEq(secondColor.g, 0);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 4);
        try helpers.expectEq(pixels.indexed1.indices[0], 0);
        try helpers.expectEq(pixels.indexed1.indices[1], 0);
        try helpers.expectEq(pixels.indexed1.indices[2], 0);
        try helpers.expectEq(pixels.indexed1.indices[3], 0);
    }
}

test "Read s03i3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s03i3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 3);
    try helpers.expectEq(pngFile.header.height, 3);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 255);
        try helpers.expectEq(firstColor.b, 0);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0xFF);
        try helpers.expectEq(secondColor.g, 0x77);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 3 * 3);
        var index: usize = 0;
        while (index < 3 * 3) : (index += 1) {
            if (index == 1 * pngFile.header.width + 1) {
                try helpers.expectEq(pixels.indexed1.indices[index], 1);
            } else {
                try helpers.expectEq(pixels.indexed1.indices[index], 0);
            }
        }
    }
}

test "Read s03n3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s03n3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 3);
    try helpers.expectEq(pngFile.header.height, 3);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 0);
        try helpers.expectEq(firstColor.g, 255);
        try helpers.expectEq(firstColor.b, 0);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 0xFF);
        try helpers.expectEq(secondColor.g, 0x77);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 3 * 3);
        var index: usize = 0;
        while (index < 3 * 3) : (index += 1) {
            if (index == 1 * pngFile.header.width + 1) {
                try helpers.expectEq(pixels.indexed1.indices[index], 1);
            } else {
                try helpers.expectEq(pixels.indexed1.indices[index], 0);
            }
        }
    }
}

test "Read s04i3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s04i3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 4);
    try helpers.expectEq(pngFile.header.height, 4);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 255);
        try helpers.expectEq(firstColor.g, 0);
        try helpers.expectEq(firstColor.b, 119);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 255);
        try helpers.expectEq(secondColor.g, 255);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 4 * 4);

        const expected = [_]u8{
            1, 1, 1, 1,
            1, 0, 0, 1,
            1, 0, 0, 1,
            1, 1, 1, 1,
        };
        var index: usize = 0;
        while (index < 4 * 4) : (index += 1) {
            try helpers.expectEq(pixels.indexed1.indices[index], @intCast(u1, expected[index]));
        }
    }
}

test "Read s04n3p01 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s04n3p01.png");
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

    try helpers.expectEq(pngFile.header.width, 4);
    try helpers.expectEq(pngFile.header.height, 4);

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed1);

        try helpers.expectEq(pixels.indexed1.palette.len, 2);

        const firstColor = pixels.indexed1.palette[0].toRgba32();
        try helpers.expectEq(firstColor.r, 255);
        try helpers.expectEq(firstColor.g, 0);
        try helpers.expectEq(firstColor.b, 119);

        const secondColor = pixels.indexed1.palette[1].toRgba32();
        try helpers.expectEq(secondColor.r, 255);
        try helpers.expectEq(secondColor.g, 255);
        try helpers.expectEq(secondColor.b, 0);

        try helpers.expectEq(pixels.indexed1.indices.len, 4 * 4);

        const expected = [_]u8{
            1, 1, 1, 1,
            1, 0, 0, 1,
            1, 0, 0, 1,
            1, 1, 1, 1,
        };
        var index: usize = 0;
        while (index < 4 * 4) : (index += 1) {
            try helpers.expectEq(pixels.indexed1.indices[index], @intCast(u1, expected[index]));
        }
    }
}

test "Read s05i3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s05i3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 5);
    try helpers.expectEq(pngFile.header.height, 5);

    const total_size = 5 * 5;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 255);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 119);
        try helpers.expectEq(color1.g, 0);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2,
            2, 1, 1, 1, 2,
            2, 1, 0, 1, 2,
            2, 1, 1, 1, 2,
            2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s05n3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s05n3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 5);
    try helpers.expectEq(pngFile.header.height, 5);

    const total_size = 5 * 5;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 255);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 119);
        try helpers.expectEq(color1.g, 0);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            2, 2, 2, 2, 2,
            2, 1, 1, 1, 2,
            2, 1, 0, 1, 2,
            2, 1, 1, 1, 2,
            2, 2, 2, 2, 2,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s06i3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s06i3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 6);
    try helpers.expectEq(pngFile.header.height, 6);

    const total_size = 6 * 6;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 0);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 119);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 255);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

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
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s06n3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s06n3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 6);
    try helpers.expectEq(pngFile.header.height, 6);

    const total_size = 6 * 6;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 0);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 119);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 255);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

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
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s07i3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s07i3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 7);
    try helpers.expectEq(pngFile.header.height, 7);

    const total_size = 7 * 7;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 255);
        try helpers.expectEq(color0.g, 0);
        try helpers.expectEq(color0.b, 119);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 255);
        try helpers.expectEq(color1.b, 119);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 255);
        try helpers.expectEq(color2.b, 0);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 0);
        try helpers.expectEq(color3.g, 0);
        try helpers.expectEq(color3.b, 255);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            3, 3, 3, 3, 3, 3, 3,
            3, 1, 1, 1, 1, 1, 3,
            3, 1, 2, 2, 2, 1, 3,
            3, 1, 2, 0, 2, 1, 3,
            3, 1, 2, 2, 2, 1, 3,
            3, 1, 1, 1, 1, 1, 3,
            3, 3, 3, 3, 3, 3, 3,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s07n3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s07n3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 7);
    try helpers.expectEq(pngFile.header.height, 7);

    const total_size = 7 * 7;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 255);
        try helpers.expectEq(color0.g, 0);
        try helpers.expectEq(color0.b, 119);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 255);
        try helpers.expectEq(color1.b, 119);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 255);
        try helpers.expectEq(color2.b, 0);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 0);
        try helpers.expectEq(color3.g, 0);
        try helpers.expectEq(color3.b, 255);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            3, 3, 3, 3, 3, 3, 3,
            3, 1, 1, 1, 1, 1, 3,
            3, 1, 2, 2, 2, 1, 3,
            3, 1, 2, 0, 2, 1, 3,
            3, 1, 2, 2, 2, 1, 3,
            3, 1, 1, 1, 1, 1, 3,
            3, 3, 3, 3, 3, 3, 3,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s08i3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s08i3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 8);
    try helpers.expectEq(pngFile.header.height, 8);

    const total_size = 8 * 8;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 255);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 119);
        try helpers.expectEq(color1.g, 0);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 119);
        try helpers.expectEq(color2.g, 255);
        try helpers.expectEq(color2.b, 0);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 255);
        try helpers.expectEq(color3.g, 0);
        try helpers.expectEq(color3.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 2, 2, 2, 2, 2, 2, 0,
            0, 2, 3, 3, 3, 3, 2, 0,
            0, 2, 3, 1, 1, 3, 2, 0,
            0, 2, 3, 1, 1, 3, 2, 0,
            0, 2, 3, 3, 3, 3, 2, 0,
            0, 2, 2, 2, 2, 2, 2, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s08n3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s08n3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 8);
    try helpers.expectEq(pngFile.header.height, 8);

    const total_size = 8 * 8;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 255);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 119);
        try helpers.expectEq(color1.g, 0);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 119);
        try helpers.expectEq(color2.g, 255);
        try helpers.expectEq(color2.b, 0);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 255);
        try helpers.expectEq(color3.g, 0);
        try helpers.expectEq(color3.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 2, 2, 2, 2, 2, 2, 0,
            0, 2, 3, 3, 3, 3, 2, 0,
            0, 2, 3, 1, 1, 3, 2, 0,
            0, 2, 3, 1, 1, 3, 2, 0,
            0, 2, 3, 3, 3, 3, 2, 0,
            0, 2, 2, 2, 2, 2, 2, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s09i3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s09i3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 9);
    try helpers.expectEq(pngFile.header.height, 9);

    const total_size = 9 * 9;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 0);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 119);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 255);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 255);
        try helpers.expectEq(color3.g, 119);
        try helpers.expectEq(color3.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 3, 3, 3, 3, 3, 3, 3, 0,
            0, 3, 2, 2, 2, 2, 2, 3, 0,
            0, 3, 2, 1, 1, 1, 2, 3, 0,
            0, 3, 2, 1, 0, 1, 2, 3, 0,
            0, 3, 2, 1, 1, 1, 2, 3, 0,
            0, 3, 2, 2, 2, 2, 2, 3, 0,
            0, 3, 3, 3, 3, 3, 3, 3, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s09n3p02 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s09n3p02.png");
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

    try helpers.expectEq(pngFile.header.width, 9);
    try helpers.expectEq(pngFile.header.height, 9);

    const total_size = 9 * 9;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed2);

        try helpers.expectEq(pixels.indexed2.palette.len, 4);

        const color0 = pixels.indexed2.palette[0].toRgba32();
        try helpers.expectEq(color0.r, 0);
        try helpers.expectEq(color0.g, 255);
        try helpers.expectEq(color0.b, 0);

        const color1 = pixels.indexed2.palette[1].toRgba32();
        try helpers.expectEq(color1.r, 0);
        try helpers.expectEq(color1.g, 119);
        try helpers.expectEq(color1.b, 255);

        const color2 = pixels.indexed2.palette[2].toRgba32();
        try helpers.expectEq(color2.r, 255);
        try helpers.expectEq(color2.g, 0);
        try helpers.expectEq(color2.b, 255);

        const color3 = pixels.indexed2.palette[3].toRgba32();
        try helpers.expectEq(color3.r, 255);
        try helpers.expectEq(color3.g, 119);
        try helpers.expectEq(color3.b, 0);

        try helpers.expectEq(pixels.indexed2.indices.len, total_size);

        const expected = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 3, 3, 3, 3, 3, 3, 3, 0,
            0, 3, 2, 2, 2, 2, 2, 3, 0,
            0, 3, 2, 1, 1, 1, 2, 3, 0,
            0, 3, 2, 1, 0, 1, 2, 3, 0,
            0, 3, 2, 1, 1, 1, 2, 3, 0,
            0, 3, 2, 2, 2, 2, 2, 3, 0,
            0, 3, 3, 3, 3, 3, 3, 3, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
        };
        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed2.indices[index], @intCast(u2, expected[index]));
        }
    }
}

test "Read s32i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s32i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 32);
    try helpers.expectEq(pngFile.header.height, 32);

    const total_size = 32 * 32;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 0, 0, 0,  0,  0, 0, 0, 0, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 11, 10, 6, 3, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  0, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 0, 0, 0,  10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s32n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s32n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 32);
    try helpers.expectEq(pngFile.header.height, 32);

    const total_size = 32 * 32;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 0, 0, 0,  0,  0, 0, 0, 0, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 11, 10, 6, 3, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  0, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 0, 0, 0,  10, 6, 3, 9, 2, 5,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s33i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s33i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 33);
    try helpers.expectEq(pngFile.header.height, 33);

    const total_size = 33 * 33;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  0,  0,  0,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  2,  2,  2,  2,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  0,  12, 12,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s33n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s33n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 33);
    try helpers.expectEq(pngFile.header.height, 33);

    const total_size = 33 * 33;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  0,  0,  0,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  2,  2,  2,  2,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  0,  12, 12,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s34i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s34i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 34);
    try helpers.expectEq(pngFile.header.height, 34);

    const total_size = 34 * 34;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  0, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 0, 0, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 0, 0, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s34n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s34n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 34);
    try helpers.expectEq(pngFile.header.height, 34);

    const total_size = 34 * 34;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  0, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 0,  0,  6, 3, 9, 2, 5, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 0, 0, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 0, 0,  0,  0, 0, 0, 0, 0, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s35i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s35i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 35);
    try helpers.expectEq(pngFile.header.height, 35);

    const total_size = 35 * 35;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  0,  0,  0,  0,  12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  11, 0,  0,  0,  0,  0,  0,  11,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  0,  0,  6,  6,  6,  0,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  5,  5,  5,  5,  5,  5,  0,  0,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 0,  0,  0,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  0,  0,  0,  7,  7,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s35n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s35n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 35);
    try helpers.expectEq(pngFile.header.height, 35);

    const total_size = 35 * 35;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  0,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  0,  0,  0,  0,  12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  11, 0,  0,  0,  0,  0,  0,  11,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  0,  0,  6,  6,  6,  0,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  5,  5,  5,  5,  5,  5,  0,  0,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 0,  0,  0,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  0,  0,  0,  7,  7,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s36i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s36i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 36);
    try helpers.expectEq(pngFile.header.height, 36);

    const total_size = 36 * 36;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 0, 0,  0, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 0, 0, 0, 0,  0, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 0, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 0, 0,  0, 7, 1,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s36n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s36n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 36);
    try helpers.expectEq(pngFile.header.height, 36);

    const total_size = 36 * 36;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 0, 0,  0, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 0, 0, 0, 0,  0, 7, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 0, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 0,  0, 0, 9, 2, 5, 12, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 0, 0, 0, 0, 0, 0,  0, 0, 1,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 0, 0,  0, 7, 1,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s37i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s37i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 37);
    try helpers.expectEq(pngFile.header.height, 37);

    const total_size = 37 * 37;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  10,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  0,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  0,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  1,  1,  1,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s37n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s37n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 37);
    try helpers.expectEq(pngFile.header.height, 37);

    const total_size = 37 * 37;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  10,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  0,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  0,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  1,  1,  1,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s38i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s38i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 38);
    try helpers.expectEq(pngFile.header.height, 38);

    const total_size = 38 * 38;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 0, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 0, 8, 11,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s38n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s38n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 38);
    try helpers.expectEq(pngFile.header.height, 38);

    const total_size = 38 * 38;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  10, 6, 3, 9, 2, 5, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            0, 0,  0,  6, 3, 9, 2, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 0,  0,  0, 0, 0, 0, 0, 0,  4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 0,  0, 0, 0, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 0, 8, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 0, 0, 0, 5, 12, 4, 7, 0, 0, 0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 0, 0, 0, 0,  0, 0, 0, 0, 11,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 0, 8, 11,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s39i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s39i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 39);
    try helpers.expectEq(pngFile.header.height, 39);

    const total_size = 39 * 39;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  0,  0,  0,  0,  0,  0,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  10, 10, 10, 10, 10, 10, 0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  6,  6,  6,  6,  6,  6,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  2,  2,  2,  0,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  12, 0,  0,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  0,  0,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  0,  8,  8,  8,  8,  0,  0,  0,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,  0,  0,  0,  0,  0,  11,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  0,  0,  0,  0,  10, 10,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s39n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s39n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 39);
    try helpers.expectEq(pngFile.header.height, 39);

    const total_size = 39 * 39;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 10, 10, 10, 10, 10, 0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  6,  6,  6,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  0,  0,  0,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  0,  0,  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  0,  0,  5,  5,  0,  0,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  0,  0,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
            0,  0,  8,  8,  8,  8,  8,  8,  0,  0,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
            0,  0,  0,  11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            10, 0,  0,  0,  0,  0,  0,  0,  0,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            6,  6,  0,  0,  0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  1,  1,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  0,  0,  0,  0,  0,  0,  8,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,  11, 11, 11, 11, 0,  0,  0,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  10, 10, 10, 10, 10, 10, 0,  0,
            6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  0,  0,  6,  6,  6,  6,  6,  6,  0,  0,
            3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,  3,  3,  3,  3,  3,  3,  0,  0,
            9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  0,  0,  9,  9,  9,  9,  9,  9,  0,  0,
            2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  0,  0,  0,  2,  2,  2,  0,  0,  0,  0,
            5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  0,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0,  0,  0,  0,  0,  12, 0,  0,
            4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,
            7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  0,  0,
            1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  1,  1,  1,  1,  0,  0,
            8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  0,  0,  0,  8,  8,  8,  8,  0,  0,  0,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 0,  0,  0,  0,  0,  0,  0,  0,  11,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 0,  0,  0,  0,  0,  0,  10, 10,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s40i3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s40i3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 40);
    try helpers.expectEq(pngFile.header.height, 40);

    const total_size = 40 * 40;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 0, 0, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 0,  0, 0, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 0,  0,  0, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 0,  0,  6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 0, 0, 0, 0,  10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 0, 0, 0, 0,  0,  6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 0, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 0, 0, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 0, 0, 0, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 0, 0, 0, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 0, 0, 0, 0,  0,  6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 0, 0, 0, 0,  10, 6,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}

test "Read s40n3p04 data properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/s40n3p04.png");
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

    try helpers.expectEq(pngFile.header.width, 40);
    try helpers.expectEq(pngFile.header.height, 40);

    const total_size = 40 * 40;

    try testing.expect(pixelsOpt != null);

    if (pixelsOpt) |pixels| {
        try testing.expect(pixels == PixelFormat.indexed4);

        try helpers.expectEq(pixels.indexed4.palette.len, 16);

        const palette = [_]u32{
            0x000000ff,
            0xff0077ff,
            0x00ffffff,
            0x00ff00ff,
            0x7700ffff,
            0x0077ffff,
            0x77ff00ff,
            0xff00ffff,
            0xff0000ff,
            0x00ff77ff,
            0xffff00ff,
            0xff7700ff,
            0x0000ffff,
        };

        for (palette) |expected, i| {
            try helpers.expectEq(pixels.indexed4.palette[i].toU32Rgba(), expected);
        }

        try helpers.expectEq(pixels.indexed4.indices.len, total_size);

        const expected = [_]u8{
            8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 0, 0, 0, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 0, 0, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 0,  0, 0, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 0,  0, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 0,  0,  0, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 0,  0,  6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            0, 0,  0,  0, 0, 0, 0, 0, 0,  0, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 0, 0, 0, 0,  10, 6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 0, 0, 0, 0,  0,  6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 0, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 0, 0, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 0, 0, 0, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 0, 0, 0, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 0, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  0, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 12, 4, 7, 1, 8, 11, 0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 0, 0, 0,  4, 7, 1, 8, 0,  0,  0,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 0, 0,  0, 0, 0, 0, 0,  0,  6,
            8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 12, 4, 7, 1, 8, 11, 10, 6, 3, 9, 2, 5, 0,  0, 0, 0, 0, 0,  10, 6,
        };

        try helpers.expectEq(pixels.indexed4.indices.len, expected.len);

        var index: usize = 0;
        while (index < total_size) : (index += 1) {
            try helpers.expectEq(pixels.indexed4.indices[index], @intCast(u4, expected[index]));
        }
    }
}
