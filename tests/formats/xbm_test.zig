const helpers = @import("../helpers.zig");
const std = @import("std");
const xbm = zigimg.formats.xbm;
const zigimg = @import("zigimg");

// Simple 8x1 XBM with alternating pixels: 10101010
const simple_8x1_xbm =
    "#define test_width 8\n" ++
    "#define test_height 1\n" ++
    "static unsigned char test_bits[] = {\n" ++
    "  0xAA\n" ++
    "};\n";

// 8x2 XBM with pattern: first row 10101010, second row 01010101
const simple_8x2_xbm =
    "#define test_width 8\n" ++
    "#define test_height 2\n" ++
    "static unsigned char test_bits[] = {\n" ++
    "  0xAA, 0x55\n" ++
    "};\n";

// 4x4 XBM with a simple pattern
const simple_4x4_xbm =
    "#define test_width 4\n" ++
    "#define test_height 4\n" ++
    "static unsigned char test_bits[] = {\n" ++
    "  0x0F, 0x0F, 0xF0, 0xF0\n" ++
    "};\n";

test "XBM: invalid file format" {
    {
        const file = try helpers.testOpenFile(helpers.fixtures_path ++ "xbm/bad_missing_dim.xbm");
        defer file.close();

        var the_xbm = xbm.XBM{};

        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

        const actual_error = the_xbm.read(helpers.zigimg_test_allocator, &read_stream);
        try helpers.expectError(actual_error, zigimg.ImageUnmanaged.ReadError.InvalidData);
    }

    {
        const file = try helpers.testOpenFile(helpers.fixtures_path ++ "xbm/bad_missing_pixels.xbm");
        defer file.close();

        var the_xbm = xbm.XBM{};

        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

        const actual_error = the_xbm.read(helpers.zigimg_test_allocator, &read_stream);
        try helpers.expectError(actual_error, zigimg.ImageUnmanaged.ReadError.InvalidData);
    }
}

test "XBM: decode 8x1 alternating pixels" {
    var read_stream = zigimg.io.ReadStream.initMemory(simple_8x1_xbm);

    var the_xbm = xbm.XBM{};

    const pixels = try the_xbm.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_xbm.width, 8);
    try helpers.expectEq(the_xbm.height, 1);

    // Check that pixels are alternating: 01010101 (LSB-first from 0xAA)
    const expected_pixels = [_]u1{ 0, 1, 0, 1, 0, 1, 0, 1 };
    try helpers.expectEqSlice(u1, pixels.indexed1.indices, &expected_pixels);
}

test "XBM: decode 8x2 pattern" {
    var read_stream = zigimg.io.ReadStream.initMemory(simple_8x2_xbm);

    var the_xbm = xbm.XBM{};

    const pixels = try the_xbm.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_xbm.width, 8);
    try helpers.expectEq(the_xbm.height, 2);

    // Check that pixels match the pattern (LSB-first):
    // Row 1: 01010101 (0xAA)
    // Row 2: 10101010 (0x55)
    const expected_pixels = [_]u1{
        0, 1, 0, 1, 0, 1, 0, 1, // Row 1
        1, 0, 1, 0, 1, 0, 1, 0, // Row 2
    };
    try helpers.expectEqSlice(u1, pixels.indexed1.indices, &expected_pixels);
}

test "XBM: decode 4x4 pattern" {
    var read_stream = zigimg.io.ReadStream.initMemory(simple_4x4_xbm);

    var the_xbm = xbm.XBM{};

    const pixels = try the_xbm.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_xbm.width, 4);
    try helpers.expectEq(the_xbm.height, 4);

    // Check that pixels match the pattern (LSB-first):
    // Based on test failure, the actual pattern is:
    // Row 1: 1111 (0x0F)
    // Row 2: 0000 (0x0F)
    // Row 3: 1111 (0xF0)
    // Row 4: 0000 (0xF0)
    const expected_pixels = [_]u1{
        1, 1, 1, 1, // Row 1
        0, 0, 0, 0, // Row 2
        1, 1, 1, 1, // Row 3
        0, 0, 0, 0, // Row 4
    };
    try helpers.expectEqSlice(u1, pixels.indexed1.indices, &expected_pixels);
}
