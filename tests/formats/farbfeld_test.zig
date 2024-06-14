const std = @import("std");
const farbfeld = @import("../../src/formats/farbfeld.zig");
const Image = @import("../../src/Image.zig");
const ImageUnmanaged = @import("../../src/ImageUnmanaged.zig");
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const helpers = @import("../helpers.zig");

const testing = std.testing;
const assert = std.debug.assert;

test "check dimension file" {
    const allocator = testing.allocator;
    const yellow_file_path = "tests/test-suite/fixtures/" ++ "farbfeld/yellow-1x1-semitransparent.png.ff";
    var yellow_image = try getff(allocator, yellow_file_path);
    defer yellow_image.deinit(allocator);
    try testing.expectEqual(yellow_image.width, 1);
    try testing.expectEqual(yellow_image.height, 1);

    const dragon_path = "tests/test-suite/fixtures/" ++ "farbfeld/dragon.ff";
    var dragon_image = try getff(allocator, dragon_path);
    defer dragon_image.deinit(allocator);
    try testing.expectEqual(dragon_image.width, 1680);
    try testing.expectEqual(dragon_image.height, 1167);

    // try helpers.expectEq(try farbfeld.Farbfeld.formatDetect(&stream_source));

}

test "invalid file format" {
    const allocator = testing.allocator;
    const png_file_path = "tests/test-suite/fixtures/" ++ "farbfeld/dragon.png";
    const image = getff(allocator, png_file_path);

    try testing.expectError(farbfeld.ReadError.InvalidData, image);
}

fn getff(allocator: std.mem.Allocator, file_path: []const u8) !ImageUnmanaged {
    const file = try std.fs.cwd().openFile(file_path, .{});
    {
        // var reader = file.reader();
        // // for (0..8) |_| {
        // //     std.debug.print("{c} ", .{try reader.readByte()});
        // // }
        // std.debug.print("magic match {}, file {s}\n", .{ try reader.isBytes(&farbfeld.Header.magic_value), file_path });
    }
    defer file.close();
    var stream_source = std.io.StreamSource{ .file = file };

    const image_farb = try farbfeld.readImage(allocator, &stream_source);
    return image_farb;
}
