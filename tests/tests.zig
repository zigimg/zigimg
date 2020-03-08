test "zigimg test suite" {
    _ = @import("bmp_test.zig");
    _ = @import("color_test.zig");
    _ = @import("image_test.zig");
    _ = @import("netpbm_test.zig");
    _ = @import("octree_quantizer_test.zig");
    _ = @import("pcx_test.zig");
    _ = @import("png_test.zig");
}
