//! general utilizies and constants
const std = @import("std");

// See figure A.6 in T.81.
const ZigzagOffsets = blk: {
    var offsets: [64]usize = undefined;
    offsets[0] = 0;

    var current_offset: usize = 0;
    var direction: enum { north_east, south_west } = .north_east;
    var i: usize = 1;
    while (i < 64) : (i += 1) {
        switch (direction) {
            .north_east => {
                if (current_offset < 8) {
                    // Hit top edge
                    current_offset += 1;
                    direction = .south_west;
                } else if (current_offset % 8 == 7) {
                    // Hit right edge
                    current_offset += 8;
                    direction = .south_west;
                } else {
                    current_offset -= 7;
                }
            },
            .south_west => {
                if (current_offset >= 56) {
                    // Hit bottom edge
                    current_offset += 1;
                    direction = .north_east;
                } else if (current_offset % 8 == 0) {
                    // Hit left edge
                    current_offset += 8;
                    direction = .north_east;
                } else {
                    current_offset += 7;
                }
            },
        }

        if (current_offset >= 64) {
            @compileError(std.fmt.comptimePrint("ZigzagOffsets: Hit offset {} (>= 64) at index {}!\n", .{ current_offset, i }));
        }

        offsets[i] = current_offset;
    }

    break :blk offsets;
};

// The precalculated IDCT multipliers. This is possible because the only part of
// the IDCT calculation that changes between runs is the coefficients.
const IDCTMultipliers = blk: {
    var multipliers: [8][8][8][8]f32 = undefined;
    @setEvalBranchQuota(18086);

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