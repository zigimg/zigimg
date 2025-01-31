const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const assert = std.debug.assert;
const ilbm = @import("../../src/formats/ilbm.zig");
const color = @import("../../src/color.zig");
const ImageReadError = Image.ReadError;
const std = @import("std");
const testing = std.testing;
const Image = @import("../../src/Image.zig");
const helpers = @import("../helpers.zig");

test "Read simple DeluxePaint DOS LBM bitmap" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "ilbm/celtic.lbm");
    defer file.close();

    var the_bitmap = ilbm.ILBM{};

    var stream_source = std.io.StreamSource{ .file = file };

    const pixels = try the_bitmap.load(&stream_source, helpers.zigimg_test_allocator);
    defer pixels.deinit(helpers.zigimg_test_allocator);
}
