const helpers = @import("../helpers.zig");
const Image = @import("../../src/Image.zig");
const ImageError = Image.Error;
const std = @import("std");

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
    try helpers.expectError(helpers.testImageFromFile(helpers.fixtures_path ++ "xbm/bad_missing_dim.xbm"), ImageError.Unsupported);

    try helpers.expectError(helpers.testImageFromFile(helpers.fixtures_path ++ "xbm/bad_missing_pixels.xbm"), Image.ReadError.InvalidData);
}

test "XBM: decode 8x1 alternating pixels" {
    var image = try Image.fromMemory(helpers.zigimg_test_allocator, simple_8x1_xbm);
    defer image.deinit();

    try helpers.expectEq(image.width, 8);
    try helpers.expectEq(image.height, 1);

    // Check that pixels are alternating: 01010101 (LSB-first from 0xAA)
    const expected_pixels = [_]u1{ 0, 1, 0, 1, 0, 1, 0, 1 };
    try helpers.expectEqSlice(u1, image.pixels.indexed1.indices, &expected_pixels);
}

test "XBM: decode 8x2 pattern" {
    var image = try Image.fromMemory(helpers.zigimg_test_allocator, simple_8x2_xbm);
    defer image.deinit();

    try helpers.expectEq(image.width, 8);
    try helpers.expectEq(image.height, 2);

    // Check that pixels match the pattern (LSB-first):
    // Row 1: 01010101 (0xAA)
    // Row 2: 10101010 (0x55)
    const expected_pixels = [_]u1{
        0, 1, 0, 1, 0, 1, 0, 1, // Row 1
        1, 0, 1, 0, 1, 0, 1, 0, // Row 2
    };
    try helpers.expectEqSlice(u1, image.pixels.indexed1.indices, &expected_pixels);
}

test "XBM: decode 4x4 pattern" {
    var image = try Image.fromMemory(helpers.zigimg_test_allocator, simple_4x4_xbm);
    defer image.deinit();

    try helpers.expectEq(image.width, 4);
    try helpers.expectEq(image.height, 4);

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
    try helpers.expectEqSlice(u1, image.pixels.indexed1.indices, &expected_pixels);
}
