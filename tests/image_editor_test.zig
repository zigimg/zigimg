const std = @import("std");

const color = @import("../src/color.zig");
const Image = @import("../src/Image.zig");
const ImageEditor = @import("../src/ImageEditor.zig");
const helpers = @import("helpers.zig");

test "Flip image vertically" {
    var unflipped = try Image.create(std.testing.allocator, 8, 8, .rgb24);
    defer unflipped.deinit();
    var flipped = try Image.create(std.testing.allocator, unflipped.width, unflipped.height, .rgb24);
    defer flipped.deinit();

    for (0..unflipped.height) |y| {
        for (0..unflipped.width) |x| {
            const level = 255 / unflipped.height;
            const clr = color.Rgb24{ .r = @intCast(y * level), .g = 0, .b = 0 };
            unflipped.pixels.rgb24[unflipped.width * y + x] = clr;
            flipped.pixels.rgb24[flipped.width * (flipped.height - 1 - y) + x] = clr;
        }
    }

    try unflipped.flipVertically();
    try std.testing.expectEqualSlices(color.Rgb24, unflipped.pixels.rgb24, flipped.pixels.rgb24);
}

test "normalise_simple" {
    const box = (ImageEditor.Box{
        .x = 0,
        .y = 0,
        .width = 10,
        .height = 10,
    }).clamp(10, 10);
    try std.testing.expectEqual(0, box.x);
    try std.testing.expectEqual(0, box.y);
    try std.testing.expectEqual(10, box.width);
    try std.testing.expectEqual(10, box.height);
}

test "normalise_overflow" {
    const box = (ImageEditor.Box{
        .x = 0,
        .y = 0,
        .width = 16,
        .height = 14,
    }).clamp(10, 10);
    try std.testing.expectEqual(0, box.x);
    try std.testing.expectEqual(0, box.y);
    try std.testing.expectEqual(10, box.width);
    try std.testing.expectEqual(10, box.height);
}

test "normalise_overflow2" {
    const box = (ImageEditor.Box{
        .x = 4,
        .y = 6,
        .width = 10,
        .height = 10,
    }).clamp(10, 10);
    try std.testing.expectEqual(4, box.x);
    try std.testing.expectEqual(6, box.y);
    try std.testing.expectEqual(6, box.width);
    try std.testing.expectEqual(4, box.height);
}

test "ImageEditor.crop: crop grayscale1 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale1);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.grayscale1) |*pixel| {
        pixel.value = 0;
    }

    // Set the region that will be cropped to white
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale1[stride + x].value = std.math.maxInt(u1);
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale1);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale1) |pixel| {
        try helpers.expectEq(pixel.value, 1);
    }
}

test "ImageEditor.crop: crop grayscale2 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale2);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.grayscale2) |*pixel| {
        pixel.value = 0;
    }

    // Set the region that will be cropped to white
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale2[stride + x].value = std.math.maxInt(u2);
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale2);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale2) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u2));
    }
}

test "ImageEditor.crop: crop grayscale4 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale4);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.grayscale4) |*pixel| {
        pixel.value = 0;
    }

    // Set the region that will be cropped to white
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale4[stride + x].value = std.math.maxInt(u4);
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale4);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale4) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u4));
    }
}

test "ImageEditor.crop: crop grayscale8 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale8);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.grayscale8) |*pixel| {
        pixel.value = 0;
    }

    // Set the region that will be cropped to white
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale8[stride + x].value = std.math.maxInt(u8);
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale8);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale8) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u8));
    }
}

test "ImageEditor.crop: crop grayscale8Alpha images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale8Alpha);
    defer big_image.deinit();

    // Set all pixels to transparent black
    for (big_image.pixels.grayscale8Alpha) |*pixel| {
        pixel.value = 0;
        pixel.alpha = 0;
    }

    // Set the region that will be cropped to white with 123 alpha
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale8Alpha[stride + x].value = std.math.maxInt(u8);
            big_image.pixels.grayscale8Alpha[stride + x].alpha = 123;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale8Alpha);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale8Alpha) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u8));
        try helpers.expectEq(pixel.alpha, 123);
    }
}

test "ImageEditor.crop: crop grayscale16 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale16);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.grayscale16) |*pixel| {
        pixel.value = 0;
    }

    // Set the region that will be cropped to white
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale16[stride + x].value = std.math.maxInt(u16);
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale16);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale16) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u16));
    }
}

test "ImageEditor.crop: crop grayscale16Alpha images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .grayscale16Alpha);
    defer big_image.deinit();

    // Set all pixels to transparent black
    for (big_image.pixels.grayscale16Alpha) |*pixel| {
        pixel.value = 0;
        pixel.alpha = 0;
    }

    // Set the region that will be cropped to white with 12345 alpha
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.grayscale16Alpha[stride + x].value = std.math.maxInt(u16);
            big_image.pixels.grayscale16Alpha[stride + x].alpha = 12345;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .grayscale16Alpha);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.grayscale16Alpha) |pixel| {
        try helpers.expectEq(pixel.value, std.math.maxInt(u16));
        try helpers.expectEq(pixel.alpha, 12345);
    }
}
