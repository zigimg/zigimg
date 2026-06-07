const helpers = @import("../helpers.zig");
const sgi = zigimg.formats.sgi;
const std = @import("std");
const zigimg = @import("zigimg");

const test_io = std.testing.io;

test "Should error on non SGI images" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close(test_io);

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    var sgi_file = sgi.SGI{};

    const invalid_file = sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    try helpers.expectError(invalid_file, zigimg.Image.ReadError.InvalidData);
}

test "SGI 24-bit uncompressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-rgb24.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 664);
    try helpers.expectEq(sgi_file.height(), 248);
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

test "SGI grayscale uncompressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-blackwhite.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 1250);
    try helpers.expectEq(sgi_file.height(), 438);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[141].value, 255);
    try helpers.expectEq(pixels.grayscale8[1_716].value, 0);
}

test "SGI 32-bit RGBA uncompressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-rgba.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 240);
    try helpers.expectEq(sgi_file.height(), 160);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "SGI RGB48be uncompressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-rgb48be.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 240);
    try helpers.expectEq(sgi_file.height(), 160);
    try std.testing.expect(pixels == .rgb48);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb48[index].to.u32Rgb(), hex_color);
    }
}

test "SGI grayscale rle compressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-gray-rle.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 1250);
    try helpers.expectEq(sgi_file.height(), 438);
    try std.testing.expect(pixels == .grayscale8);

    try helpers.expectEq(pixels.grayscale8[141].value, 255);
    try helpers.expectEq(pixels.grayscale8[1_716].value, 0);
}

test "SGI 24-bit rle compressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-24bit-rle.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 664);
    try helpers.expectEq(sgi_file.height(), 248);
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

test "SGI RGB48be rle uncompressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-rgb48be-rle.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 240);
    try helpers.expectEq(sgi_file.height(), 160);
    try std.testing.expect(pixels == .rgb48);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgb48[index].to.u32Rgb(), hex_color);
    }
}

test "SGI 32-bit RGBA rle compressed" {
    const file = try helpers.testOpenFile(test_io, helpers.fixtures_path ++ "sgi/sample-rgba-rle.sgi");
    defer file.close(test_io);

    var sgi_file = sgi.SGI{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_io, file, read_buffer[0..]);

    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(sgi_file.width(), 240);
    try helpers.expectEq(sgi_file.height(), 160);
    try std.testing.expect(pixels == .rgba32);

    const indexes = [_]usize{ 8_754, 3, 28_224 };
    const expected_colors = [_]u32{
        0xffffff,
        0xff,
        0x0,
    };

    for (expected_colors, indexes) |hex_color, index| {
        try helpers.expectEq(pixels.rgba32[index].to.u32Rgb(), hex_color);
    }
}

test "SGI 64-bit RGBA uncompressed - alpha channel bug test" {
    const width: u16 = 2;
    const height: u16 = 2;

    var file_data: [544]u8 = .{0} ** 544;

    file_data[0] = 0x01;
    file_data[1] = 0xda;
    file_data[2] = 0x00;
    file_data[3] = 0x02;
    file_data[4] = 0x00;
    file_data[5] = 0x03;
    file_data[6] = 0x00;
    file_data[7] = @intCast(width);
    file_data[8] = 0x00;
    file_data[9] = @intCast(height);
    file_data[10] = 0x00;
    file_data[11] = 0x04;

    const data_offset = 512;

    file_data[data_offset + 0] = 0x10; file_data[data_offset + 1] = 0x00;
    file_data[data_offset + 2] = 0x20; file_data[data_offset + 3] = 0x00;
    file_data[data_offset + 4] = 0x30; file_data[data_offset + 5] = 0x00;
    file_data[data_offset + 6] = 0x40; file_data[data_offset + 7] = 0x00;

    file_data[data_offset + 8] = 0x01; file_data[data_offset + 9] = 0x00;
    file_data[data_offset + 10] = 0x02; file_data[data_offset + 11] = 0x00;
    file_data[data_offset + 12] = 0x03; file_data[data_offset + 13] = 0x00;
    file_data[data_offset + 14] = 0x04; file_data[data_offset + 15] = 0x00;

    file_data[data_offset + 16] = 0x00; file_data[data_offset + 17] = 0x10;
    file_data[data_offset + 18] = 0x00; file_data[data_offset + 19] = 0x20;
    file_data[data_offset + 20] = 0x00; file_data[data_offset + 21] = 0x30;
    file_data[data_offset + 22] = 0x00; file_data[data_offset + 23] = 0x40;

    file_data[data_offset + 24] = 0xAB; file_data[data_offset + 25] = 0xCD;
    file_data[data_offset + 26] = 0x12; file_data[data_offset + 27] = 0x34;
    file_data[data_offset + 28] = 0x56; file_data[data_offset + 29] = 0x78;
    file_data[data_offset + 30] = 0x9A; file_data[data_offset + 31] = 0xBC;

    var read_stream = zigimg.io.ReadStream.initMemory(&file_data);

    var sgi_file = sgi.SGI{};
    const pixels = try sgi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(pixels == .rgba64);

    try helpers.expectEq(pixels.rgba64[2].a, 0xABCD);
    try helpers.expectEq(pixels.rgba64[3].a, 0x1234);
    try helpers.expectEq(pixels.rgba64[0].a, 0x5678);
    try helpers.expectEq(pixels.rgba64[1].a, 0x9ABC);
}
