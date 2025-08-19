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

test "ImageEditor.crop: crop rgb24 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgb24);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.rgb24) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgb24[stride + x] = .{ .r = 123, .g = 211, .b = 191 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgb24);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgb24) |pixel| {
        try helpers.expectEq(pixel, color.Rgb24{ .r = 123, .g = 211, .b = 191 });
    }
}

test "ImageEditor.crop: crop rgba32 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgba32);
    defer big_image.deinit();

    // Set all pixels to transparent black
    for (big_image.pixels.rgba32) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgba32[stride + x] = .{ .r = 123, .g = 211, .b = 191, .a = 97 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgba32);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgba32) |pixel| {
        try helpers.expectEq(pixel, color.Rgba32{ .r = 123, .g = 211, .b = 191, .a = 97 });
    }
}

test "ImageEditor.crop: crop rgb332 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgb332);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.rgb332) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgb332[stride + x] = .{ .r = 5, .g = 7, .b = 3 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgb332);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgb332) |pixel| {
        try helpers.expectEq(pixel, color.Rgb332{ .r = 5, .g = 7, .b = 3 });
    }
}

test "ImageEditor.crop: crop rgb565 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgb565);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.rgb565) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgb565[stride + x] = .{ .r = 21, .g = 57, .b = 15 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgb565);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgb565) |pixel| {
        try helpers.expectEq(pixel, color.Rgb565{ .r = 21, .g = 57, .b = 15 });
    }
}

test "ImageEditor.crop: crop rgb555 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgb555);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.rgb555) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgb555[stride + x] = .{ .r = 21, .g = 7, .b = 15 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgb555);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgb555) |pixel| {
        try helpers.expectEq(pixel, color.Rgb555{ .r = 21, .g = 7, .b = 15 });
    }
}

test "ImageEditor.crop: crop bgr555 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .bgr555);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.bgr555) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.bgr555[stride + x] = .{ .r = 21, .g = 7, .b = 15 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .bgr555);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.bgr555) |pixel| {
        try helpers.expectEq(pixel, color.Bgr555{ .r = 21, .g = 7, .b = 15 });
    }
}

test "ImageEditor.crop: crop bgr24 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .bgr24);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.bgr24) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.bgr24[stride + x] = .{ .r = 123, .g = 211, .b = 191 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .bgr24);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.bgr24) |pixel| {
        try helpers.expectEq(pixel, color.Bgr24{ .r = 123, .g = 211, .b = 191 });
    }
}

test "ImageEditor.crop: crop bgra32 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .bgra32);
    defer big_image.deinit();

    // Set all pixels to transparent black
    for (big_image.pixels.bgra32) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.bgra32[stride + x] = .{ .r = 123, .g = 211, .b = 191, .a = 97 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .bgra32);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.bgra32) |pixel| {
        try helpers.expectEq(pixel, color.Bgra32{ .r = 123, .g = 211, .b = 191, .a = 97 });
    }
}

test "ImageEditor.crop: crop rgb48 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgb48);
    defer big_image.deinit();

    // Set all pixels to black
    for (big_image.pixels.rgb48) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgb48[stride + x] = .{ .r = 32767, .g = 12345, .b = 54321 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgb48);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgb48) |pixel| {
        try helpers.expectEq(pixel, color.Rgb48{ .r = 32767, .g = 12345, .b = 54321 });
    }
}

test "ImageEditor.crop: crop rgba64 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .rgba64);
    defer big_image.deinit();

    // Set all pixels to transparant black
    for (big_image.pixels.rgba64) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.rgba64[stride + x] = .{ .r = 32767, .g = 12345, .b = 54321, .a = 45213 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .rgba64);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.rgba64) |pixel| {
        try helpers.expectEq(pixel, color.Rgba64{ .r = 32767, .g = 12345, .b = 54321, .a = 45213 });
    }
}

test "ImageEditor.crop: crop float32 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .float32);
    defer big_image.deinit();

    // Set all pixels to transparent black
    for (big_image.pixels.float32) |*pixel| {
        pixel.* = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.float32[stride + x] = .{ .r = 0.123, .g = 0.456, .b = 0.789, .a = 0.543 };
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .float32);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (cropped.pixels.float32) |pixel| {
        try helpers.expectApproxEqAbs(pixel.r, 0.123, 0.0001);
        try helpers.expectApproxEqAbs(pixel.g, 0.456, 0.0001);
        try helpers.expectApproxEqAbs(pixel.b, 0.789, 0.0001);
        try helpers.expectApproxEqAbs(pixel.a, 0.543, 0.0001);
    }
}

test "ImageEditor.crop: crop indexed1 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .indexed1);
    defer big_image.deinit();

    // Setup the palette
    big_image.pixels.indexed1.palette[0] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    big_image.pixels.indexed1.palette[1] = .{ .r = 255, .g = 255, .b = 255, .a = 255 };

    // Set all pixels to index 0
    for (big_image.pixels.indexed1.indices) |*index| {
        index.* = 0;
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.indexed1.indices[stride + x] = 1;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .indexed1);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (0..big_image.pixels.indexed1.palette.len) |index| {
        try helpers.expectEq(cropped.pixels.indexed1.palette[index], big_image.pixels.indexed1.palette[index]);
    }

    for (cropped.pixels.indexed1.indices) |index| {
        try helpers.expectEq(index, 1);
    }
}

test "ImageEditor.crop: crop indexed2 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .indexed2);
    defer big_image.deinit();

    // Setup the palette
    for (0..big_image.pixels.indexed2.palette.len) |palette_index| {
        const grayscale_value: u8 = @intFromFloat(@as(f32, @floatFromInt(palette_index)) / @as(f32, @floatFromInt(big_image.pixels.indexed2.palette.len)) * 255.0);
        big_image.pixels.indexed2.palette[0] = .{ .r = grayscale_value, .g = grayscale_value, .b = grayscale_value, .a = 255 };
    }

    // Set all pixels to index 0
    for (big_image.pixels.indexed2.indices) |*index| {
        index.* = 0;
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.indexed2.indices[stride + x] = 2;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .indexed2);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (0..big_image.pixels.indexed2.palette.len) |index| {
        try helpers.expectEq(cropped.pixels.indexed2.palette[index], big_image.pixels.indexed2.palette[index]);
    }

    for (cropped.pixels.indexed2.indices) |index| {
        try helpers.expectEq(index, 2);
    }
}

test "ImageEditor.crop: crop indexed4 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .indexed4);
    defer big_image.deinit();

    // Setup the palette
    for (0..big_image.pixels.indexed4.palette.len) |palette_index| {
        const grayscale_value: u8 = @intFromFloat(@as(f32, @floatFromInt(palette_index)) / @as(f32, @floatFromInt(big_image.pixels.indexed4.palette.len)) * 255.0);
        big_image.pixels.indexed4.palette[0] = .{ .r = grayscale_value, .g = grayscale_value, .b = grayscale_value, .a = 255 };
    }

    // Set all pixels to index 0
    for (big_image.pixels.indexed4.indices) |*index| {
        index.* = 0;
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.indexed4.indices[stride + x] = 7;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .indexed4);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (0..big_image.pixels.indexed4.palette.len) |index| {
        try helpers.expectEq(cropped.pixels.indexed4.palette[index], big_image.pixels.indexed4.palette[index]);
    }

    for (cropped.pixels.indexed4.indices) |index| {
        try helpers.expectEq(index, 7);
    }
}

test "ImageEditor.crop: crop indexed8 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .indexed8);
    defer big_image.deinit();

    // Setup the palette
    for (0..big_image.pixels.indexed8.palette.len) |palette_index| {
        const grayscale_value: u8 = @intFromFloat(@as(f32, @floatFromInt(palette_index)) / @as(f32, @floatFromInt(big_image.pixels.indexed8.palette.len)) * 255.0);
        big_image.pixels.indexed8.palette[0] = .{ .r = grayscale_value, .g = grayscale_value, .b = grayscale_value, .a = 255 };
    }

    // Set all pixels to index 0
    for (big_image.pixels.indexed8.indices) |*index| {
        index.* = 0;
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.indexed8.indices[stride + x] = 125;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .indexed8);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (0..big_image.pixels.indexed8.palette.len) |index| {
        try helpers.expectEq(cropped.pixels.indexed8.palette[index], big_image.pixels.indexed8.palette[index]);
    }

    for (cropped.pixels.indexed8.indices) |index| {
        try helpers.expectEq(index, 125);
    }
}

test "ImageEditor.crop: crop indexed16 images" {
    var big_image = try Image.create(std.testing.allocator, 8, 8, .indexed16);
    defer big_image.deinit();

    // Setup the palette
    for (0..big_image.pixels.indexed16.palette.len) |palette_index| {
        const grayscale_value: u8 = @intFromFloat(@as(f32, @floatFromInt(palette_index)) / @as(f32, @floatFromInt(big_image.pixels.indexed16.palette.len)) * 255.0);
        big_image.pixels.indexed16.palette[0] = .{ .r = grayscale_value, .g = grayscale_value, .b = grayscale_value, .a = 255 };
    }

    // Set all pixels to index 0
    for (big_image.pixels.indexed16.indices) |*index| {
        index.* = 0;
    }

    // Set the region that will be cropped
    for (2..(2 + 2)) |y| {
        const stride = y * big_image.width;

        for (2..(2 + 2)) |x| {
            big_image.pixels.indexed16.indices[stride + x] = 32767;
        }
    }

    var cropped = try big_image.crop(helpers.zigimg_test_allocator, .{ .x = 2, .y = 2, .width = 2, .height = 2 });
    defer cropped.deinit();

    try std.testing.expect(cropped.pixels == .indexed16);
    try helpers.expectEq(cropped.width, 2);
    try helpers.expectEq(cropped.height, 2);

    for (0..big_image.pixels.indexed16.palette.len) |index| {
        try helpers.expectEq(cropped.pixels.indexed16.palette[index], big_image.pixels.indexed16.palette[index]);
    }

    for (cropped.pixels.indexed16.indices) |index| {
        try helpers.expectEq(index, 32767);
    }
}
