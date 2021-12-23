pub const BMP = @import("bmp.zig").Bitmap;
pub const PBM = @import("netpbm.zig").PBM;
pub const PCX = @import("pcx.zig").PCX;
pub const PGM = @import("netpbm.zig").PGM;
pub const PNG = @import("png.zig").PNG;
pub const PPM = @import("netpbm.zig").PPM;
pub const QOI = @import("qoi.zig").QOI;
pub const TGA = @import("tga.zig").TGA;

pub const ImageEncoderOptions = union(enum) {
    none: void,
    pbm: PBM.EncoderOptions,
    pgm: PGM.EncoderOptions,
    ppm: PPM.EncoderOptions,
    qoi: QOI.EncoderOptions,

    const Self = @This();

    pub const None = Self{ .none = .{} };
};
