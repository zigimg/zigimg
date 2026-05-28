const std = @import("std");
const zigimg = @import("zigimg");
const Image = zigimg.Image;
const helpers = @import("../helpers.zig");
const test_io = std.testing.io;

const test_image_path = helpers.fixtures_path ++ "jpeg/";

fn expectLoadDoesNotPanic(path: []const u8) !void {
    var read_buf: [256 * 1024]u8 = undefined;

    var file = try helpers.testOpenFile(test_io, path);
    defer file.close(test_io);

    var image = Image.fromFile(helpers.zigimg_test_allocator, test_io, file, &read_buf) catch return;
    defer image.deinit(helpers.zigimg_test_allocator);
}

test "JPEG loads crafted DC coefficient overflow fixtures without panicking" {
    const fixtures = [_][]const u8{
        test_image_path ++ "crafted_33000x8.jpg",
        test_image_path ++ "crafted_40000x8.jpg",
        test_image_path ++ "crafted_64000x8.jpg",
    };

    for (fixtures) |fixture| {
        try expectLoadDoesNotPanic(fixture);
    }
}

test "JPEG loads crafted IDCT overflow fixtures without panicking" {
    const fixtures = [_][]const u8{
        test_image_path ++ "crafted_80x8.jpg",
        test_image_path ++ "crafted_3200x8.jpg",
        test_image_path ++ "crafted_32000x8.jpg",
    };

    for (fixtures) |fixture| {
        try expectLoadDoesNotPanic(fixture);
    }
}
