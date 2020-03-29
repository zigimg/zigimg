const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const zigimg = @import("zigimg");
const deflate = zigimg.deflate;
usingnamespace @import("../helpers.zig");

const NoCompressionBlock = comptime blk: {
    const Data = "HELLOWORLD";
    var buffer: [128]u8 = undefined;
    var bufferStream = std.io.fixedBufferStream(&buffer);
    var bufferOutStream = bufferStream.outStream();
    var bitOutStream = std.io.bitOutStream(.Little, bufferOutStream);

    const length = Data.len;

    try bitOutStream.writeBits(@as(u1, 1), 1);
    try bitOutStream.writeBits(@as(u2, 00), 2);
    try bitOutStream.flushBits();
    try bufferOutStream.writeIntLittle(u16, @as(u16, length));
    try bufferOutStream.writeIntLittle(u16, @truncate(u16, ~length));
    _ = try bufferOutStream.write(Data);

    break :blk buffer[0..bufferStream.pos];
};

test "Test Deflate no compression block" {
    var outBuffer: [256]u8 = undefined;
    var in_position: usize = 0;
    var out_position: usize = 0;

    var deflateDecompressor = deflate.DeflateDecompressor.init(zigimg_test_allocator);
    try deflateDecompressor.read(NoCompressionBlock[0..], &in_position, outBuffer[0..], &out_position);

    testing.expectEqualSlices(u8, @as([]const u8, "HELLOWORLD"[0..]), outBuffer[0..out_position]);
}

test "Test deflate dynamic compression" {
    const dynamic_deflate_block = @embedFile("../fixtures/deflate/dynamic_compression.bin");

    var in_position: usize = 0;

    var out_buffer: [1024]u8 = undefined;
    var out_position: usize = 0;

    var deflate_decompressor = deflate.DeflateDecompressor.init(zigimg_test_allocator);
    try deflate_decompressor.read(dynamic_deflate_block[0..], &in_position, out_buffer[0..], &out_position);

    const out_data = out_buffer[0..out_position];

    expectEq(out_data[0], 0);
    expectEq(out_data[1], 255);
    expectEq(out_data[2], 255);
    expectEq(out_data[3], 255);
    expectEq(out_data[4], 254);
    expectEq(out_data[5], 0);
}
