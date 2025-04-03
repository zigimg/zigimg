pub const bmp = @import("formats/bmp.zig");
pub const farbfeld = @import("formats/farbfeld.zig");
pub const gif = @import("formats/gif.zig");
pub const ico = @import("formats/ico.zig");
pub const iff = @import("formats/iff.zig");
pub const jpeg = @import("formats/jpeg.zig");
pub const pam = @import("formats/pam.zig");
pub const netpbm = @import("formats/netpbm.zig");
pub const pcx = @import("formats/pcx.zig");
pub const png = @import("formats/png.zig");
pub const qoi = @import("formats/qoi.zig");
pub const ras = @import("formats/ras.zig");
pub const tga = @import("formats/tga.zig");

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
