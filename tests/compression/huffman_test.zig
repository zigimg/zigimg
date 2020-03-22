const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const zigimg = @import("zigimg");
const huffman = zigimg.huffman;
const deflate = zigimg.deflate;
usingnamespace @import("../helpers.zig");

test "Test Huffman decoder with DEFLATE Fixed Literal table" {
    var literalDecoder = try huffman.Decoder.initFromCodewordLength(deflate.FixedHuffmanLiteralLengthTable[0..]);

    var used_bits: usize = 0;

    expectEq(try literalDecoder.decode(0b00001100, &used_bits), 0);
    expectEq(try literalDecoder.decode(0b000010011, &used_bits), 144);
    expectEq(try literalDecoder.decode(0b0000000, &used_bits), 256);
    expectEq(try literalDecoder.decode(0b00000011, &used_bits), 280);
}
