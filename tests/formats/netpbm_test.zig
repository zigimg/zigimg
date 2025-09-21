const helpers = @import("../helpers.zig");
const netpbm = zigimg.formats.netpbm;
const std = @import("std");
const zigimg = @import("zigimg");

test "Load ASCII PBM image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pbm_ascii.pbm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pbm_file = netpbm.PBM{};

    const pixels = try pbm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pbm_file.header.width, 8);
    try helpers.expectEq(pbm_file.header.height, 16);
    try helpers.expectEq(try pbm_file.pixelFormat(), .grayscale1);

    try std.testing.expect(pixels == .grayscale1);
    try helpers.expectEq(pixels.grayscale1[0].value, 0);
    try helpers.expectEq(pixels.grayscale1[1].value, 1);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 1);
}

test "Load binary PBM image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pbm_binary.pbm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pbm_file = netpbm.PBM{};

    const pixels = try pbm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pbm_file.header.width, 8);
    try helpers.expectEq(pbm_file.header.height, 16);
    try helpers.expectEq(try pbm_file.pixelFormat(), .grayscale1);

    try std.testing.expect(pixels == .grayscale1);
    try helpers.expectEq(pixels.grayscale1[0].value, 0);
    try helpers.expectEq(pixels.grayscale1[1].value, 1);
    try helpers.expectEq(pixels.grayscale1[15 * 8 + 7].value, 1);
}

test "Load ASCII PGM 8-bit grayscale image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pgm_ascii_grayscale8.pgm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pgm_file = netpbm.PGM{};

    const pixels = try pgm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pgm_file.header.width, 16);
    try helpers.expectEq(pgm_file.header.height, 24);
    try helpers.expectEq(try pgm_file.pixelFormat(), .grayscale8);

    try std.testing.expect(pixels == .grayscale8);
    try helpers.expectEq(pixels.grayscale8[0].value, 2);
    try helpers.expectEq(pixels.grayscale8[1].value, 5);
    try helpers.expectEq(pixels.grayscale8[383].value, 196);
}

test "Load Binary PGM 8-bit grayscale image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pgm_binary_grayscale8.pgm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pgm_file = netpbm.PGM{};

    const pixels = try pgm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pgm_file.header.width, 16);
    try helpers.expectEq(pgm_file.header.height, 24);
    try helpers.expectEq(try pgm_file.pixelFormat(), .grayscale8);

    try std.testing.expect(pixels == .grayscale8);
    try helpers.expectEq(pixels.grayscale8[0].value, 2);
    try helpers.expectEq(pixels.grayscale8[1].value, 5);
    try helpers.expectEq(pixels.grayscale8[383].value, 196);
}

test "Load ASCII PGM 16-bit grayscale image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pgm_ascii_grayscale16.pgm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pgm_file = netpbm.PGM{};

    const pixels = try pgm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pgm_file.header.width, 8);
    try helpers.expectEq(pgm_file.header.height, 16);
    try helpers.expectEq(try pgm_file.pixelFormat(), .grayscale16);

    try std.testing.expect(pixels == .grayscale16);
    try helpers.expectEq(pixels.grayscale16[0].value, 3553);
    try helpers.expectEq(pixels.grayscale16[1].value, 4319);
    try helpers.expectEq(pixels.grayscale16[127].value, 61139);
}

test "Load Binary PGM 16-bit grayscale image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/pgm_binary_grayscale16.pgm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var pgm_file = netpbm.PGM{};

    const pixels = try pgm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(pgm_file.header.width, 8);
    try helpers.expectEq(pgm_file.header.height, 16);
    try helpers.expectEq(try pgm_file.pixelFormat(), .grayscale16);

    try std.testing.expect(pixels == .grayscale16);
    try helpers.expectEq(pixels.grayscale16[0].value, 3553);
    try helpers.expectEq(pixels.grayscale16[1].value, 4319);
    try helpers.expectEq(pixels.grayscale16[127].value, 61139);
}

test "Load ASCII PPM image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/ppm_ascii_rgb24.ppm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var ppm_file = netpbm.PPM{};

    const pixels = try ppm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(ppm_file.header.width, 27);
    try helpers.expectEq(ppm_file.header.height, 27);
    try helpers.expectEq(try ppm_file.pixelFormat(), .rgb24);

    try std.testing.expect(pixels == .rgb24);

    try helpers.expectEq(pixels.rgb24[0].r, 0x34);
    try helpers.expectEq(pixels.rgb24[0].g, 0x53);
    try helpers.expectEq(pixels.rgb24[0].b, 0x9f);

    try helpers.expectEq(pixels.rgb24[1].r, 0x32);
    try helpers.expectEq(pixels.rgb24[1].g, 0x5b);
    try helpers.expectEq(pixels.rgb24[1].b, 0x96);

    try helpers.expectEq(pixels.rgb24[26].r, 0xa8);
    try helpers.expectEq(pixels.rgb24[26].g, 0x5a);
    try helpers.expectEq(pixels.rgb24[26].b, 0x78);

    try helpers.expectEq(pixels.rgb24[27].r, 0x2e);
    try helpers.expectEq(pixels.rgb24[27].g, 0x54);
    try helpers.expectEq(pixels.rgb24[27].b, 0x99);

    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].r, 0x88);
    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].g, 0xb7);
    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].b, 0x55);
}

test "Load binary PPM image" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "netpbm/ppm_binary_rgb24.ppm");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var ppm_file = netpbm.PPM{};

    const pixels = try ppm_file.read(helpers.zigimg_test_allocator, &read_stream);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(ppm_file.header.width, 27);
    try helpers.expectEq(ppm_file.header.height, 27);
    try helpers.expectEq(try ppm_file.pixelFormat(), .rgb24);

    try std.testing.expect(pixels == .rgb24);

    try helpers.expectEq(pixels.rgb24[0].r, 0x34);
    try helpers.expectEq(pixels.rgb24[0].g, 0x53);
    try helpers.expectEq(pixels.rgb24[0].b, 0x9f);

    try helpers.expectEq(pixels.rgb24[1].r, 0x32);
    try helpers.expectEq(pixels.rgb24[1].g, 0x5b);
    try helpers.expectEq(pixels.rgb24[1].b, 0x96);

    try helpers.expectEq(pixels.rgb24[26].r, 0xa8);
    try helpers.expectEq(pixels.rgb24[26].g, 0x5a);
    try helpers.expectEq(pixels.rgb24[26].b, 0x78);

    try helpers.expectEq(pixels.rgb24[27].r, 0x2e);
    try helpers.expectEq(pixels.rgb24[27].g, 0x54);
    try helpers.expectEq(pixels.rgb24[27].b, 0x99);

    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].r, 0x88);
    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].g, 0xb7);
    try helpers.expectEq(pixels.rgb24[26 * 27 + 26].b, 0x55);
}

test "Write bitmap(grayscale1) ASCII PBM file" {
    const grayscales = [_]u1{
        1, 0, 0, 1,
        1, 0, 1, 0,
        0, 1, 0, 1,
        1, 1, 1, 0,
    };

    const image_file_name = "zigimg_pbm_ascii_test.pbm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale1);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const source = source_image.pixels;
    for (grayscales, 0..) |value, index| {
        source.grayscale1[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .pbm = .{ .binary = false },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_pixels = read_image.pixels;

    try std.testing.expect(read_pixels == .grayscale1);

    for (grayscales, 0..) |grayscale_value, index| {
        try helpers.expectEq(read_pixels.grayscale1[index].value, grayscale_value);
    }
}

test "Write bitmap(Grayscale1) binary PBM file" {
    const grayscales = [_]u1{
        1, 0, 0, 1,
        1, 0, 1, 0,
        0, 1, 0, 1,
        1, 1, 1, 0,
        1, 1,
    };

    const image_file_name = "zigimg_pbm_binary_test.pbm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale1);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const source = source_image.pixels;

    for (grayscales, 0..) |value, index| {
        source.grayscale1[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .pbm = .{ .binary = true },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_pixels = read_image.pixels;

    try std.testing.expect(read_pixels == .grayscale1);

    for (grayscales, 0..) |grayscale_value, index| {
        try helpers.expectEq(read_pixels.grayscale1[index].value, grayscale_value);
    }
}

test "Write grayscale8 ASCII PGM file" {
    const grayscales = [_]u8{
        0,   29,  56,  85,  113, 142, 170, 199, 227, 255,
        227, 199, 170, 142, 113, 85,  56,  29,  0,
    };

    const image_file_name = "zigimg_pgm_ascii_test.pgm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale8);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const source = source_image.pixels;
    for (grayscales, 0..) |value, index| {
        source.grayscale8[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .pgm = .{ .binary = false },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_pixels = read_image.pixels;

    try std.testing.expect(read_pixels == .grayscale8);

    for (grayscales, 0..) |grayscale_value, index| {
        try helpers.expectEq(read_pixels.grayscale8[index].value, grayscale_value);
    }
}

test "Write grayscale8 binary PGM file" {
    const grayscales = [_]u8{
        0,   29,  56,  85,  113, 142, 170, 199, 227, 255,
        227, 199, 170, 142, 113, 85,  56,  29,  0,
    };

    const image_file_name = "zigimg_pgm_binary_test.pgm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale8);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const source = source_image.pixels;
    for (grayscales, 0..) |value, index| {
        source.grayscale8[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .pgm = .{ .binary = true },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_pixels = read_image.pixels;
    try std.testing.expect(read_pixels == .grayscale8);

    for (grayscales, 0..) |grayscale_value, index| {
        try helpers.expectEq(read_pixels.grayscale8[index].value, grayscale_value);
    }
}

test "Writing Rgb24 ASCII PPM format" {
    const expected_colors = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xffffff, 0x00ffff, 0xff00ff, 0xffff00 };

    const image_file_name = "zigimg_ppm_rgb24_ascii_test.ppm";
    const width = expected_colors.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .rgb24);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const pixels = source_image.pixels;

    try std.testing.expect(pixels == .rgb24);
    try std.testing.expect(pixels.rgb24.len == width * height);

    // R, G, B
    pixels.rgb24[0] = zigimg.color.Rgb24.from.rgb(255, 0, 0);
    pixels.rgb24[1] = zigimg.color.Rgb24.from.rgb(0, 255, 0);
    pixels.rgb24[2] = zigimg.color.Rgb24.from.rgb(0, 0, 255);

    // Black, white
    pixels.rgb24[3] = zigimg.color.Rgb24.from.rgb(0, 0, 0);
    pixels.rgb24[4] = zigimg.color.Rgb24.from.rgb(255, 255, 255);

    // Cyan, Magenta, Yellow
    pixels.rgb24[5] = zigimg.color.Rgb24.from.rgb(0, 255, 255);
    pixels.rgb24[6] = zigimg.color.Rgb24.from.rgb(255, 0, 255);
    pixels.rgb24[7] = zigimg.color.Rgb24.from.rgb(255, 255, 0);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .ppm = .{ .binary = false },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_image_pixels = read_image.pixels;

    try std.testing.expect(read_image_pixels == .rgb24);

    for (expected_colors, 0..) |hex_color, index| {
        try helpers.expectEq(read_image_pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "Writing Rgb24 binary PPM format" {
    const expected_colors = [_]u32{ 0xff0000, 0x00ff00, 0x0000ff, 0x000000, 0xffffff, 0x00ffff, 0xff00ff, 0xffff00 };

    const image_file_name = "zigimg_ppm_rgb24_binary_test.ppm";
    const width = expected_colors.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .rgb24);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    const pixels = source_image.pixels;

    try std.testing.expect(pixels == .rgb24);
    try std.testing.expect(pixels.rgb24.len == width * height);

    // R, G, B
    pixels.rgb24[0] = zigimg.color.Rgb24.from.rgb(255, 0, 0);
    pixels.rgb24[1] = zigimg.color.Rgb24.from.rgb(0, 255, 0);
    pixels.rgb24[2] = zigimg.color.Rgb24.from.rgb(0, 0, 255);

    // Black, white
    pixels.rgb24[3] = zigimg.color.Rgb24.from.rgb(0, 0, 0);
    pixels.rgb24[4] = zigimg.color.Rgb24.from.rgb(255, 255, 255);

    // Cyan, Magenta, Yellow
    pixels.rgb24[5] = zigimg.color.Rgb24.from.rgb(0, 255, 255);
    pixels.rgb24[6] = zigimg.color.Rgb24.from.rgb(255, 0, 255);
    pixels.rgb24[7] = zigimg.color.Rgb24.from.rgb(255, 255, 0);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{
        .ppm = .{ .binary = true },
    });

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_image = try zigimg.Image.fromFilePath(helpers.zigimg_test_allocator, image_file_name, read_buffer[0..]);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(read_image.width, width);
    try helpers.expectEq(read_image.height, height);

    const read_image_pixels = read_image.pixels;

    try std.testing.expect(read_image_pixels == .rgb24);

    for (expected_colors, 0..) |hex_color, index| {
        try helpers.expectEq(read_image_pixels.rgb24[index].to.u32Rgb(), hex_color);
    }
}

test "Trying to write a bitmap or grayscale Netpbm with an true color pixel format will error" {
    const image_file_name = "zigimg_ppm_rgb24_error_test.ppm";

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, 8, 1, .rgb24);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    const pixels = source_image.pixels;

    // R, G, B
    pixels.rgb24[0] = zigimg.color.Rgb24.from.rgb(255, 0, 0);
    pixels.rgb24[1] = zigimg.color.Rgb24.from.rgb(0, 255, 0);
    pixels.rgb24[2] = zigimg.color.Rgb24.from.rgb(0, 0, 255);

    // Black, white
    pixels.rgb24[3] = zigimg.color.Rgb24.from.rgb(0, 0, 0);
    pixels.rgb24[4] = zigimg.color.Rgb24.from.rgb(255, 255, 255);

    // Cyan, Magenta, Yellow
    pixels.rgb24[5] = zigimg.color.Rgb24.from.rgb(0, 255, 255);
    pixels.rgb24[6] = zigimg.color.Rgb24.from.rgb(255, 0, 255);
    pixels.rgb24[7] = zigimg.color.Rgb24.from.rgb(255, 255, 0);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .pbm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .pgm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }
}

test "Trying to write a bitmap or true color Netpbm with a 8-bit grayscale pixel format will error" {
    const grayscales = [_]u8{
        0,   29,  56,  85,  113, 142, 170, 199, 227, 255,
        227, 199, 170, 142, 113, 85,  56,  29,  0,
    };

    const image_file_name = "zigimg_pgm_error_test.pgm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale8);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    const source = source_image.pixels;
    for (grayscales, 0..) |value, index| {
        source.grayscale8[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .pbm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .ppm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }
}

test "Trying to write a grayscale or true color Netbpm with a 1-bit grayscale pixel format will error" {
    const grayscales = [_]u1{
        1, 0, 0, 1,
        1, 0, 1, 0,
        0, 1, 0, 1,
        1, 1, 1, 0,
        1, 1,
    };

    const image_file_name = "zigimg_pbm_error_test.pbm";
    const width = grayscales.len;
    const height = 1;

    var source_image = try zigimg.Image.create(helpers.zigimg_test_allocator, width, height, .grayscale1);
    defer source_image.deinit(helpers.zigimg_test_allocator);

    defer {
        std.fs.cwd().deleteFile(image_file_name) catch unreachable;
    }

    const source = source_image.pixels;

    for (grayscales, 0..) |value, index| {
        source.grayscale1[index].value = value;
    }

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .pgm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }

    {
        const write_error = source_image.writeToFilePath(helpers.zigimg_test_allocator, image_file_name, write_buffer[0..], .{ .ppm = .{} });
        try std.testing.expectError(zigimg.Image.WriteError.Unsupported, write_error);
    }
}
