const helpers = @import("../helpers.zig");
const std = @import("std");
const tiff = zigimg.formats.tiff;
const zigimg = @import("zigimg");

test "Should error on non TIFF images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var sgi_file = tiff.TIFF{};

    const invalid_file = sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    try helpers.expectError(invalid_file, zigimg.Image.ReadError.InvalidData);
}

test "TIFF/LE monochrome black uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 640);
    try helpers.expectEq(the_tiff.height(), 426);
    try std.testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[2].value, 0);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 0);
}

test "TIFF/LE grayscale8 uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-grayscale8-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[0].value, 76);
    try helpers.expectEq(pixels.grayscale8[8].value, 149);
    try helpers.expectEq(pixels.grayscale8[90].value, 0);
    try helpers.expectEq(pixels.grayscale8[128 * 66 + 72].value, 149);
}

test "TIFF/LE 8-bit with colormap uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-pal8-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .indexed8);

    const palette64 = pixels.indexed8.palette[64];

    try helpers.expectEq(palette64.r, 255);
    try helpers.expectEq(palette64.g, 0);
    try helpers.expectEq(palette64.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[0], 64);
    try helpers.expectEq(pixels.indexed8.indices[12], 128);
}

test "TIFF/LE 24-bit uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 664);
    try helpers.expectEq(the_tiff.height(), 248);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/BE rgb24 gray single strip uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/big-endian/sample-rgb24-single-strip.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 0, 12, 24 };
    const expected_colors = [_]u32{
        0x4c4c4c,
        0x959595,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/BE rgb24 color single strip uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/big-endian/sample-pal8-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 0, 12, 24 };
    const expected_colors = [_]u32{
        0xff021d,
        0xff37,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/BE 24-bit uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/big-endian/sample-rgb24-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 664);
    try helpers.expectEq(the_tiff.height(), 248);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE RGBA uncompressed" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgba-raw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 32);
    try helpers.expectEq(the_tiff.height(), 32);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 100, 1000, 1018 };
    const expected_colors = [_]u32{ 0xf6ff00, 0xbe0042, 0x2900d7 };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE monochrome black packbits" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-packbits.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 640);
    try helpers.expectEq(the_tiff.height(), 426);
    try std.testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[2].value, 0);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 0);
}

test "TIFF/LE grayscale8 packbits" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-grayscale8-packbits.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[0].value, 76);
    try helpers.expectEq(pixels.grayscale8[8].value, 149);
    try helpers.expectEq(pixels.grayscale8[90].value, 0);
    try helpers.expectEq(pixels.grayscale8[128 * 66 + 72].value, 149);
}

test "TIFF/LE 8-bit with colormap packbits" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-pal8-packbits.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .indexed8);

    const palette64 = pixels.indexed8.palette[64];

    try helpers.expectEq(palette64.r, 255);
    try helpers.expectEq(palette64.g, 0);
    try helpers.expectEq(palette64.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[0], 64);
    try helpers.expectEq(pixels.indexed8.indices[12], 128);
}

test "TIFF/LE 24-bit packbits" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-packbits.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 664);
    try helpers.expectEq(the_tiff.height(), 248);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE RGBA packbits" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgba-packbits.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 32);
    try helpers.expectEq(the_tiff.height(), 32);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 100, 1000, 1018 };
    const expected_colors = [_]u32{ 0xf6ff00, 0xbe0042, 0x2900d7 };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE monochrome black CCITT" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/ccitt_rle.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 400);
    try helpers.expectEq(the_tiff.height(), 300);
    try std.testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[73 * 400 + 48].value, 0);
}

test "TIFF/LE monochrome black LZW" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-lzw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 640);
    try helpers.expectEq(the_tiff.height(), 426);
    try std.testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[2].value, 0);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 0);
}

test "TIFF/LE grayscale8 LZW" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-grayscale8-lzw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[0].value, 76);
    try helpers.expectEq(pixels.grayscale8[8].value, 149);
    try helpers.expectEq(pixels.grayscale8[90].value, 0);
    try helpers.expectEq(pixels.grayscale8[128 * 66 + 72].value, 149);
}

test "TIFF/LE 8-bit with colormap LZW" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-pal8-lzw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .indexed8);

    const palette64 = pixels.indexed8.palette[64];

    try helpers.expectEq(palette64.r, 255);
    try helpers.expectEq(palette64.g, 0);
    try helpers.expectEq(palette64.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[0], 64);
    try helpers.expectEq(pixels.indexed8.indices[12], 128);
}

test "TIFF/LE 24-bit LZW" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-lzw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 664);
    try helpers.expectEq(the_tiff.height(), 248);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE RGBA LZW" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgba-lzw.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 32);
    try helpers.expectEq(the_tiff.height(), 32);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 100, 1000, 1018 };
    const expected_colors = [_]u32{ 0xf6ff00, 0xbe0042, 0x2900d7 };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE monochrome black Deflate" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-deflate.tiff");
    defer file.close();

    var the_bitmap = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_bitmap.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 640);
    try helpers.expectEq(the_bitmap.height(), 426);
    try std.testing.expect(pixels == .grayscale1);

    try helpers.expectEq(pixels.grayscale1[0].value, 1);
    try helpers.expectEq(pixels.grayscale1[2].value, 0);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 0);
}

test "TIFF/LE grayscale8 Deflate" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-grayscale8-deflate.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[0].value, 76);
    try helpers.expectEq(pixels.grayscale8[8].value, 149);
    try helpers.expectEq(pixels.grayscale8[90].value, 0);
    try helpers.expectEq(pixels.grayscale8[128 * 66 + 72].value, 149);
}

test "TIFF/LE 8-bit with colormap Deflate" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-pal8-deflate.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 128);
    try helpers.expectEq(the_tiff.height(), 128);
    try std.testing.expect(pixels == .indexed8);

    const palette64 = pixels.indexed8.palette[64];

    try helpers.expectEq(palette64.r, 255);
    try helpers.expectEq(palette64.g, 0);
    try helpers.expectEq(palette64.b, 0);

    try helpers.expectEq(pixels.indexed8.indices[0], 64);
    try helpers.expectEq(pixels.indexed8.indices[12], 128);
}

test "TIFF/LE 24-bit Deflate" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-deflate.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 664);
    try helpers.expectEq(the_tiff.height(), 248);
    try std.testing.expect(pixels == .rgb24);

    const indexes = [_]usize{ 8_754, 43_352, 42_224 };
    const expected_colors = [_]u32{
        0x21282e,
        0xe4ad38,
        0xffffff,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/LE RGBA Deflate" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgba-deflate.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 32);
    try helpers.expectEq(the_tiff.height(), 32);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 100, 1000, 1018 };
    const expected_colors = [_]u32{ 0xf6ff00, 0xbe0042, 0x2900d7 };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "TIFF/BE 24-bit uncompressed RGB with replicated BitsPerSample and missing StripByteCounts" {
    // Real-world scanner output (e.g. Epson scan) often writes BitsPerSample
    // with data_count=1 (single SHORT=8) even when SamplesPerPixel=3, and
    // omits StripByteCounts entirely. libtiff handles both leniencies; this
    // test pins zigimg to do the same.
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-rgb24-bps1-no-stripbc.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 4);
    try helpers.expectEq(the_tiff.height(), 4);
    try std.testing.expect(pixels == .rgb24);
    // Strip data is bytes 0..47 in RGB order: pixel[0] = (0,1,2), pixel[1] = (3,4,5), ...
    for (0..16) |i| {
        const base: u8 = @intCast(i * 3);
        try helpers.expectEq(pixels.rgb24[i].r, base);
        try helpers.expectEq(pixels.rgb24[i].g, base + 1);
        try helpers.expectEq(pixels.rgb24[i].b, base + 2);
    }
}

test "TIFF/BE monochrome CCITT Group 4 (T.6) - all white" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-ccitt-g4-white.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 16);
    try helpers.expectEq(the_tiff.height(), 16);
    try std.testing.expect(pixels == .grayscale1);
    // min-is-white photometric => white pixels render as 1
    for (pixels.grayscale1) |p| try helpers.expectEq(p.value, 1);
}

test "TIFF/BE monochrome CCITT Group 4 (T.6) - all black" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-ccitt-g4-black.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 16);
    try helpers.expectEq(the_tiff.height(), 16);
    try std.testing.expect(pixels == .grayscale1);
    for (pixels.grayscale1) |p| try helpers.expectEq(p.value, 0);
}

test "TIFF/BE monochrome CCITT Group 4 (T.6) - vertical stripe pattern" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-ccitt-g4-pattern.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 16);
    try helpers.expectEq(the_tiff.height(), 16);
    try std.testing.expect(pixels == .grayscale1);
    // Pattern is "1 0 1 0..." in PBM (1=black, 0=white). With min-is-white the
    // rendered values are inverted: black-white-black-white => 0-1-0-1.
    for (0..16) |row| {
        for (0..16) |col| {
            const expected: u1 = if (col & 1 == 0) 0 else 1;
            try helpers.expectEq(pixels.grayscale1[row * 16 + col].value, expected);
        }
    }
}

test "TIFF/BE monochrome CCITT Group 4 (T.6) - mixed checkerboard halves" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "tiff/sample-monob-ccitt-g4-mixed.tiff");
    defer file.close();

    var the_tiff = tiff.TIFF{};
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_tiff.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_tiff.width(), 24);
    try helpers.expectEq(the_tiff.height(), 16);
    try std.testing.expect(pixels == .grayscale1);
    // Top 8 rows: 12 white + 12 black; bottom 8 rows: 12 black + 12 white.
    // With min-is-white photometric, white => 1, black => 0.
    for (0..8) |row| {
        for (0..12) |col| try helpers.expectEq(pixels.grayscale1[row * 24 + col].value, 1);
        for (12..24) |col| try helpers.expectEq(pixels.grayscale1[row * 24 + col].value, 0);
    }
    for (8..16) |row| {
        for (0..12) |col| try helpers.expectEq(pixels.grayscale1[row * 24 + col].value, 0);
        for (12..24) |col| try helpers.expectEq(pixels.grayscale1[row * 24 + col].value, 1);
    }
}
