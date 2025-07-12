const helpers = @import("../helpers.zig");
const Image = @import("../../src/Image.zig");
const ImageError = Image.Error;

test "XBM: invalid file format" {
    try helpers.expectError(helpers.testImageFromFile(helpers.fixtures_path ++ "xbm/bad_missing_dim.xbm"), ImageError.Unsupported);

    try helpers.expectError(helpers.testImageFromFile(helpers.fixtures_path ++ "xbm/bad_missing_pixels.xbm"), Image.ReadError.InvalidData);
}
