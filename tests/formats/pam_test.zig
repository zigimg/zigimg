const helpers = @import("../helpers.zig");
const pam = zigimg.formats.pam;
const std = @import("std");
const zigimg = @import("zigimg");

test "rejects non-PAM images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.InvalidData);
}

test "rejects PAM images with unsupported depth" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/unsupported_depth.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.Unsupported);
}

test "rejects PAM images with invalid maxval" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/invalid_maxval.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.InvalidData);
}

test "rejects PAM images with component values greater than maxval" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/value_greater_than_maxval.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    try helpers.expectError(invalid, zigimg.Image.ReadError.InvalidData);
}

test "rejects PAM images with unknown tuple type" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/unknown_tupletype.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.Unsupported);
}

test "rejects PAM images with invalid first token" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/invalid_first_token.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.InvalidData);
}

test "rejects PAM images with tuple type not matching other parameters" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/non_matching_tuple_type.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const invalid = pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);

    try helpers.expectError(invalid, zigimg.Image.ReadError.InvalidData);
}

test "accepts comments" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_blackandwhite_comments.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale1, image.pixels.grayscale1, &[16]zigimg.color.Grayscale1{
        // zig fmt: off
        .{.value = 1}, .{.value = 0}, .{.value = 1}, .{.value = 0},
        .{.value = 0}, .{.value = 1}, .{.value = 0}, .{.value = 1},
        .{.value = 1}, .{.value = 0}, .{.value = 1}, .{.value = 0},
        .{.value = 0}, .{.value = 1}, .{.value = 0}, .{.value = 1},
        // zig fmt: on
    });
}

test "reads blackandwhite pam" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_blackandwhite.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale1, image.pixels.grayscale1, &[16]zigimg.color.Grayscale1{
        // zig fmt: off
        .{.value = 1}, .{.value = 0}, .{.value = 1}, .{.value = 0},
        .{.value = 0}, .{.value = 1}, .{.value = 0}, .{.value = 1},
        .{.value = 1}, .{.value = 0}, .{.value = 1}, .{.value = 0},
        .{.value = 0}, .{.value = 1}, .{.value = 0}, .{.value = 1},
        // zig fmt: on
    });
}

test "reads blackandwhite_alpha pam" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_blackandwhite_alpha.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale1, image.pixels.grayscale1, &[16]zigimg.color.Grayscale1{
        // zig fmt: off
        .{.value = 1}, .{.value = 0}, .{.value = 0}, .{.value = 0},
        .{.value = 1}, .{.value = 0}, .{.value = 0}, .{.value = 0},
        .{.value = 1}, .{.value = 0}, .{.value = 0}, .{.value = 0},
        .{.value = 1}, .{.value = 0}, .{.value = 0}, .{.value = 0},
        // zig fmt: on
    });
}

test "reads grayscale pam with maxval 255" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_grayscale_maxval_255.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale8, image.pixels.grayscale8, &[16]zigimg.color.Grayscale8{
        // zig fmt: off
        .{.value = 0x68}, .{.value = 0x61}, .{.value = 0x68}, .{.value = 0x61},
        .{.value = 0x20}, .{.value = 0x72}, .{.value = 0x65}, .{.value = 0x64},
        .{.value = 0x20}, .{.value = 0x73}, .{.value = 0x75}, .{.value = 0x73},
        .{.value = 0x2c}, .{.value = 0x20}, .{.value = 0x66}, .{.value = 0x6f},
        // zig fmt: on
    });
}

test "reads grayscale alpha pam with maxval 255" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_grayscale_alpha_maxval_255.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale8Alpha, image.pixels.grayscale8Alpha, &[16]zigimg.color.Grayscale8Alpha{
        // zig fmt: off
        .{.value = 0x68, .alpha = 0x61}, .{.value = 0x68, .alpha = 0x61}, .{.value = 0x20, .alpha = 0x72}, .{.value = 0x65, .alpha = 0x64},
        .{.value = 0x20, .alpha = 0x73}, .{.value = 0x75, .alpha = 0x73}, .{.value = 0x2c, .alpha = 0x20}, .{.value = 0x66, .alpha = 0x6f},
        .{.value = 0x6f, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61}, .{.value = 0x72, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61},
        .{.value = 0x7a, .alpha = 0x20}, .{.value = 0x71, .alpha = 0x75}, .{.value = 0x75, .alpha = 0x78}, .{.value = 0x20, .alpha = 0x65},
        // zig fmt: on
    });
}

test "read of rgb pam with maxval 255" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/horse.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 843750), image.pixels.len());
}

test "basic read-write-read produces same result" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_grayscale_alpha_maxval_255.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.height);
    try std.testing.expectEqual(@as(usize, 4), image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale8Alpha, image.pixels.grayscale8Alpha, &[16]zigimg.color.Grayscale8Alpha{
        // zig fmt: off
        .{.value = 0x68, .alpha = 0x61}, .{.value = 0x68, .alpha = 0x61}, .{.value = 0x20, .alpha = 0x72}, .{.value = 0x65, .alpha = 0x64},
        .{.value = 0x20, .alpha = 0x73}, .{.value = 0x75, .alpha = 0x73}, .{.value = 0x2c, .alpha = 0x20}, .{.value = 0x66, .alpha = 0x6f},
        .{.value = 0x6f, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61}, .{.value = 0x72, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61},
        .{.value = 0x7a, .alpha = 0x20}, .{.value = 0x71, .alpha = 0x75}, .{.value = 0x75, .alpha = 0x78}, .{.value = 0x20, .alpha = 0x65},
        // zig fmt: on
    });

    var write_buffer: [8192]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(write_buffer[0..]);

    try pam.PAM.writeImage(helpers.zigimg_test_allocator, &write_stream, image, .{.pam = .{}});

    var read_back_stream = zigimg.io.ReadStream.initMemory(write_stream.writer().buffered());

    var decoded_image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_back_stream);
    defer decoded_image.deinit(helpers.zigimg_test_allocator);
    
    try std.testing.expectEqual(@as(usize, 4), decoded_image.height);
    try std.testing.expectEqual(@as(usize, 4), decoded_image.width);
    try helpers.expectEqSlice(zigimg.color.Grayscale8Alpha, decoded_image.pixels.grayscale8Alpha, &[16]zigimg.color.Grayscale8Alpha{
        // zig fmt: off
        .{.value = 0x68, .alpha = 0x61}, .{.value = 0x68, .alpha = 0x61}, .{.value = 0x20, .alpha = 0x72}, .{.value = 0x65, .alpha = 0x64},
        .{.value = 0x20, .alpha = 0x73}, .{.value = 0x75, .alpha = 0x73}, .{.value = 0x2c, .alpha = 0x20}, .{.value = 0x66, .alpha = 0x6f},
        .{.value = 0x6f, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61}, .{.value = 0x72, .alpha = 0x20}, .{.value = 0x62, .alpha = 0x61},
        .{.value = 0x7a, .alpha = 0x20}, .{.value = 0x71, .alpha = 0x75}, .{.value = 0x75, .alpha = 0x78}, .{.value = 0x20, .alpha = 0x65},
        // zig fmt: on
    });
}

test "reads rgba pam with maxval 255" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_rgba_maxval_255.pam");
    defer file.close();

      var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.pixels.len());
    try helpers.expectEqSlice(zigimg.color.Rgba32, image.pixels.rgba32, &[4]zigimg.color.Rgba32{
        .{.r = 'a', .g = 'b', .b = 'c', .a = 'd'},
        .{.r = 'e', .g = 'f', .b = 'g', .a = 'h'},
        .{.r = 'i', .g = 'j', .b = 'k', .a = 'l'},
        .{.r = 'm', .g = 'n', .b = 'o', .a = 'p'},
    });
}

test "reads rgba pam with maxval 65535" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "pam/simple_rgba_maxval_65535.pam");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var image = try pam.PAM.readImage(helpers.zigimg_test_allocator, &read_stream);
    defer image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expectEqual(@as(usize, 4), image.pixels.len());
    try helpers.expectEqSlice(zigimg.color.Rgba64, image.pixels.rgba64, &[4]zigimg.color.Rgba64{
        .{ .r = 25185, .g = 25699, .b = 26213, .a = 26727 },
        .{ .r = 27241, .g = 27755, .b = 28269, .a = 28783 },
        .{ .r = 29297, .g = 29811, .b = 30325, .a = 30839 },
        .{ .r = 31353, .g = 31867, .b = 32381, .a = 49791 },
    });
}
