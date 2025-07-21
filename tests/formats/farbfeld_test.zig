const color = @import("../../src/color.zig");
const farbfeld = @import("../../src/formats/farbfeld.zig");
const helpers = @import("../helpers.zig");
const Image = @import("../../src/Image.zig");
const ImageUnmanaged = @import("../../src/ImageUnmanaged.zig");
const std = @import("std");

test "Farbfeld: Check dimension file" {
    {
        const yellow_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/yellow-1x1-semitransparent.png.ff");
        defer yellow_file.close();

        var yellow_stream_source = std.Io.StreamSource{ .file = yellow_file };

        var yellow_image = farbfeld.Farbfeld{};
        const yellow_pixels = try yellow_image.read(helpers.zigimg_test_allocator, &yellow_stream_source);
        defer yellow_pixels.deinit(helpers.zigimg_test_allocator);

        try helpers.expectEq(yellow_image.header.width, 1);
        try helpers.expectEq(yellow_image.header.height, 1);
        try std.testing.expect(yellow_pixels == .rgba64);
    }

    {
        const dragon_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/dragon.ff");
        defer dragon_file.close();

        var dragon_stream_source = std.Io.StreamSource{ .file = dragon_file };

        var dragon_image = farbfeld.Farbfeld{};
        const dragon_pixels = try dragon_image.read(helpers.zigimg_test_allocator, &dragon_stream_source);
        defer dragon_pixels.deinit(helpers.zigimg_test_allocator);

        try helpers.expectEq(dragon_image.header.width, 1680);
        try helpers.expectEq(dragon_image.header.height, 1167);
        try std.testing.expect(dragon_pixels == .rgba64);
    }
}

test "Farbfeld: invalid file format" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/dragon.png");
    defer file.close();

    var stream_source = std.Io.StreamSource{ .file = file };

    var farbfeld_image = farbfeld.Farbfeld{};
    const image_error = farbfeld_image.read(helpers.zigimg_test_allocator, &stream_source);

    try std.testing.expectError(ImageUnmanaged.ReadError.InvalidData, image_error);
}

test "Farbfeld: read writeImage output" {
    const source_file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/yellow-1x1-semitransparent.png.ff");
    defer source_file.close();

    var source_stream_source = std.Io.StreamSource{ .file = source_file };

    var source_image: farbfeld.Farbfeld = .{};
    const source_pixels = try source_image.read(helpers.zigimg_test_allocator, &source_stream_source);
    defer source_pixels.deinit(helpers.zigimg_test_allocator);

    var target_buffer: [farbfeld.Header.size + @sizeOf(color.Rgba64) * 1]u8 = undefined;
    var write_stream = Image.Stream{
        .buffer = std.Io.fixedBufferStream(&target_buffer),
    };

    try source_image.write(&write_stream, source_pixels);
    write_stream.buffer = std.Io.fixedBufferStream(write_stream.buffer.getWritten());

    var decoded_image = try farbfeld.Farbfeld.readImage(helpers.zigimg_test_allocator, &write_stream);
    defer decoded_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(decoded_image.width, source_image.header.width);
    try helpers.expectEq(decoded_image.height, source_image.header.height);
    try std.testing.expect(decoded_image.pixels == .rgba64);

    try helpers.expectEq(decoded_image.pixels.rgba64[0], source_pixels.rgba64[0]);
}
