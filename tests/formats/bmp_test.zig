const ImageReader = image.ImageReader;
const ImageSeekStream = image.ImageSeekStream;
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const bmp = @import("../../src/formats/bmp.zig");
const color = @import("../../src/color.zig");
const errors = @import("../../src/errors.zig");
const std = @import("std");
const testing = std.testing;
const image = @import("../../src/image.zig");
const helpers = @import("../helpers.zig");

const MemoryRGBABitmap = @embedFile("../../../test-suite/fixtures/bmp/windows_rgba_v5.bmp");

fn verifyBitmapRGBAV5(the_bitmap: bmp.Bitmap, pixels_opt: ?color.ColorStorage) !void {
    try helpers.expectEq(the_bitmap.file_header.size, 153738);
    try helpers.expectEq(the_bitmap.file_header.reserved, 0);
    try helpers.expectEq(the_bitmap.file_header.pixel_offset, 138);
    try helpers.expectEq(the_bitmap.width(), 240);
    try helpers.expectEq(the_bitmap.height(), 160);

    try helpers.expectEqSlice(u8, @tagName(the_bitmap.info_header), "V5");

    _ = switch (the_bitmap.info_header) {
        .V5 => |v5Header| {
            try helpers.expectEq(v5Header.header_size, bmp.BitmapInfoHeaderV5.HeaderSize);
            try helpers.expectEq(v5Header.width, 240);
            try helpers.expectEq(v5Header.height, 160);
            try helpers.expectEq(v5Header.color_plane, 1);
            try helpers.expectEq(v5Header.bit_count, 32);
            try helpers.expectEq(v5Header.compression_method, bmp.CompressionMethod.Bitfields);
            try helpers.expectEq(v5Header.image_raw_size, 240 * 160 * 4);
            try helpers.expectEq(v5Header.horizontal_resolution, 2835);
            try helpers.expectEq(v5Header.vertical_resolution, 2835);
            try helpers.expectEq(v5Header.palette_size, 0);
            try helpers.expectEq(v5Header.important_colors, 0);
            try helpers.expectEq(v5Header.red_mask, 0x00ff0000);
            try helpers.expectEq(v5Header.green_mask, 0x0000ff00);
            try helpers.expectEq(v5Header.blue_mask, 0x000000ff);
            try helpers.expectEq(v5Header.alpha_mask, 0xff000000);
            try helpers.expectEq(v5Header.color_space, bmp.BitmapColorSpace.sRgb);
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
            try helpers.expectEq(v5Header.intent, bmp.BitmapIntent.Graphics);
            try helpers.expectEq(v5Header.profile_data, 0);
            try helpers.expectEq(v5Header.profile_size, 0);
            try helpers.expectEq(v5Header.reserved, 0);
        },
        else => unreachable,
    };

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .Bgra32);

        try helpers.expectEq(pixels.len(), 240 * 160);

        const first_pixel = pixels.Bgra32[0];
        try helpers.expectEq(first_pixel.R, 0xFF);
        try helpers.expectEq(first_pixel.G, 0xFF);
        try helpers.expectEq(first_pixel.B, 0xFF);
        try helpers.expectEq(first_pixel.A, 0xFF);

        const second_pixel = pixels.Bgra32[1];
        try helpers.expectEq(second_pixel.R, 0xFF);
        try helpers.expectEq(second_pixel.G, 0x00);
        try helpers.expectEq(second_pixel.B, 0x00);
        try helpers.expectEq(second_pixel.A, 0xFF);

        const third_pixel = pixels.Bgra32[2];
        try helpers.expectEq(third_pixel.R, 0x00);
        try helpers.expectEq(third_pixel.G, 0xFF);
        try helpers.expectEq(third_pixel.B, 0x00);
        try helpers.expectEq(third_pixel.A, 0xFF);

        const fourth_pixel = pixels.Bgra32[3];
        try helpers.expectEq(fourth_pixel.R, 0x00);
        try helpers.expectEq(fourth_pixel.G, 0x00);
        try helpers.expectEq(fourth_pixel.B, 0xFF);
        try helpers.expectEq(fourth_pixel.A, 0xFF);

        const colored_pixel = pixels.Bgra32[(22 * 240) + 16];
        try helpers.expectEq(colored_pixel.R, 195);
        try helpers.expectEq(colored_pixel.G, 195);
        try helpers.expectEq(colored_pixel.B, 255);
        try helpers.expectEq(colored_pixel.A, 255);
    }
}

test "Read simple version 4 24-bit RGB bitmap" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/fixtures/bmp/simple_v4.bmp");
    defer file.close();

    var the_bitmap = bmp.Bitmap{};

    var stream_source = std.io.StreamSource{ .file = file };

    var pixels_opt: ?color.ColorStorage = null;
    try the_bitmap.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try helpers.expectEq(the_bitmap.width(), 8);
    try helpers.expectEq(the_bitmap.height(), 1);

    try testing.expect(pixels_opt != null);

    if (pixels_opt) |pixels| {
        try testing.expect(pixels == .Bgr24);

        const red = pixels.Bgr24[0];
        try helpers.expectEq(red.R, 0xFF);
        try helpers.expectEq(red.G, 0x00);
        try helpers.expectEq(red.B, 0x00);

        const green = pixels.Bgr24[1];
        try helpers.expectEq(green.R, 0x00);
        try helpers.expectEq(green.G, 0xFF);
        try helpers.expectEq(green.B, 0x00);

        const blue = pixels.Bgr24[2];
        try helpers.expectEq(blue.R, 0x00);
        try helpers.expectEq(blue.G, 0x00);
        try helpers.expectEq(blue.B, 0xFF);

        const cyan = pixels.Bgr24[3];
        try helpers.expectEq(cyan.R, 0x00);
        try helpers.expectEq(cyan.G, 0xFF);
        try helpers.expectEq(cyan.B, 0xFF);

        const magenta = pixels.Bgr24[4];
        try helpers.expectEq(magenta.R, 0xFF);
        try helpers.expectEq(magenta.G, 0x00);
        try helpers.expectEq(magenta.B, 0xFF);

        const yellow = pixels.Bgr24[5];
        try helpers.expectEq(yellow.R, 0xFF);
        try helpers.expectEq(yellow.G, 0xFF);
        try helpers.expectEq(yellow.B, 0x00);

        const black = pixels.Bgr24[6];
        try helpers.expectEq(black.R, 0x00);
        try helpers.expectEq(black.G, 0x00);
        try helpers.expectEq(black.B, 0x00);

        const white = pixels.Bgr24[7];
        try helpers.expectEq(white.R, 0xFF);
        try helpers.expectEq(white.G, 0xFF);
        try helpers.expectEq(white.B, 0xFF);
    }
}

test "Read a valid version 5 RGBA bitmap from file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/fixtures/bmp/windows_rgba_v5.bmp");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var the_bitmap = bmp.Bitmap{};

    var pixels_opt: ?color.ColorStorage = null;
    try the_bitmap.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try verifyBitmapRGBAV5(the_bitmap, pixels_opt);
}

test "Read a valid version 5 RGBA bitmap from memory" {
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(MemoryRGBABitmap) };

    var the_bitmap = bmp.Bitmap{};

    var pixels_opt: ?color.ColorStorage = null;
    try the_bitmap.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels_opt);

    defer {
        if (pixels_opt) |pixels| {
            pixels.deinit(helpers.zigimg_test_allocator);
        }
    }

    try verifyBitmapRGBAV5(the_bitmap, pixels_opt);
}

test "Should error when reading an invalid file" {
    const file = try helpers.testOpenFile(helpers.zigimg_test_allocator, "../test-suite/fixtures/bmp/notbmp.png");
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var the_bitmap = bmp.Bitmap{};

    var pixels: ?color.ColorStorage = null;
    const invalidFile = the_bitmap.read(helpers.zigimg_test_allocator, stream_source.reader(), stream_source.seekableStream(), &pixels);
    try helpers.expectError(invalidFile, errors.ImageError.InvalidMagicHeader);
}
