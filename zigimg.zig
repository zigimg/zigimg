pub const color = @import("src/color.zig");
pub const FormatInterface = @import("src/FormatInterface.zig");
pub const formats = @import("src/formats.zig");
pub const Image = @import("src/Image.zig");
pub const math = @import("src/math.zig");
pub const OctTreeQuantizer = @import("src/OctTreeQuantizer.zig");
pub const PixelFormat = @import("src/pixel_format.zig").PixelFormat;
pub const PixelFormatConverter = @import("src/PixelFormatConverter.zig");
pub const Colors = @import("src/predefined_colors.zig").Colors;
pub const io = @import("src/io.zig");

test {
    _ = color;
    _ = FormatInterface;
    _ = formats;
    _ = Image;
    _ = math;
    _ = OctTreeQuantizer;
    _ = PixelFormat;
    _ = PixelFormatConverter;
    _ = Colors;
    _ = io;

    _ = @import("src/compressions/lzw.zig");
    _ = @import("tests/color_test.zig");
    _ = @import("tests/io_test.zig");
    _ = @import("tests/formats/bmp_test.zig");
    _ = @import("tests/formats/gif_test.zig");
    _ = @import("tests/formats/iff_test.zig");
    _ = @import("tests/formats/jpeg_test.zig");
    _ = @import("tests/formats/pam_test.zig");
    _ = @import("tests/formats/netpbm_test.zig");
    _ = @import("tests/formats/pcx_test.zig");
    _ = @import("tests/formats/png_test.zig");
    _ = @import("tests/formats/qoi_test.zig");
    _ = @import("tests/formats/ras_test.zig");
    _ = @import("tests/formats/sgi_test.zig");
    _ = @import("tests/formats/tga_test.zig");
    _ = @import("tests/formats/tiff_test.zig");
    _ = @import("tests/formats/farbfeld_test.zig");
    _ = @import("tests/formats/xbm_test.zig");
    _ = @import("tests/image_editor_test.zig");
    _ = @import("tests/image_test.zig");
    _ = @import("tests/math_test.zig");
    _ = @import("tests/octree_quantizer_test.zig");
    _ = @import("tests/pixel_format_converter_test.zig");
    _ = @import("tests/pixel_format_test.zig");
}
