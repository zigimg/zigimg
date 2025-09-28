const helpers = @import("../helpers.zig");
const std = @import("std");
const zigimg = @import("zigimg");
const farbfeld = zigimg.formats.farbfeld;

test "Farbfeld: Read yellow file" {
    const yellow_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/yellow-1x1-semitransparent.png.ff");
    defer yellow_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var yellow_read_stream = zigimg.io.ReadStream.initFile(yellow_file, read_buffer[0..]);

    var yellow_image = farbfeld.Farbfeld{};
    const yellow_pixels = try yellow_image.read(helpers.zigimg_test_allocator, &yellow_read_stream);
    defer yellow_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(yellow_image.header.width, 1);
    try helpers.expectEq(yellow_image.header.height, 1);
    try std.testing.expect(yellow_pixels == .rgba64);
}

test "Farbfeld: read dragon file" {
    const dragon_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/dragon.ff");
    defer dragon_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var dragon_read_stream = zigimg.io.ReadStream.initFile(dragon_file, read_buffer[0..]);

    var dragon_image = farbfeld.Farbfeld{};
    const dragon_pixels = try dragon_image.read(helpers.zigimg_test_allocator, &dragon_read_stream);
    defer dragon_pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(dragon_image.header.width, 1680);
    try helpers.expectEq(dragon_image.header.height, 1167);
    try std.testing.expect(dragon_pixels == .rgba64);
}

test "Farbfeld: invalid file format" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/dragon.png");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var farbfeld_image = farbfeld.Farbfeld{};
    const image_error = farbfeld_image.read(helpers.zigimg_test_allocator, &read_stream);

    try std.testing.expectError(zigimg.Image.ReadError.InvalidData, image_error);
}

test "Farbfeld: read writeImage output" {
    const source_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/yellow-1x1-semitransparent.png.ff");
    defer source_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var source_read_stream = zigimg.io.ReadStream.initFile(source_file, read_buffer[0..]);

    var source_image: farbfeld.Farbfeld = .{};
    const source_pixels = try source_image.read(helpers.zigimg_test_allocator, &source_read_stream);
    defer source_pixels.deinit(helpers.zigimg_test_allocator);

    var target_buffer: [farbfeld.Header.SIZE + @sizeOf(zigimg.color.Rgba64) * 1]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(target_buffer[0..]);

    try source_image.write(&write_stream, source_pixels);

    var target_read_stream = zigimg.io.ReadStream.initMemory(target_buffer[0..]);

    var decoded_image = try farbfeld.Farbfeld.readImage(helpers.zigimg_test_allocator, &target_read_stream);
    defer decoded_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(decoded_image.width, source_image.header.width);
    try helpers.expectEq(decoded_image.height, source_image.header.height);
    try std.testing.expect(decoded_image.pixels == .rgba64);

    try helpers.expectEq(decoded_image.pixels.rgba64[0], source_pixels.rgba64[0]);
}
