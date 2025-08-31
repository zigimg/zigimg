const std = @import("std");
const helpers = @import("../helpers.zig");

const jpeg = @import("../../src/formats/jpeg.zig");
const color = @import("../../src/color.zig");
const Image = @import("../../src/Image.zig");
const ImageReadError = Image.ReadError;
const testing = std.testing;

test "Should error on non JPEG images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?color.PixelStorage = null;
    const invalidFile = jpeg_file.read(&stream_source, &pixels_opt);
    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectError(invalidFile, ImageReadError.InvalidData);
}

test "Read JFIF header properly and decode simple Huffman stream" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/huff_simple0.jpg");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?color.PixelStorage = null;
    const frame = try jpeg_file.read(&stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 8);
    try helpers.expectEq(frame.frame_header.width, 16);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 3);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .rgb24);
    }
}

test "Read the tuba properly" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/tuba.jpg");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?color.PixelStorage = null;
    const frame = try jpeg_file.read(&stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 512);
    try helpers.expectEq(frame.frame_header.width, 512);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 3);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .rgb24);

        // Just for fun, let's sample a few pixels. :^)
        try helpers.expectEq(pixels.rgb24[(126 * 512 + 163)], color.Rgb24.from.rgb(0xAC, 0x78, 0x54));
        try helpers.expectEq(pixels.rgb24[(265 * 512 + 284)], color.Rgb24.from.rgb(0x37, 0x30, 0x33));
        try helpers.expectEq(pixels.rgb24[(431 * 512 + 300)], color.Rgb24.from.rgb(0xFE, 0xE7, 0xC9));
    }
}

test "Read grayscale images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/grayscale_sample0.jpg");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?color.PixelStorage = null;
    const frame = try jpeg_file.read(&stream_source, &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(frame.frame_header.height, 32);
    try helpers.expectEq(frame.frame_header.width, 32);
    try helpers.expectEq(frame.frame_header.sample_precision, 8);
    try helpers.expectEq(frame.frame_header.components.len, 1);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .grayscale8);

        // Just for fun, let's sample a few pixels. :^)
        try helpers.expectEq(pixels.grayscale8[(0 * 32 + 0)], color.Grayscale8{ .value = 0x00 });
        try helpers.expectEq(pixels.grayscale8[(15 * 32 + 15)], color.Grayscale8{ .value = 0xaa });
        try helpers.expectEq(pixels.grayscale8[(28 * 32 + 28)], color.Grayscale8{ .value = 0xf7 });
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
            var tst_file = try idir.openFile(entry.name, .{ .mode = .read_only });
            defer tst_file.close();

            var stream = Image.Stream{ .file = tst_file };

            var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
            defer jpeg_file.deinit();

            var pixels_opt: ?color.PixelStorage = null;
            _ = try jpeg_file.read(&stream, &pixels_opt);

            defer {
                if (pixels_opt) |pixels| {
                    pixels.deinit(helpers.zigimg_test_allocator);
                }
            }

            try testing.expect(pixels_opt != null);
            if (pixels_opt) |pixels| {
                try testing.expect(pixels == .rgb24);

                // Just for fun, let's sample a few pixels. :^)
                const actual: color.Colorf32 = pixels.rgb24[(0 * 32 + 0)].to.color(color.Colorf32);
                try testing.expectApproxEqAbs(@as(f32, 1.0), actual.r, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 1.0), actual.g, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 0.0), actual.b, 0.05);

                const actual1: color.Colorf32 = pixels.rgb24[(13 * 32 + 9)].to.color(color.Colorf32);
                try testing.expectApproxEqAbs(@as(f32, 0.71), actual1.r, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 0.55), actual1.g, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 0.0), actual1.b, 0.05);

                const actual2: color.Colorf32 = pixels.rgb24[(25 * 32 + 18)].to.color(color.Colorf32);
                try testing.expectApproxEqAbs(@as(f32, 0.42), actual2.r, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 0.19), actual2.g, 0.05);
                try testing.expectApproxEqAbs(@as(f32, 0.39), actual2.b, 0.05);
            }
            std.debug.print("OK\n", .{});
        }
    }
}

test "Read progressive jpeg with restart intervals" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "jpeg/tuba_restart_prog.jpg");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var jpeg_file = jpeg.JPEG.init(helpers.zigimg_test_allocator);
    defer jpeg_file.deinit();

    var pixels_opt: ?color.PixelStorage = null;
    const frame = try jpeg_file.read(&stream_source, &pixels_opt);

    _ = frame;

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try testing.expect(pixels_opt != null);
}

fn averageDelta(img0: Image, img1: Image) !f32 {
    try testing.expectEqual(img0.width, img1.width);
    try testing.expectEqual(img0.height, img1.height);

    const w = img0.width;
    const h = img0.height;

    var sum: f64 = 0.0;
    var n: usize = 0;

    switch (img0.pixelFormat()) {
        .rgb24 => {
            try testing.expectEqual(@as(@TypeOf(img0.pixelFormat()), img1.pixelFormat()), .rgb24);
            const p0 = img0.pixels.rgb24;
            const p1 = img1.pixels.rgb24;
            for (0..h) |y| {
                for (0..w) |x| {
                    const idx = y * w + x;
                    sum += @abs(@as(f64, @floatFromInt(p0[idx].r)) - @as(f64, @floatFromInt(p1[idx].r)));
                    sum += @abs(@as(f64, @floatFromInt(p0[idx].g)) - @as(f64, @floatFromInt(p1[idx].g)));
                    sum += @abs(@as(f64, @floatFromInt(p0[idx].b)) - @as(f64, @floatFromInt(p1[idx].b)));
                    n += 3;
                }
            }
        },
        .grayscale8 => {
            try testing.expectEqual(@as(@TypeOf(img0.pixelFormat()), img1.pixelFormat()), .grayscale8);
            const p0 = img0.pixels.grayscale8;
            const p1 = img1.pixels.grayscale8;
            for (0..h) |y| {
                for (0..w) |x| {
                    const idx = y * w + x;
                    sum += @abs(@as(f64, @floatFromInt(p0[idx].value)) - @as(f64, @floatFromInt(p1[idx].value)));
                    n += 1;
                }
            }
        },
        else => @panic("unsupported pixel format in averageDelta"),
    }

    return @as(f32, @floatCast(sum / @as(f64, @floatFromInt(n))));
}

fn encodeDecode(img: *const Image, quality: u8) !Image {
    var arena = std.heap.ArenaAllocator.init(helpers.zigimg_test_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Generous buffer for small test images
    const buf = try alloc.alloc(u8, 1 << 20);
    defer alloc.free(buf);

    const encoded = try img.writeToMemory(buf, .{ .jpeg = .{ .quality = quality } });
    return try Image.fromMemory(helpers.zigimg_test_allocator, encoded);
}

test "JPEG writer round-trip RGB average delta (q=60)" {
    var img = try Image.create(helpers.zigimg_test_allocator, 128, 96, .rgb24);
    defer img.deinit();

    // Fill with a smooth gradient and some color variation
    for (0..img.height) |y| {
        for (0..img.width) |x| {
            const fx = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(img.width - 1));
            const fy = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(img.height - 1));
            const r: u8 = @intFromFloat(fx * 255.0);
            const g: u8 = @intFromFloat(fy * 255.0);
            const b: u8 = @intFromFloat((1.0 - 0.5 * fx - 0.5 * fy) * 255.0);
            img.pixels.rgb24[y * img.width + x] = color.Rgb24.from.rgb(r, g, b);
        }
    }

    var decoded = try encodeDecode(&img, 60);
    defer decoded.deinit();
    const avg = try averageDelta(img, decoded);
    std.debug.print("JPEG writer RGB q=60 avg_delta={d:.2} (<= 3.0)\n", .{avg});
    try testing.expect(avg <= 3.0);
}

test "JPEG writer round-trip grayscale average delta (q=60)" {
    var img = try Image.create(helpers.zigimg_test_allocator, 64, 64, .grayscale8);
    defer img.deinit();
    for (0..img.height) |y| {
        for (0..img.width) |x| {
            const v: u8 = @intCast((x + y) % 256);
            img.pixels.grayscale8[y * img.width + x] = .{ .value = v };
        }
    }

    var decoded = try encodeDecode(&img, 60);
    defer decoded.deinit();
    const avg = try averageDelta(img, decoded);
    std.debug.print("JPEG writer Gray q=60 avg_delta={d:.2} (<= 3.0)\n", .{avg});
    try testing.expect(avg <= 3.0);
}
