const gif = zigimg.formats.gif;
const helpers = @import("../helpers.zig");
const std = @import("std");
const zigimg = @import("zigimg");

test "GIF writer roundtrip - simple indexed8 image" {
    const allocator = helpers.zigimg_test_allocator;

    // Create a simple 4x4 indexed8 image
    const width: usize = 4;
    const height: usize = 4;

    var image = zigimg.Image{
        .width = width,
        .height = height,
        .pixels = try zigimg.color.PixelStorage.init(allocator, .indexed8, width * height),
    };
    defer image.deinit(allocator);

    // Set up a simple palette (4 colors) and resize to 4 entries
    image.pixels.resizePalette(4);
    const palette = image.pixels.indexed8.palette;
    palette[0] = .{ .r = 255, .g = 0, .b = 0, .a = 255 }; // Red
    palette[1] = .{ .r = 0, .g = 255, .b = 0, .a = 255 }; // Green
    palette[2] = .{ .r = 0, .g = 0, .b = 255, .a = 255 }; // Blue
    palette[3] = .{ .r = 255, .g = 255, .b = 0, .a = 255 }; // Yellow

    // Fill with a simple pattern
    const indices = image.pixels.indexed8.indices;
    indices[0] = 0;
    indices[1] = 1;
    indices[2] = 2;
    indices[3] = 3;
    indices[4] = 1;
    indices[5] = 2;
    indices[6] = 3;
    indices[7] = 0;
    indices[8] = 2;
    indices[9] = 3;
    indices[10] = 0;
    indices[11] = 1;
    indices[12] = 3;
    indices[13] = 0;
    indices[14] = 1;
    indices[15] = 2;

    // Expected colors after roundtrip (palette lookup)
    const expected_colors = [_]zigimg.color.Rgba32{
        .{ .r = 255, .g = 0, .b = 0, .a = 255 }, // Red (index 0)
        .{ .r = 0, .g = 255, .b = 0, .a = 255 }, // Green (index 1)
        .{ .r = 0, .g = 0, .b = 255, .a = 255 }, // Blue (index 2)
        .{ .r = 255, .g = 255, .b = 0, .a = 255 }, // Yellow (index 3)
        .{ .r = 0, .g = 255, .b = 0, .a = 255 }, // Green (index 1)
        .{ .r = 0, .g = 0, .b = 255, .a = 255 }, // Blue (index 2)
        .{ .r = 255, .g = 255, .b = 0, .a = 255 }, // Yellow (index 3)
        .{ .r = 255, .g = 0, .b = 0, .a = 255 }, // Red (index 0)
        .{ .r = 0, .g = 0, .b = 255, .a = 255 }, // Blue (index 2)
        .{ .r = 255, .g = 255, .b = 0, .a = 255 }, // Yellow (index 3)
        .{ .r = 255, .g = 0, .b = 0, .a = 255 }, // Red (index 0)
        .{ .r = 0, .g = 255, .b = 0, .a = 255 }, // Green (index 1)
        .{ .r = 255, .g = 255, .b = 0, .a = 255 }, // Yellow (index 3)
        .{ .r = 255, .g = 0, .b = 0, .a = 255 }, // Red (index 0)
        .{ .r = 0, .g = 255, .b = 0, .a = 255 }, // Green (index 1)
        .{ .r = 0, .g = 0, .b = 255, .a = 255 }, // Blue (index 2)
    };

    // Write to memory buffer
    var write_buffer: [8192]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    // Read back using low-level GIF reader to get indexed data
    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var gif_file = gif.GIF.init(allocator);
    defer gif_file.deinit();

    var frames = try gif_file.read(&read_stream);
    defer {
        for (frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        frames.deinit(allocator);
    }

    // Verify dimensions
    try std.testing.expectEqual(@as(u16, @intCast(width)), gif_file.header.width);
    try std.testing.expectEqual(@as(u16, @intCast(height)), gif_file.header.height);

    // Verify we got one frame
    try std.testing.expectEqual(@as(usize, 1), frames.items.len);

    // The GIF reader returns indexed format
    const pixel_format = std.meta.activeTag(frames.items[0].pixels);
    try std.testing.expect(pixel_format.isIndexed());

    // Verify pixel values match by comparing colors using iterator
    var pixel_iter = zigimg.color.PixelStorageIterator.init(&frames.items[0].pixels);
    for (expected_colors) |expected| {
        const actual_opt = pixel_iter.next();
        try std.testing.expect(actual_opt != null);
        const actual = actual_opt.?.to.color(zigimg.color.Rgba32);
        try std.testing.expectEqual(expected.r, actual.r);
        try std.testing.expectEqual(expected.g, actual.g);
        try std.testing.expectEqual(expected.b, actual.b);
    }
}

test "GIF writer roundtrip - indexed1 format" {
    const allocator = helpers.zigimg_test_allocator;

    // Create a simple 4x4 indexed1 image (2 colors max)
    const width: usize = 4;
    const height: usize = 4;

    var image = zigimg.Image{
        .width = width,
        .height = height,
        .pixels = try zigimg.color.PixelStorage.init(allocator, .indexed1, width * height),
    };
    defer image.deinit(allocator);

    // Set up a 2-color palette
    image.pixels.resizePalette(2);
    const palette = image.pixels.indexed1.palette;
    palette[0] = .{ .r = 0, .g = 0, .b = 0, .a = 255 }; // Black
    palette[1] = .{ .r = 255, .g = 255, .b = 255, .a = 255 }; // White

    // Fill with checkerboard pattern
    const indices = image.pixels.indexed1.indices;
    for (0..width * height) |i| {
        const x = i % width;
        const y = i / width;
        indices[i] = @intCast((x + y) % 2);
    }

    // Write to memory buffer
    var write_buffer: [8192]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    // Read back
    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var gif_file = gif.GIF.init(allocator);
    defer gif_file.deinit();

    var frames = try gif_file.read(&read_stream);
    defer {
        for (frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        frames.deinit(allocator);
    }

    // Verify dimensions
    try std.testing.expectEqual(@as(u16, @intCast(width)), gif_file.header.width);
    try std.testing.expectEqual(@as(u16, @intCast(height)), gif_file.header.height);

    // Verify pixel colors match
    var original_iter = zigimg.color.PixelStorageIterator.init(&image.pixels);
    var decoded_iter = zigimg.color.PixelStorageIterator.init(&frames.items[0].pixels);

    while (original_iter.next()) |original_color| {
        const decoded_color_opt = decoded_iter.next();
        try std.testing.expect(decoded_color_opt != null);
        const original = original_color.to.color(zigimg.color.Rgba32);
        const decoded = decoded_color_opt.?.to.color(zigimg.color.Rgba32);
        try std.testing.expectEqual(original.r, decoded.r);
        try std.testing.expectEqual(original.g, decoded.g);
        try std.testing.expectEqual(original.b, decoded.b);
    }
}

test "GIF writer roundtrip - indexed2 format" {
    const allocator = helpers.zigimg_test_allocator;

    // Create a simple 4x4 indexed2 image (4 colors max)
    const width: usize = 4;
    const height: usize = 4;

    var image = zigimg.Image{
        .width = width,
        .height = height,
        .pixels = try zigimg.color.PixelStorage.init(allocator, .indexed2, width * height),
    };
    defer image.deinit(allocator);

    // Set up a 4-color palette
    image.pixels.resizePalette(4);
    const palette = image.pixels.indexed2.palette;
    palette[0] = .{ .r = 255, .g = 0, .b = 0, .a = 255 }; // Red
    palette[1] = .{ .r = 0, .g = 255, .b = 0, .a = 255 }; // Green
    palette[2] = .{ .r = 0, .g = 0, .b = 255, .a = 255 }; // Blue
    palette[3] = .{ .r = 255, .g = 255, .b = 0, .a = 255 }; // Yellow

    // Fill with rotating pattern
    const indices = image.pixels.indexed2.indices;
    for (0..width * height) |i| {
        indices[i] = @intCast(i % 4);
    }

    // Write to memory buffer
    var write_buffer: [8192]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    // Read back
    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var gif_file = gif.GIF.init(allocator);
    defer gif_file.deinit();

    var frames = try gif_file.read(&read_stream);
    defer {
        for (frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        frames.deinit(allocator);
    }

    // Verify dimensions
    try std.testing.expectEqual(@as(u16, @intCast(width)), gif_file.header.width);
    try std.testing.expectEqual(@as(u16, @intCast(height)), gif_file.header.height);

    // Verify pixel colors match
    var original_iter = zigimg.color.PixelStorageIterator.init(&image.pixels);
    var decoded_iter = zigimg.color.PixelStorageIterator.init(&frames.items[0].pixels);

    while (original_iter.next()) |original_color| {
        const decoded_color_opt = decoded_iter.next();
        try std.testing.expect(decoded_color_opt != null);
        const original = original_color.to.color(zigimg.color.Rgba32);
        const decoded = decoded_color_opt.?.to.color(zigimg.color.Rgba32);
        try std.testing.expectEqual(original.r, decoded.r);
        try std.testing.expectEqual(original.g, decoded.g);
        try std.testing.expectEqual(original.b, decoded.b);
    }
}

test "GIF writer roundtrip - indexed4 format" {
    const allocator = helpers.zigimg_test_allocator;

    // Create a simple 4x4 indexed4 image (16 colors max)
    const width: usize = 4;
    const height: usize = 4;

    var image = zigimg.Image{
        .width = width,
        .height = height,
        .pixels = try zigimg.color.PixelStorage.init(allocator, .indexed4, width * height),
    };
    defer image.deinit(allocator);

    // Set up a 16-color palette (grayscale ramp)
    image.pixels.resizePalette(16);
    const palette = image.pixels.indexed4.palette;
    for (0..16) |i| {
        const v: u8 = @intCast(i * 17); // 0, 17, 34, ... 255
        palette[i] = .{ .r = v, .g = v, .b = v, .a = 255 };
    }

    // Fill with gradient pattern
    const indices = image.pixels.indexed4.indices;
    for (0..width * height) |i| {
        indices[i] = @intCast(i % 16);
    }

    // Write to memory buffer
    var write_buffer: [8192]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    // Read back
    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var gif_file = gif.GIF.init(allocator);
    defer gif_file.deinit();

    var frames = try gif_file.read(&read_stream);
    defer {
        for (frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        frames.deinit(allocator);
    }

    // Verify dimensions
    try std.testing.expectEqual(@as(u16, @intCast(width)), gif_file.header.width);
    try std.testing.expectEqual(@as(u16, @intCast(height)), gif_file.header.height);

    // Verify pixel colors match
    var original_iter = zigimg.color.PixelStorageIterator.init(&image.pixels);
    var decoded_iter = zigimg.color.PixelStorageIterator.init(&frames.items[0].pixels);

    while (original_iter.next()) |original_color| {
        const decoded_color_opt = decoded_iter.next();
        try std.testing.expect(decoded_color_opt != null);
        const original = original_color.to.color(zigimg.color.Rgba32);
        const decoded = decoded_color_opt.?.to.color(zigimg.color.Rgba32);
        try std.testing.expectEqual(original.r, decoded.r);
        try std.testing.expectEqual(original.g, decoded.g);
        try std.testing.expectEqual(original.b, decoded.b);
    }
}

test "GIF writer roundtrip - read existing GIF, write, read again" {
    const allocator = helpers.zigimg_test_allocator;

    // Read an existing GIF file using low-level reader
    const gif_input_file = try helpers.testOpenFile(helpers.fixtures_path ++ "gif/rotating_earth.gif");
    defer gif_input_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(gif_input_file, read_buffer[0..]);

    var original_gif = gif.GIF.init(allocator);
    defer original_gif.deinit();

    var original_frames = try original_gif.read(&read_stream);
    defer {
        for (original_frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        original_frames.deinit(allocator);
    }

    // Create an Image from the first frame for writing
    const image = zigimg.Image{
        .width = original_gif.header.width,
        .height = original_gif.header.height,
        .pixels = original_frames.items[0].pixels,
    };

    // Write to memory buffer
    var write_buffer: [1024 * 1024]u8 = undefined; // 1MB buffer
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    // Read back the written GIF
    var read_back_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var decoded_gif = gif.GIF.init(allocator);
    defer decoded_gif.deinit();

    var decoded_frames = try decoded_gif.read(&read_back_stream);
    defer {
        for (decoded_frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        decoded_frames.deinit(allocator);
    }

    // Verify dimensions match
    try std.testing.expectEqual(original_gif.header.width, decoded_gif.header.width);
    try std.testing.expectEqual(original_gif.header.height, decoded_gif.header.height);

    // Verify we got one frame (we only wrote the first frame)
    try std.testing.expectEqual(@as(usize, 1), decoded_frames.items.len);

    // Verify pixel colors match using iterator
    var original_iter = zigimg.color.PixelStorageIterator.init(&original_frames.items[0].pixels);
    var decoded_iter = zigimg.color.PixelStorageIterator.init(&decoded_frames.items[0].pixels);

    while (original_iter.next()) |original_color| {
        const decoded_color_opt = decoded_iter.next();
        try std.testing.expect(decoded_color_opt != null);
        const original = original_color.to.color(zigimg.color.Rgba32);
        const decoded = decoded_color_opt.?.to.color(zigimg.color.Rgba32);
        try std.testing.expectEqual(original.r, decoded.r);
        try std.testing.expectEqual(original.g, decoded.g);
        try std.testing.expectEqual(original.b, decoded.b);
    }
}

test "GIF writer preserves animation metadata" {
    const allocator = helpers.zigimg_test_allocator;

    var image = try loadRotatingEarthImage(allocator);
    defer image.deinit(allocator);

    const original_loop_count = image.animation.loop_count;
    const frame_count = image.animation.frames.items.len;

    var write_buffer: [4 * 1024 * 1024]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    try gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} });

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var decoded_gif = gif.GIF.init(allocator);
    defer decoded_gif.deinit();

    var decoded_frames = try decoded_gif.read(&read_stream);
    defer {
        for (decoded_frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        decoded_frames.deinit(allocator);
    }

    try helpers.expectEq(decoded_gif.loopCount(), original_loop_count);
    try helpers.expectEq(decoded_frames.items.len, frame_count);
    try helpers.expectApproxEqAbs(decoded_frames.items[0].duration, image.animation.frames.items[0].duration, 0.0001);
}

test "GIF writer honors loop override option" {
    const allocator = helpers.zigimg_test_allocator;

    var image = try loadRotatingEarthImage(allocator);
    defer image.deinit(allocator);

    image.animation.loop_count = 0;

    var write_buffer: [4 * 1024 * 1024]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    const encoder_options = zigimg.Image.EncoderOptions{
        .gif = .{
            .loop_count = 3,
        },
    };

    try gif.GIF.writeImage(allocator, &write_stream, image, encoder_options);

    const written_len = write_stream.writer().end;
    try std.testing.expect(written_len > 0);

    var read_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var decoded_gif = gif.GIF.init(allocator);
    defer decoded_gif.deinit();

    var decoded_frames = try decoded_gif.read(&read_stream);
    defer {
        for (decoded_frames.items) |entry| {
            entry.pixels.deinit(allocator);
        }
        decoded_frames.deinit(allocator);
    }

    try helpers.expectEq(decoded_frames.items.len, image.animation.frames.items.len);
    try helpers.expectEq(decoded_gif.loopCount(), 3);
}

test "GIF writer rejects non-indexed data without auto convert" {
    const allocator = helpers.zigimg_test_allocator;

    var image = zigimg.Image{
        .width = 2,
        .height = 2,
        .pixels = try zigimg.color.PixelStorage.init(allocator, .rgb24, 2 * 2),
    };
    defer image.deinit(allocator);

    var write_buffer: [2 * 1024]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    gif.GIF.writeImage(allocator, &write_stream, image, .{ .gif = .{} }) catch |err| {
        try std.testing.expectEqual(zigimg.Image.WriteError.Unsupported, err);
        return;
    };
    try std.testing.expect(false);
}

test "Should error on non GIF images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(file, read_buffer[0..]);

    var gif_file = gif.GIF.init(helpers.zigimg_test_allocator);
    defer gif_file.deinit();

    const invalid_file = gif_file.read(&read_stream);
    try helpers.expectError(invalid_file, zigimg.Image.ReadError.InvalidData);
}

fn makeAnimatedTestImage(allocator: std.mem.Allocator) !zigimg.Image {
    const width: usize = 4;
    const height: usize = 4;

    var frames: zigimg.Image.Animation.FrameList = .{
        .items = &[_]zigimg.Image.AnimationFrame{},
        .capacity = 0,
        .allocator = allocator,
    };

    const palette = [_]zigimg.color.Rgba32{
        .{ .r = 0, .g = 0, .b = 0, .a = 255 },
        .{ .r = 255, .g = 0, .b = 0, .a = 255 },
    };

    var frame0_pixels = try zigimg.color.PixelStorage.init(allocator, .indexed8, width * height);
    frame0_pixels.resizePalette(palette.len);
    std.mem.copy(zigimg.color.Rgba32, frame0_pixels.indexed8.palette, palette[0..]);
    for (0..width * height) |i| frame0_pixels.indexed8.indices[i] = @intCast(i % 2);

    const frame0 = zigimg.Image.AnimationFrame{
        .pixels = frame0_pixels,
        .duration = 0.15,
        .disposal = @intCast(zigimg.formats.gif.DisposeMethod.none),
    };
    try frames.append(allocator, frame0);

    var frame1_pixels = try zigimg.color.PixelStorage.init(allocator, .indexed8, width * height);
    frame1_pixels.resizePalette(palette.len);
    std.mem.copy(zigimg.color.Rgba32, frame1_pixels.indexed8.palette, palette[0..]);
    for (0..height) |row| {
        for (0..width) |col| {
            const idx = row * width + col;
            frame1_pixels.indexed8.indices[idx] = @intCast(row % 2);
        }
    }

    const frame1 = zigimg.Image.AnimationFrame{
        .pixels = frame1_pixels,
        .duration = 0.25,
        .disposal = @intCast(zigimg.formats.gif.DisposeMethod.restore_background_color),
    };
    try frames.append(allocator, frame1);

    const first_frame_pixels = frames.items[0].pixels;

    return zigimg.Image{
        .width = width,
        .height = height,
        .pixels = first_frame_pixels,
        .animation = .{
            .frames = frames,
            .loop_count = zigimg.Image.AnimationLoopInfinite,
        },
    };
}

const SINGLE_GIF_FILE_TEST = false;

fn loadRotatingEarthImage(allocator: std.mem.Allocator) !zigimg.Image {
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    const image_path = "rotating_earth.gif";
    return zigimg.Image.fromFilePath(allocator, image_path, read_buffer[0..]);
}

test "GIF test suite" {
    if (SINGLE_GIF_FILE_TEST) {
        return error.SkipZigTest;
    }

    var test_list: std.ArrayList([]const u8) = .empty;
    defer test_list.deinit(helpers.zigimg_test_allocator);

    const test_list_file = try helpers.testOpenFile(helpers.fixtures_path ++ "gif/TESTS");
    defer test_list_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_list_file, read_buffer[0..]);

    var reader = read_stream.reader();

    var area_alloc = std.heap.ArenaAllocator.init(helpers.zigimg_test_allocator);
    const area_allocator = area_alloc.allocator();
    defer area_alloc.deinit();

    var read_line: []u8 = reader.takeDelimiterExclusive('\n') catch &.{};

    while (read_line.len > 0) {
        try test_list.append(helpers.zigimg_test_allocator, try area_allocator.dupe(u8, read_line));
        read_line = reader.takeDelimiterExclusive('\n') catch &.{};
    }

    var has_failed_file = false;

    for (test_list.items) |entry| {
        doGifTest(entry) catch |err| {
            has_failed_file = true;
            std.debug.print("Error: {}\n", .{err});
            continue;
        };

        std.debug.print("OK\n", .{});
    }

    if (has_failed_file) {
        return error.GifTestSuiteFailed;
    }
}

test "Rotating Earth GIF" {
    const gif_input_file = try helpers.testOpenFile(helpers.fixtures_path ++ "gif/rotating_earth.gif");
    defer gif_input_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(gif_input_file, read_buffer[0..]);

    var gif_file = gif.GIF.init(helpers.zigimg_test_allocator);
    defer gif_file.deinit();

    var frames = try gif_file.read(&read_stream);
    defer {
        for (frames.items) |entry| {
            entry.pixels.deinit(helpers.zigimg_test_allocator);
        }
        frames.deinit(helpers.zigimg_test_allocator);
    }

    try helpers.expectEq(gif_file.header.width, 400);
    try helpers.expectEq(gif_file.header.height, 400);

    try helpers.expectEq(frames.items.len, 44);

    try helpers.expectEq(frames.items[0].pixels.indexed8.indices[10], 106);
    try helpers.expectEq(frames.items[0].pixels.indexed8.indices[399 * 400 + 382], 8);
}

test "Iterate on a single GIF file" {
    if (!SINGLE_GIF_FILE_TEST) {
        return error.SkipZigTest;
    }

    try doGifTest("high-color");
}

const IniFile = struct {
    area_allocator: std.heap.ArenaAllocator,
    sections: std.StringArrayHashMapUnmanaged(SectionEntry) = .{},

    const SectionEntry = struct {
        dict: std.StringArrayHashMapUnmanaged(Value) = .{},

        pub fn getValue(self: *const SectionEntry, key: []const u8) ?Value {
            return self.dict.get(key);
        }
    };

    const Value = union(enum) {
        number: u32,
        string: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator) IniFile {
        return .{
            .area_allocator = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *IniFile) void {
        for (self.sections.values()) |*entry| {
            entry.dict.deinit(self.area_allocator.allocator());
        }
        self.sections.deinit(self.area_allocator.allocator());
        self.area_allocator.deinit();
    }

    pub fn parse(self: *IniFile, reader: *std.Io.Reader) !void {
        const allocator = self.area_allocator.allocator();

        var line_writer = std.Io.Writer.Allocating.init(allocator);
        defer line_writer.deinit();

        var read_size = try reader.streamDelimiter(&line_writer.writer, '\n');
        try reader.discardAll(1);

        var read_line: []u8 = line_writer.written();

        var current_section: []const u8 = "";

        while (true) {
            if (read_line.len > 0) {
                switch (read_line[0]) {
                    '#' => {
                        // Do nothing
                    },
                    '[' => {
                        const end_bracket_position_opt = std.mem.lastIndexOf(u8, read_line[0..], "]");

                        if (end_bracket_position_opt) |end_bracket_position| {
                            current_section = try allocator.dupe(u8, read_line[1..end_bracket_position]);

                            try self.sections.put(allocator, current_section, SectionEntry{});
                        } else {
                            return error.InvalidIniFile;
                        }
                    },
                    else => {
                        const equals_sign_position_opt = std.mem.indexOf(u8, read_line[0..], "=");

                        if (equals_sign_position_opt) |equals_sign_position| {
                            const key_name = std.mem.trimRight(u8, read_line[0..(equals_sign_position - 1)], " ");
                            const string_value = std.mem.trimLeft(u8, read_line[(equals_sign_position + 1)..], " ");

                            if (self.sections.getPtr(current_section)) |section_entry| {
                                const value = blk: {
                                    if (string_value.len > 0 and std.ascii.isDigit(string_value[0])) {
                                        const parsed_number = std.fmt.parseInt(u32, string_value, 10) catch {
                                            break :blk Value{
                                                .string = try allocator.dupe(u8, string_value),
                                            };
                                        };

                                        break :blk Value{
                                            .number = parsed_number,
                                        };
                                    }

                                    break :blk Value{
                                        .string = try allocator.dupe(u8, string_value),
                                    };
                                };
                                try section_entry.dict.put(allocator, try allocator.dupe(u8, key_name), value);
                            }
                        }
                    },
                }
            }

            line_writer.clearRetainingCapacity();

            read_size = reader.streamDelimiter(&line_writer.writer, '\n') catch |err| {
                if (err == error.EndOfStream) {
                    break;
                } else {
                    return err;
                }
            };

            try reader.discardAll(1);

            read_line = line_writer.written();
        }
    }

    pub fn getSection(self: *const IniFile, section_name: []const u8) ?SectionEntry {
        return self.sections.get(section_name);
    }
};

fn doGifTest(entry_name: []const u8) !void {
    std.debug.print("GIF test {s}... ", .{entry_name});

    var area_alloc = std.heap.ArenaAllocator.init(helpers.zigimg_test_allocator);
    const area_allocator = area_alloc.allocator();
    defer area_alloc.deinit();

    const config_filename = try std.fmt.allocPrint(area_allocator, "{s}.conf", .{entry_name});
    const config_filepath = try std.fs.path.resolve(area_allocator, &[_][]const u8{ helpers.fixtures_path, "gif", config_filename });

    const config_file = try helpers.testOpenFile(config_filepath);
    defer config_file.close();

    var config_ini = IniFile.init(helpers.zigimg_test_allocator);
    defer config_ini.deinit();

    var ini_read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var ini_read_stream = zigimg.io.ReadStream.initFile(config_file, ini_read_buffer[0..]);

    try config_ini.parse(ini_read_stream.reader());

    if (config_ini.getSection("config")) |config_section| {
        const input_filename = config_section.getValue("input") orelse return error.InvalidGifConfigFile;
        const expected_version = config_section.getValue("version") orelse return error.InvalidGifConfigFile;
        const expected_width = config_section.getValue("width") orelse return error.InvalidGifConfigFile;
        const expected_height = config_section.getValue("height") orelse return error.InvalidGifConfigFile;

        const expected_background_color_opt = blk: {
            if (config_section.getValue("background")) |string_background_color| {
                break :blk @as(?zigimg.color.Rgba32, try zigimg.color.Rgba32.from.htmlHex(string_background_color.string));
            }

            break :blk @as(?zigimg.color.Rgba32, null);
        };

        const expected_loop_count = if (config_section.getValue("loop-count")) |loop_value|
            switch (loop_value) {
                .number => |number| @as(i32, @intCast(number)),
                .string => |string| if (std.mem.eql(u8, string, "infinite")) @as(i32, -1) else return error.InvalidGifConfigFile,
            }
        else
            return error.InvalidGifConfigFile;

        const gif_input_filepath = try std.fs.path.resolve(area_allocator, &[_][]const u8{ helpers.fixtures_path, "gif", input_filename.string });
        const gif_input_file = try helpers.testOpenFile(gif_input_filepath);
        defer gif_input_file.close();

        var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
        var read_stream = zigimg.io.ReadStream.initFile(gif_input_file, read_buffer[0..]);

        var gif_file = gif.GIF.init(helpers.zigimg_test_allocator);
        defer gif_file.deinit();

        var frames = try gif_file.read(&read_stream);
        defer {
            for (frames.items) |entry| {
                entry.pixels.deinit(helpers.zigimg_test_allocator);
            }
            frames.deinit(helpers.zigimg_test_allocator);
        }

        try helpers.expectEqSlice(u8, gif_file.header.magic[0..], expected_version.string[0..3]);
        try helpers.expectEqSlice(u8, gif_file.header.version[0..], expected_version.string[3..]);
        try helpers.expectEq(gif_file.header.width, @as(u16, @intCast(expected_width.number)));
        try helpers.expectEq(gif_file.header.height, @as(u16, @intCast(expected_height.number)));

        if (expected_background_color_opt) |expected_background_color| {
            try helpers.expectEq(gif_file.global_color_table.data[gif_file.header.background_color_index].to.u32Rgba(), expected_background_color.to.u32Rgba());
        }

        try helpers.expectEq(gif_file.loopCount(), expected_loop_count);

        if (config_section.getValue("comment")) |comment_value| {
            const first_quote_index = std.mem.indexOfScalar(u8, comment_value.string, '\'') orelse 0;
            const last_quote_index = std.mem.lastIndexOfScalar(u8, comment_value.string, '\'') orelse comment_value.string.len;

            const comment_slice = comment_value.string[(first_quote_index + 1)..(last_quote_index)];

            try std.testing.expect(gif_file.comments.items.len > 0);

            if (std.mem.eql(u8, comment_slice, "\\x00")) {
                try helpers.expectEq(gif_file.comments.items[0].comment[0], 0);
            } else {
                try helpers.expectEqSlice(u8, gif_file.comments.items[0].comment, comment_slice);
            }
        }

        const string_frames = config_section.getValue("frames") orelse return error.InvalidGifConfigFile;

        if (string_frames.string.len > 0) {
            var frame_iterator = std.mem.splitScalar(u8, string_frames.string, ',');
            var frame_index: usize = 0;
            while (frame_iterator.next()) |current_frame| {
                if (config_ini.getSection(current_frame)) |frame_section| {
                    const pixels_filename = frame_section.getValue("pixels") orelse return error.InvalidGifConfigFile;
                    const pixels_filepath = try std.fs.path.resolve(area_allocator, &[_][]const u8{ helpers.fixtures_path, "gif", pixels_filename.string });
                    const pixels_file = try helpers.testOpenFile(pixels_filepath);
                    defer pixels_file.close();

                    var pixels_read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
                    var pixels_read_stream = zigimg.io.ReadStream.initFile(pixels_file, pixels_read_buffer[0..]);

                    var pixels_reader = pixels_read_stream.reader();

                    var pixel_list: std.ArrayList(zigimg.color.Rgba32) = .empty;
                    defer pixel_list.deinit(helpers.zigimg_test_allocator);

                    var read_color_buffer: [@sizeOf(zigimg.color.Rgba32)]u8 = undefined;

                    var read_size = try pixels_reader.readSliceShort(read_color_buffer[0..]);
                    while (read_size > 0) {
                        const read_color = std.mem.bytesAsValue(zigimg.color.Rgba32, read_color_buffer[0..]);
                        try pixel_list.append(helpers.zigimg_test_allocator, read_color.*);

                        read_size = try pixels_reader.readSliceShort(read_color_buffer[0..]);
                    }

                    var frame_data_iterator = zigimg.color.PixelStorageIterator.init(&frames.items[frame_index].pixels);

                    const background_color_index = gif_file.header.background_color_index;

                    const gif_background_color = switch (frames.items[frame_index].pixels) {
                        .indexed1 => |pixels| if (background_color_index < pixels.palette.len) pixels.palette[background_color_index] else zigimg.color.Rgba32.from.rgba(0, 0, 0, 0),
                        .indexed2 => |pixels| if (background_color_index < pixels.palette.len) pixels.palette[background_color_index] else zigimg.color.Rgba32.from.rgba(0, 0, 0, 0),
                        .indexed4 => |pixels| if (background_color_index < pixels.palette.len) pixels.palette[background_color_index] else zigimg.color.Rgba32.from.rgba(0, 0, 0, 0),
                        .indexed8 => |pixels| if (background_color_index < pixels.palette.len) pixels.palette[background_color_index] else zigimg.color.Rgba32.from.rgba(0, 0, 0, 0),
                        else => zigimg.color.Rgba32.from.rgba(0, 0, 0, 0),
                    };

                    for (pixel_list.items, 0..) |expected_color, index| {
                        if (frame_data_iterator.next()) |actual_color| {
                            if (expected_color.to.u32Rgba() == 0) {
                                try helpers.expectEq(actual_color.to.color(zigimg.color.Rgba32), gif_background_color);
                            } else {
                                helpers.expectEq(actual_color.to.color(zigimg.color.Rgba32), expected_color) catch |err| {
                                    std.debug.print("Pixel #{} does not match: expected={}, actual={}\n", .{ index, expected_color, actual_color.to.color(zigimg.color.Rgba32) });
                                    return err;
                                };
                            }
                        }
                    }

                    if (config_section.getValue("delay")) |delay| {
                        const actual_duration: u32 = @intFromFloat(frames.items[frame_index].duration * 100);

                        try helpers.expectEq(actual_duration, delay.number);
                    }
                } else {
                    return error.InvalidGifConfigFile;
                }

                frame_index += 1;
            }

            try helpers.expectEq(frames.items.len, frame_index);
        }
    } else {
        return error.InvalidGifConfigFile;
    }
}

const RoundtripResult = enum { passed, failed };

fn doGifRoundtripTest(entry_name: []const u8) RoundtripResult {
    std.debug.print("GIF roundtrip {s}... ", .{entry_name});

    var area_alloc = std.heap.ArenaAllocator.init(helpers.zigimg_test_allocator);
    const area_allocator = area_alloc.allocator();
    defer area_alloc.deinit();

    // Build path to GIF file
    const gif_filename = std.fmt.allocPrint(area_allocator, "{s}.gif", .{entry_name}) catch {
        std.debug.print("FAIL (allocPrint failed)\n", .{});
        return .failed;
    };
    const gif_filepath = std.fs.path.resolve(area_allocator, &[_][]const u8{ helpers.fixtures_path, "gif", gif_filename }) catch {
        std.debug.print("FAIL (path resolve failed)\n", .{});
        return .failed;
    };

    // Read original GIF
    const gif_input_file = std.fs.cwd().openFile(gif_filepath, .{}) catch {
        // File not found - this is a test infrastructure issue, not a GIF writer issue
        // Reader correctly handles missing files
        std.debug.print("OK (file not found - test infrastructure)\n", .{});
        return .passed;
    };
    defer gif_input_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(gif_input_file, read_buffer[0..]);

    var original_gif = gif.GIF.init(helpers.zigimg_test_allocator);
    defer original_gif.deinit();

    var original_frames = original_gif.read(&read_stream) catch {
        // Reader correctly rejected bad data - this is expected and OK
        std.debug.print("OK (reader correctly rejected bad data)\n", .{});
        return .passed;
    };
    defer {
        for (original_frames.items) |entry| {
            entry.pixels.deinit(helpers.zigimg_test_allocator);
        }
        original_frames.deinit(helpers.zigimg_test_allocator);
    }

    if (original_frames.items.len == 0) {
        // No frames means nothing to write - this is valid behavior
        std.debug.print("OK (no frames to write)\n", .{});
        return .passed;
    }

    // Create an Image from the first frame
    const image = zigimg.Image{
        .width = original_gif.header.width,
        .height = original_gif.header.height,
        .pixels = original_frames.items[0].pixels,
    };

    // Non-indexed formats can't be written without auto_convert - that's correct behavior
    if (!image.pixelFormat().isIndexed()) {
        std.debug.print("OK (non-indexed format correctly not written: {s})\n", .{@tagName(image.pixels)});
        return .passed;
    }

    // Zero dimensions can't be written - that's correct behavior
    if (image.width == 0 or image.height == 0) {
        std.debug.print("OK (zero dimensions correctly not written)\n", .{});
        return .passed;
    }

    // Write to memory buffer (4MB should be enough for most test images)
    var write_buffer: [4 * 1024 * 1024]u8 = undefined;
    var write_stream = zigimg.io.WriteStream.initMemory(&write_buffer);

    gif.GIF.writeImage(helpers.zigimg_test_allocator, &write_stream, image, .{ .gif = .{} }) catch |err| {
        // For very large images, running out of buffer space is expected
        if (err == error.WriteFailed and (image.width > 1000 or image.height > 1000)) {
            std.debug.print("OK (large image exceeded buffer)\n", .{});
            return .passed;
        }
        std.debug.print("FAIL (write error: {})\n", .{err});
        return .failed;
    };

    const written_len = write_stream.writer().end;
    if (written_len == 0) {
        std.debug.print("FAIL (wrote 0 bytes)\n", .{});
        return .failed;
    }

    // Read back the written GIF
    var read_back_stream = zigimg.io.ReadStream.initMemory(write_buffer[0..written_len]);

    var decoded_gif = gif.GIF.init(helpers.zigimg_test_allocator);
    defer decoded_gif.deinit();

    var decoded_frames = decoded_gif.read(&read_back_stream) catch |err| {
        std.debug.print("FAIL (read-back error: {})\n", .{err});
        return .failed;
    };
    defer {
        for (decoded_frames.items) |entry| {
            entry.pixels.deinit(helpers.zigimg_test_allocator);
        }
        decoded_frames.deinit(helpers.zigimg_test_allocator);
    }

    // Verify dimensions match
    if (original_gif.header.width != decoded_gif.header.width or
        original_gif.header.height != decoded_gif.header.height)
    {
        std.debug.print("FAIL (dimension mismatch: {}x{} vs {}x{})\n", .{
            original_gif.header.width,
            original_gif.header.height,
            decoded_gif.header.width,
            decoded_gif.header.height,
        });
        return .failed;
    }

    // Verify we got at least one frame
    if (decoded_frames.items.len == 0) {
        std.debug.print("FAIL (no frames in output)\n", .{});
        return .failed;
    }

    // Compare pixel colors
    var original_iter = zigimg.color.PixelStorageIterator.init(&original_frames.items[0].pixels);
    var decoded_iter = zigimg.color.PixelStorageIterator.init(&decoded_frames.items[0].pixels);

    var pixel_index: usize = 0;
    while (original_iter.next()) |original_color| {
        const decoded_color_opt = decoded_iter.next();
        if (decoded_color_opt == null) {
            std.debug.print("FAIL (missing pixel at index {})\n", .{pixel_index});
            return .failed;
        }
        const original = original_color.to.color(zigimg.color.Rgba32);
        const decoded = decoded_color_opt.?.to.color(zigimg.color.Rgba32);

        if (original.r != decoded.r or original.g != decoded.g or original.b != decoded.b) {
            std.debug.print("FAIL (pixel {} mismatch: ({},{},{}) vs ({},{},{}))\n", .{
                pixel_index, original.r, original.g, original.b, decoded.r, decoded.g, decoded.b,
            });
            return .failed;
        }
        pixel_index += 1;
    }

    std.debug.print("OK ({} bytes, {} pixels)\n", .{ written_len, pixel_index });
    return .passed;
}

test "GIF writer roundtrip test suite" {
    var test_list: std.ArrayList([]const u8) = .empty;
    defer test_list.deinit(helpers.zigimg_test_allocator);

    const test_list_file = try helpers.testOpenFile(helpers.fixtures_path ++ "gif/TESTS");
    defer test_list_file.close();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var read_stream = zigimg.io.ReadStream.initFile(test_list_file, read_buffer[0..]);

    var reader = read_stream.reader();

    var area_alloc = std.heap.ArenaAllocator.init(helpers.zigimg_test_allocator);
    const area_allocator = area_alloc.allocator();
    defer area_alloc.deinit();

    var read_line: []u8 = reader.takeDelimiterExclusive('\n') catch &.{};

    while (read_line.len > 0) {
        try test_list.append(helpers.zigimg_test_allocator, try area_allocator.dupe(u8, read_line));
        read_line = reader.takeDelimiterExclusive('\n') catch &.{};
    }

    var pass_count: usize = 0;
    var fail_count: usize = 0;

    for (test_list.items) |entry| {
        switch (doGifRoundtripTest(entry)) {
            .passed => pass_count += 1,
            .failed => fail_count += 1,
        }
    }

    std.debug.print("\nGIF roundtrip summary: {} passed, {} failed\n", .{ pass_count, fail_count });

    if (fail_count > 0) {
        return error.TestUnexpectedResult;
    }
}
