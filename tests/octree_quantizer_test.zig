const ArrayList = @import("std").ArrayList;
const HeapAllocator = @import("std").heap.HeapAllocator;
const OctTreeQuantizer = @import("zigimg").octree_quantizer.OctTreeQuantizer;
const assert = @import("std").debug.assert;
const bmp = @import("zigimg").bmp;
const color = @import("zigimg").color;
const testing = @import("std").testing;
usingnamespace @import("helpers.zig");

var heapAlloc = HeapAllocator.init();
var heap_allocator = &heapAlloc.allocator;

test "Build the oct tree with 3 colors" {
    var quantizer = OctTreeQuantizer.init(heap_allocator);
    defer quantizer.deinit();
    const red = color.Color.initRGB(0xFF, 0, 0);
    const green = color.Color.initRGB(0, 0xFF, 0);
    const blue = color.Color.initRGB(0, 0, 0xFF);
    try quantizer.addColor(red);
    try quantizer.addColor(green);
    try quantizer.addColor(blue);
    var paletteStorage: [256]color.Color = undefined;
    var palette = try quantizer.makePalette(256, paletteStorage[0..]);
    expectEq(palette.len, 3);

    expectEq(try quantizer.getPaletteIndex(red), 2);
    expectEq(try quantizer.getPaletteIndex(green), 1);
    expectEq(try quantizer.getPaletteIndex(blue), 0);
}

test "Build a oct tree with 32-bit RGBA bitmap" {
    const MemoryRGBABitmap = @embedFile("fixtures/bmp/windows_rgba_v5.bmp");
    var theBitmap = try bmp.Bitmap.fromMemory(heap_allocator, MemoryRGBABitmap);
    defer theBitmap.deinit();

    var quantizer = OctTreeQuantizer.init(heap_allocator);
    defer quantizer.deinit();

    if (theBitmap.pixels) |pixelData| {
        for (pixelData) |pixel| {
            try quantizer.addColor(pixel.premultipliedAlpha());
        }
    }

    var paletteStorage: [256]color.Color = undefined;
    var palette = try quantizer.makePalette(255, paletteStorage[0..]);
    expectEq(palette.len, 255);

    var paletteIndex = try quantizer.getPaletteIndex(color.Color.initRGBA(110, 0, 0, 255));
    expectEq(paletteIndex, 93);

    var secondPaletteIndex = try quantizer.getPaletteIndex(color.Color.initRGBA(0, 0, 119, 255));
    expectEq(secondPaletteIndex, 53);
}
