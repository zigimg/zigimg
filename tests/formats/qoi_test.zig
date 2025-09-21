const qoi = zigimg.formats.qoi;
const std = @import("std");
const helpers = @import("../helpers.zig");
const zigimg = @import("zigimg");

const zero_raw_file = helpers.fixtures_path ++ "qoi/zero.raw";
const zero_qoi_file = helpers.fixtures_path ++ "qoi/zero.qoi";

test "Should error on non QOI images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var qoi_file = qoi.QOI{};

    const invalid_file = qoi_file.read(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid_file, zigimg.Image.ReadError.InvalidData);
}

test "Read zero.qoi file" {
    const file = try helpers.testOpenFile(zero_qoi_file);
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var qoi_file = qoi.QOI{};

    const pixels = try qoi_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(qoi_file.width(), 512);
    try helpers.expectEq(qoi_file.height(), 512);
    try helpers.expectEq(try qoi_file.pixelFormat(), .rgba32);
    try std.testing.expect(qoi_file.header.colorspace == .srgb);

    try std.testing.expect(pixels == .rgba32);

    var buffer: [1025 * 1024]u8 = undefined;
    const zero_raw_pixels = try helpers.testReadFile(zero_raw_file, buffer[0..]);
    try std.testing.expectEqualSlices(u8, zero_raw_pixels, std.mem.sliceAsBytes(pixels.rgba32));
}

test "Write qoi file" {
    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, 512, 512, .rgba32);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    var buffer: [1025 * 1024]u8 = undefined;
    const zero_raw_pixels = try helpers.testReadFile(zero_raw_file, buffer[0..]);
    @memcpy(std.mem.sliceAsBytes(source_image.pixels.rgba32), std.mem.bytesAsSlice(u8, zero_raw_pixels));

    var image_buffer: [100 * 1024]u8 = undefined;
    var zero_qoi = try helpers.testReadFile(zero_qoi_file, buffer[0..]);

    const result_image = try source_image.writeToMemory(helpers.zigimg_test_allocator, image_buffer[0..], .{ .qoi = .{} });

    try std.testing.expectEqualSlices(u8, zero_qoi[0..], result_image);
}
