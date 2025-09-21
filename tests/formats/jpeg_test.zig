const helpers = @import("../helpers.zig");
const jpeg = zigimg.formats.jpeg;
const std = @import("std");
const zigimg = @import("zigimg");

test "Should error on non JPEG images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?zigimg.color.PixelStorage = null;
    const invalidFile = jpeg_file.read(&read_stream, &pixels_opt);
    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalidFile, zigimg.Image.ReadError.InvalidData);
}

test "Read JFIF header properly and decode simple Huffman stream" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/huff_simple0.jpg");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?zigimg.color.PixelStorage = null;
    const frame = try jpeg_file.read(&read_stream, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 8);
    try helpers.expectEq(frame.frame_header.width, 16);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 3);

    try std.testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try std.testing.expect(pixels == .rgb24);
    }
}

test "Read the tuba properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/tuba.jpg");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?zigimg.color.PixelStorage = null;
    const frame = try jpeg_file.read(&read_stream, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 512);
    try helpers.expectEq(frame.frame_header.width, 512);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 3);

    try std.testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try std.testing.expect(pixels == .rgb24);

        // Just for fun, let's sample a few pixels. :^)
        try helpers.expectEq(pixels.rgb24[(126 * 512 + 163)], zigimg.color.Rgb24.from.rgb(0xAC, 0x78, 0x54));
        try helpers.expectEq(pixels.rgb24[(265 * 512 + 284)], zigimg.color.Rgb24.from.rgb(0x37, 0x30, 0x33));
        try helpers.expectEq(pixels.rgb24[(431 * 512 + 300)], zigimg.color.Rgb24.from.rgb(0xFE, 0xE7, 0xC9));
    }
}

test "Read grayscale images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/grayscale_sample0.jpg");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?zigimg.color.PixelStorage = null;
    const frame = try jpeg_file.read(&read_stream, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 32);
    try helpers.expectEq(frame.frame_header.width, 32);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 1);

    try std.testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try std.testing.expect(pixels == .grayscale8);

        // Just for fun, let's sample a few pixels. :^)
        try helpers.expectEq(pixels.grayscale8[(0 * 32 + 0)], zigimg.color.Grayscale8{ .value = 0x00 });
        try helpers.expectEq(pixels.grayscale8[(15 * 32 + 15)], zigimg.color.Grayscale8{ .value = 0xaa });
        try helpers.expectEq(pixels.grayscale8[(28 * 32 + 28)], zigimg.color.Grayscale8{ .value = 0xf7 });
    }
}

test "Read subsampling images" {
    var testdir = std.fs.cwd().openDir(helpers.fixtures_path ++ "jpeg/", .{ .access_sub_paths = false, .no_follow = true, .iterate = true }) catch null;
    if (testdir) |*idir| {
        defer idir.close();

        var it = idir.iterate();
        std.debug.print("\n", .{});
        while (try it.next()) |entry| {
            if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".jpg") or !std.mem.startsWith(u8, entry.name, "subsampling_")) continue;

            std.debug.print("Testing file {s} ... ", .{entry.name});
            var test_file = try idir.openFile(entry.name, .{ .mode = .read_only });
            defer test_file.close();

            var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
            var read_stream = zigimg.io.ReadStream.initFile(test_file, read_buffer[0..]);

            var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
            defer jpeg_file.deinit();

            var pixels_opt: ?zigimg.color.PixelStorage = null;
            _ = try jpeg_file.read(&read_stream, &pixels_opt);

            defer {
                if (pixels_opt) |pixels| {
                    pixels.deinit(helpers.zigimg_test_allocator);
                }
            }

            try std.testing.expect(pixels_opt != null);
            if (pixels_opt) |pixels| {
                try std.testing.expect(pixels == .rgb24);

                // Just for fun, let's sample a few pixels. :^)
                const actual: zigimg.color.Colorf32 = pixels.rgb24[(0 * 32 + 0)].to.color(zigimg.color.Colorf32);
                try std.testing.expectApproxEqAbs(@as(f32, 1.0), actual.r, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 1.0), actual.g, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 0.0), actual.b, 0.05);

                const actual1: zigimg.color.Colorf32 = pixels.rgb24[(13 * 32 + 9)].to.color(zigimg.color.Colorf32);
                try std.testing.expectApproxEqAbs(@as(f32, 0.71), actual1.r, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 0.55), actual1.g, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 0.0), actual1.b, 0.05);

                const actual2: zigimg.color.Colorf32 = pixels.rgb24[(25 * 32 + 18)].to.color(zigimg.color.Colorf32);
                try std.testing.expectApproxEqAbs(@as(f32, 0.42), actual2.r, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 0.19), actual2.g, 0.05);
                try std.testing.expectApproxEqAbs(@as(f32, 0.39), actual2.b, 0.05);
            }
            std.debug.print("OK\n", .{});
        }
    }
}

test "Read progressive jpeg with restart intervals" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/tuba_restart_prog.jpg");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?zigimg.color.PixelStorage = null;
    const frame = try jpeg_file.read(&read_stream, &pixels_opt);

    _ = frame;

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try std.testing.expect(pixels_opt != null);
}
