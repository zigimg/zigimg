//! general utilizies and constants
const std = @import("std");

// See figure A.6 in T.81.
// zig fmt: off
pub const ZigzagOffsets: [64]usize  = .{
    0,   1,  8, 16,  9,  2,  3, 10,
    17, 24, 32, 25, 18, 11,  4,  5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13,  6,  7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63
};
// zig fmt: on

/// The precalculated IDCT multipliers. This is possible because the only part of
/// the IDCT calculation that changes between runs is the coefficients.
/// see A.3.3 of t.81 1992
pub const IDCTMultipliers = blk: {
    var multipliers: [8][8][8][8]f32 = undefined;
    @setEvalBranchQuota(4700);

    var y: usize = 0;
    while (y < 8) : (y += 1) {
        var x: usize = 0;
        while (x < 8) : (x += 1) {
            var u: usize = 0;
            while (u < 8) : (u += 1) {
                var v: usize = 0;
                while (v < 8) : (v += 1) {
                    const C_u: f32 = if (u == 0) 1.0 / @sqrt(2.0) else 1.0;
                    const C_v: f32 = if (v == 0) 1.0 / @sqrt(2.0) else 1.0;

                    const x_cosine = @cos(((2 * @as(f32, @floatFromInt(x)) + 1) * @as(f32, @floatFromInt(u)) * std.math.pi) / 16.0);
                    const y_cosine = @cos(((2 * @as(f32, @floatFromInt(y)) + 1) * @as(f32, @floatFromInt(v)) * std.math.pi) / 16.0);
                    const uv_value = C_u * C_v * x_cosine * y_cosine;
                    multipliers[y][x][u][v] = uv_value;
                }
            }
        }
    }

    break :blk multipliers;
};

/// Marker codes, see t-81 section B.1.1.3
pub const Markers = enum(u16) {
    // Start of Frame markers, non-differential, Huffman coding
    sof0 = 0xFFC0, // Baseline DCT
    sof1 = 0xFFC1, // Extended sequential DCT
    sof2 = 0xFFC2, // Progressive DCT
    sof3 = 0xFFC3, // Lossless sequential

    // Start of Frame markers, differential, Huffman coding
    sof5 = 0xFFC5, // Differential sequential DCT
    sof6 = 0xFFC6, // Differential progressive DCT
    sof7 = 0xFFC7, // Differential lossless sequential

    // Start of Frame markers, non-differential, arithmetic coding
    sof9 = 0xFFC9, // Extended sequential DCT
    sof10 = 0xFFCA, // Progressive DCT
    sof11 = 0xFFCB, // Lossless sequential

    // Start of Frame markers, differential, arithmetic coding
    sof13 = 0xFFCD, // Differential sequential DCT
    sof14 = 0xFFCE, // Differential progressive DCT
    sof15 = 0xFFCF, // Differential lossless sequential

    define_huffman_tables = 0xFFC4,
    define_arithmetic_coding = 0xFFCC,

    // 0xFFD0-0xFFD7: Restart markers
    restart0 = 0xFFD0,
    restart1 = 0xFFD1,
    restart2 = 0xFFD2,
    restart3 = 0xFFD3,
    restart4 = 0xFFD4,
    restart5 = 0xFFD5,
    restart6 = 0xFFD6,
    restart7 = 0xFFD7,

    start_of_image = 0xFFD8,
    end_of_image = 0xFFD9,
    start_of_scan = 0xFFDA,
    define_quantization_tables = 0xFFDB,
    define_number_of_lines = 0xFFDC,
    define_restart_interval = 0xFFDD,
    define_hierarchical_progression = 0xFFDE,
    expand_reference_components = 0xFFDF,

    // 0xFFE0-0xFFEF application segments markers add 0-15 as needed.
    app0 = 0xFFE0,
    app1 = 0xFFE1,
    app2 = 0xFFE2,
    app3 = 0xFFE3,
    app4 = 0xFFE4,
    app5 = 0xFFE5,
    app6 = 0xFFE6,
    app7 = 0xFFE7,
    app8 = 0xFFE8,
    app9 = 0xFFE9,
    app10 = 0xFFEA,
    app11 = 0xFFEB,
    app12 = 0xFFEC,
    app13 = 0xFFED,
    app14 = 0xFFEE,
    app15 = 0xFFEF,

    // 0xFFF0-0xFFFD jpeg extension markers add 0-13 as needed.
    jpeg_extension0 = 0xFFF0,
    comment = 0xFFFE,

    // reserved markers from 0xFF01-0xFFBF, add as needed
};

pub const MAX_COMPONENTS = 3;
pub const MAX_BLOCKS = 8;
pub const MCU = [64]i32;
