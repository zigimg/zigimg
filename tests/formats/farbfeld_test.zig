const std = @import("std");
const farbfeld = @import("../../src/formats/farbfeld.zig");
const Image = @import("../../src/Image.zig");
const ImageUnmanaged = @import("../../src/ImageUnmanaged.zig");
const helpers = @import("../helpers.zig");

const testing = std.testing;
const assert = std.debug.assert;

test "check dimension file" {
    const yellow_file_path = "yellow-1x1-semitransparent.png.ff";
    var yellow_image = try getff(helpers.zigimg_test_allocator, yellow_file_path);
    defer yellow_image.deinit(helpers.zigimg_test_allocator);

    try testing.expectEqual(yellow_image.width, 1);
    try testing.expectEqual(yellow_image.height, 1);
    try testing.expect(yellow_image.pixels == .rgba64);

    const dragon_path = "dragon.ff";
    var dragon_image = try getff(helpers.zigimg_test_allocator, dragon_path);
    defer dragon_image.deinit(helpers.zigimg_test_allocator);

    try testing.expectEqual(dragon_image.width, 1680);
    try testing.expectEqual(dragon_image.height, 1167);
    try testing.expect(dragon_image.pixels == .rgba64);
}

test "invalid file format" {
    const png_file_path = "dragon.png";
    const image = getff(helpers.zigimg_test_allocator, png_file_path);

    try testing.expectError(farbfeld.ReadError.InvalidData, image);
}

test "read writeImage output" {
    const dragon_path = "yellow-1x1-semitransparent.png.ff";
    var source_image = try getff(helpers.zigimg_test_allocator, dragon_path);
    defer source_image.deinit(helpers.zigimg_test_allocator);
    var buf: [farbfeld.Header.size + @sizeOf(farbfeld.color.Rgba64) * 1]u8 = undefined;
    var stream = Image.Stream{
        .buffer = std.io.fixedBufferStream(&buf),
    };

    try farbfeld.Farbfeld.writeImage(helpers.zigimg_test_allocator, &stream, source_image, .{ .farbfeld = {} });
    stream.buffer = std.io.fixedBufferStream(stream.buffer.getWritten());

    var decoded_image = try farbfeld.Farbfeld.readImage(helpers.zigimg_test_allocator, &stream);
    defer decoded_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(decoded_image.width, source_image.width);
    try helpers.expectEq(decoded_image.height, source_image.height);
    try testing.expect(decoded_image.pixels == .rgba64);
}

fn getff(allocator: std.mem.Allocator, comptime file_path: []const u8) !ImageUnmanaged {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "farbfeld/" ++ file_path);
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    const image_farb = try farbfeld.Farbfeld.readImage(allocator, &stream_source);
    return image_farb;
}
