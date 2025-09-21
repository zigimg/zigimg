const bmp = zigimg.formats.bmp;
const helpers = @import("../helpers.zig");
const std = @import("std");
const zigimg = @import("zigimg");

fn verifyBitmapRGBAV5(the_bitmap: bmp.BMP, pixels: zigimg.color.PixelStorage) !void {
    try helpers.expectEq(the_bitmap.file_header.size, 153738);
    try helpers.expectEq(the_bitmap.file_header.reserved, 0);
    try helpers.expectEq(the_bitmap.file_header.pixel_offset, 138);
    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);

    try helpers.expectEqSlice(u8, @tagName(the_bitmap.info_header), "v5");

    _ = switch (the_bitmap.info_header) {
        .v5 => |v5Header| {
            try helpers.expectEq(v5Header.header_size, bmp.BitmapInfoHeaderV5.HeaderSize);
            try helpers.expectEq(v5Header.width, 240);
            try helpers.expectEq(v5Header.height, 160);
            try helpers.expectEq(v5Header.color_plane, 1);
            try helpers.expectEq(v5Header.bit_count, 32);
            try helpers.expectEq(v5Header.compression_method, bmp.CompressionMethod.bitfields);
            try helpers.expectEq(v5Header.image_raw_size, 240 * 160 * 4);
            try helpers.expectEq(v5Header.horizontal_resolution, 2835);
            try helpers.expectEq(v5Header.vertical_resolution, 2835);
            try helpers.expectEq(v5Header.palette_size, 0);
            try helpers.expectEq(v5Header.important_colors, 0);
            try helpers.expectEq(v5Header.red_mask, 0x00ff0000);
            try helpers.expectEq(v5Header.green_mask, 0x0000ff00);
            try helpers.expectEq(v5Header.blue_mask, 0x000000ff);
            try helpers.expectEq(v5Header.alpha_mask, 0xff000000);
            try helpers.expectEq(v5Header.color_space, bmp.BitmapColorSpace.srgb);
            try helpers.expectEq(v5Header.cie_end_points.red.x, 0);
            try helpers.expectEq(v5Header.cie_end_points.red.y, 0);
            try helpers.expectEq(v5Header.cie_end_points.red.z, 0);
            try helpers.expectEq(v5Header.cie_end_points.green.x, 0);
            try helpers.expectEq(v5Header.cie_end_points.green.y, 0);
            try helpers.expectEq(v5Header.cie_end_points.green.z, 0);
            try helpers.expectEq(v5Header.cie_end_points.blue.x, 0);
            try helpers.expectEq(v5Header.cie_end_points.blue.y, 0);
            try helpers.expectEq(v5Header.cie_end_points.blue.z, 0);
            try helpers.expectEq(v5Header.gamma_red, 0);
            try helpers.expectEq(v5Header.gamma_green, 0);
            try helpers.expectEq(v5Header.gamma_blue, 0);
            try helpers.expectEq(v5Header.intent, bmp.BitmapIntent.graphics);
            try helpers.expectEq(v5Header.profile_data, 0);
            try helpers.expectEq(v5Header.profile_size, 0);
            try helpers.expectEq(v5Header.reserved, 0);
        },
        else => unreachable,
    };

    try std.testing.expect(pixels == .bgra32);

    try helpers.expectEq(pixels.len(), 240 * 160);

    const first_pixel = pixels.bgra32[0];
    try helpers.expectEq(first_pixel.r, 0xFF);
    try helpers.expectEq(first_pixel.g, 0xFF);
    try helpers.expectEq(first_pixel.b, 0xFF);
    try helpers.expectEq(first_pixel.a, 0xFF);

    const second_pixel = pixels.bgra32[1];
    try helpers.expectEq(second_pixel.r, 0xFF);
    try helpers.expectEq(second_pixel.g, 0x00);
    try helpers.expectEq(second_pixel.b, 0x00);
    try helpers.expectEq(second_pixel.a, 0xFF);

    const third_pixel = pixels.bgra32[2];
    try helpers.expectEq(third_pixel.r, 0x00);
    try helpers.expectEq(third_pixel.g, 0xFF);
    try helpers.expectEq(third_pixel.b, 0x00);
    try helpers.expectEq(third_pixel.a, 0xFF);

    const fourth_pixel = pixels.bgra32[3];
    try helpers.expectEq(fourth_pixel.r, 0x00);
    try helpers.expectEq(fourth_pixel.g, 0x00);
    try helpers.expectEq(fourth_pixel.b, 0xFF);
    try helpers.expectEq(fourth_pixel.a, 0xFF);

    const colored_pixel = pixels.bgra32[(22 * 240) + 16];
    try helpers.expectEq(colored_pixel.r, 195);
    try helpers.expectEq(colored_pixel.g, 195);
    try helpers.expectEq(colored_pixel.b, 255);
    try helpers.expectEq(colored_pixel.a, 255);
}

test "Read simple version 4 24-bit RGB bitmap" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var the_bitmap = bmp.BMP{};

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    const pixels = try the_bitmap.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(the_bitmap.width(), 8);
    try helpers.expectEq(the_bitmap.height(), 1);

    try std.testing.expect(pixels == .bgr24);

    const red = pixels.bgr24[0];
    try helpers.expectEq(red.r, 0xFF);
    try helpers.expectEq(red.g, 0x00);
    try helpers.expectEq(red.b, 0x00);

    const green = pixels.bgr24[1];
    try helpers.expectEq(green.r, 0x00);
    try helpers.expectEq(green.g, 0xFF);
    try helpers.expectEq(green.b, 0x00);

    const blue = pixels.bgr24[2];
    try helpers.expectEq(blue.r, 0x00);
    try helpers.expectEq(blue.g, 0x00);
    try helpers.expectEq(blue.b, 0xFF);

    const cyan = pixels.bgr24[3];
    try helpers.expectEq(cyan.r, 0x00);
    try helpers.expectEq(cyan.g, 0xFF);
    try helpers.expectEq(cyan.b, 0xFF);

    const magenta = pixels.bgr24[4];
    try helpers.expectEq(magenta.r, 0xFF);
    try helpers.expectEq(magenta.g, 0x00);
    try helpers.expectEq(magenta.b, 0xFF);

    const yellow = pixels.bgr24[5];
    try helpers.expectEq(yellow.r, 0xFF);
    try helpers.expectEq(yellow.g, 0xFF);
    try helpers.expectEq(yellow.b, 0x00);

    const black = pixels.bgr24[6];
    try helpers.expectEq(black.r, 0x00);
    try helpers.expectEq(black.g, 0x00);
    try helpers.expectEq(black.b, 0x00);

    const white = pixels.bgr24[7];
    try helpers.expectEq(white.r, 0xFF);
    try helpers.expectEq(white.g, 0xFF);
    try helpers.expectEq(white.b, 0xFF);
}

test "Read a valid version 5 RGBA bitmap from file" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var the_bitmap = bmp.BMP{};

    const pixels = try the_bitmap.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try verifyBitmapRGBAV5(the_bitmap, pixels);
}

test "Read a valid version 5 RGBA bitmap from memory" {
    var memory_rgba_bitmap: [200 * 1024]u8 = undefined;
    const buffer: []const u8 = try helpers.testReadFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", memory_rgba_bitmap[0..]);

    var read_stream = zigimg.io.ReadStream.initMemory(buffer);

    var the_bitmap = bmp.BMP{};

    const pixels = try the_bitmap.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try verifyBitmapRGBAV5(the_bitmap, pixels);
}

test "Should error when reading an invalid file" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/notbmp.png");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var the_bitmap = bmp.BMP{};

    const invalid_file = the_bitmap.read(helpers.zigimg_test_allocator, &read_stream);
    try helpers.expectError(invalid_file, zigimg.Image.ReadError.InvalidData);
}

test "Write a v4 bitmap when writing an image with bgr24 pixel format" {
    const expected_colors = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xffffff, 0x00ffff, 0xff00ff, 0xffff00 };

    const image_file_name = "zigimg_bmp_v4.bmp";
    const width = expected_colors.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .bgr24);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const pixels = source_image.pixels;

    try std.testing.expect(pixels == .bgr24);
    try std.testing.expect(pixels.bgr24.len == width * height);

    // R, G, B
    pixels.bgr24[0] = zigimg.color.Bgr24.from.rgb(255, 0, 0);
    pixels.bgr24[1] = zigimg.color.Bgr24.from.rgb(0, 255, 0);
    pixels.bgr24[2] = zigimg.color.Bgr24.from.rgb(0, 0, 255);

    // Black, white
    pixels.bgr24[3] = zigimg.color.Bgr24.from.rgb(0, 0, 0);
    pixels.bgr24[4] = zigimg.color.Bgr24.from.rgb(255, 255, 255);

    // Cyan, Magenta, Yellow
    pixels.bgr24[5] = zigimg.color.Bgr24.from.rgb(0, 255, 255);
    pixels.bgr24[6] = zigimg.color.Bgr24.from.rgb(255, 0, 255);
    pixels.bgr24[7] = zigimg.color.Bgr24.from.rgb(255, 255, 0);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .bmp = .{} });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(read_file, read_buffer[0..]);

    var read_bmp = bmp.BMP{};

    const read_image_pixels = try read_bmp.read(helpers.zigimg_test_allocator, &read_stream);
    defer read_image_pixels.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_bmp.info_header == .v4);

    try helpers.expectEq(read_bmp.width(), @as(i32, @intCast(width)));
    try helpers.expectEq(read_bmp.height(), @as(i32, @intCast(height)));

    try std.testing.expect(read_image_pixels == .bgr24);

    for (expected_colors, 0..) |hex_color, index| {
        try helpers.expectEq(read_image_pixels.bgr24[index].to.u32Rgb(), hex_color);
    }
}

test "Write a v5 bitmap when writing an image with bgra32 pixel format" {
    const expected_colors = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xffffff, 0x00ffff, 0xff00ff, 0xffff00, 0x000000000 };

    const image_file_name = "zigimg_bmp_v5.bmp";
    const width = expected_colors.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .bgra32);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const pixels = source_image.pixels;

    try std.testing.expect(pixels == .bgra32);
    try std.testing.expect(pixels.bgra32.len == width * height);

    // R, G, B
    pixels.bgra32[0] = zigimg.color.Bgra32.from.rgb(255, 0, 0);
    pixels.bgra32[1] = zigimg.color.Bgra32.from.rgb(0, 255, 0);
    pixels.bgra32[2] = zigimg.color.Bgra32.from.rgb(0, 0, 255);

    // Black, white
    pixels.bgra32[3] = zigimg.color.Bgra32.from.rgb(0, 0, 0);
    pixels.bgra32[4] = zigimg.color.Bgra32.from.rgb(255, 255, 255);

    // Cyan, Magenta, Yellow
    pixels.bgra32[5] = zigimg.color.Bgra32.from.rgb(0, 255, 255);
    pixels.bgra32[6] = zigimg.color.Bgra32.from.rgb(255, 0, 255);
    pixels.bgra32[7] = zigimg.color.Bgra32.from.rgb(255, 255, 0);

    // Transparent pixel
    pixels.bgra32[8] = zigimg.color.Bgra32.from.rgba(0, 0, 0, 0);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .bmp = .{} });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(read_file, read_buffer[0..]);

    var read_bmp = bmp.BMP{};

    const read_image_pixels = try read_bmp.read(helpers.zigimg_test_allocator, &read_stream);
    defer read_image_pixels.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_bmp.info_header == .v5);

    try helpers.expectEq(read_bmp.width(), @as(i32, @intCast(width)));
    try helpers.expectEq(read_bmp.height(), @as(i32, @intCast(height)));

    try std.testing.expect(read_image_pixels == .bgra32);

    for (expected_colors, 0..) |hex_color, index| {
        try helpers.expectEq(read_image_pixels.bgra32[index].to.u32Rgb(), hex_color);
    }
}
