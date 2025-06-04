const Image = @import("../src/Image.zig");
const OctTreeQuantizer = @import("../src/OctTreeQuantizer.zig");
const color = @import("../src/color.zig");
const std = @import("std");
const helpers = @import("helpers.zig");

test "Build the oct tree with 3 colors" {
    var quantizer = OctTreeQuantizer.init(helpers.zigimg_test_allocator);
    defer quantizer.deinit();

    const red = color.Rgba32.from.rgb(0xFF, 0, 0);
    const green = color.Rgba32.from.rgb(0, 0xFF, 0);
    const blue = color.Rgba32.from.rgb(0, 0, 0xFF);

    try quantizer.addColor(red);
    try quantizer.addColor(green);
    try quantizer.addColor(blue);

    var palette_storage: [256]color.Rgba32 = undefined;
    const palette = quantizer.makePalette(256, palette_storage[0..]);

    try helpers.expectEq(palette.len, 3);

    try helpers.expectEq(try quantizer.getPaletteIndex(red), 2);
    try helpers.expectEq(try quantizer.getPaletteIndex(green), 1);
    try helpers.expectEq(try quantizer.getPaletteIndex(blue), 0);

    try helpers.expectEq(palette[0].b, 0xFF);
    try helpers.expectEq(palette[1].g, 0xFF);
    try helpers.expectEq(palette[2].r, 0xFF);
}

test "Build a oct tree with 32-bit RGBA bitmap" {
    var memory_rgba_bitmap: [200 * 1024]u8 = undefined;
    const buffer = try helpers.testReadFile(helpers.fixtures_path ++ "bmp/windows_rgba_v5.bmp", memory_rgba_bitmap[0..]);

    var image = try Image.fromMemory(helpers.zigimg_test_allocator, buffer);
    defer image.deinit();

    var quantizer = OctTreeQuantizer.init(helpers.zigimg_test_allocator);
    defer quantizer.deinit();

    var color_it = image.iterator();

    while (color_it.next()) |pixel| {
        try quantizer.addColor(pixel);
    }

    var palette_storage: [256]color.Rgba32 = undefined;
    const palette = quantizer.makePalette(255, palette_storage[0..]);

    try helpers.expectEq(palette.len, 255);

    const palette_index = try quantizer.getPaletteIndex(color.Rgba32.from.rgba(110, 0, 0, 255));
    try helpers.expectEq(palette_index, 87);
    try helpers.expectEq(palette[palette_index].r, 110);
    try helpers.expectEq(palette[palette_index].g, 2);
    try helpers.expectEq(palette[palette_index].b, 2);
    try helpers.expectEq(palette[palette_index].a, 255);

    const second_palette_index = try quantizer.getPaletteIndex(color.Rgba32.from.rgba(0, 0, 119, 255));
    try helpers.expectEq(second_palette_index, 50);
    try helpers.expectEq(palette[second_palette_index].r, 0);
    try helpers.expectEq(palette[second_palette_index].g, 0);
    try helpers.expectEq(palette[second_palette_index].b, 117);
    try helpers.expectEq(palette[second_palette_index].a, 255);
}
