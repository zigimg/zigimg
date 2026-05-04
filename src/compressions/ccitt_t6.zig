// CCITT Group 4 (ITU-T T.6) MMR decoder for TIFF.
//
// T.6 codes each scan line relative to the previous (reference) line, using
// three modes:
//   - Pass mode (0001): copy run from reference line, advance a0 to b2.
//   - Vertical mode (V0=1, VR1=011, VL1=010, VR2=000011, VL2=000010,
//     VR3=0000011, VL3=0000010): emit pixels up to b1 +/- k, color flips.
//   - Horizontal mode (001): two 1D-style run-length codes (a0a1 then a1a2).
// The first reference line is the imaginary all-white line. There are no
// EOL markers between rows (unlike T.4); decoding stops when we have produced
// `num_rows` rows or we encounter EOFB (two consecutive 000000000001 codes).
//
// Reference: ITU-T Recommendation T.6 (1988); algorithm modeled directly on
// libtiff's `tif_fax3.c` (Fax4Decode + EXPAND2D + CHECK_b1 macros).
//
// The decoder maintains, for each row, an array of alternating white/black
// run lengths starting with white. The previous row's array is the reference;
// b1 is a running cursor advanced in pair-steps (pb += 2; b1 += pb[0]+pb[1])
// each time it falls behind a0. This pair-step model preserves the color-flip
// parity of b1 (always the next reference transition where the prior row
// flips to the OPPOSITE of a0's current color), which is what makes the 2D
// vertical/pass/horizontal mode references decode correctly even on complex
// real-world content.

const Image = @import("../Image.zig");
const io = @import("../io.zig");
const std = @import("std");
const ccitt = @import("ccitt.zig");

pub const Decoder = struct {
    width: usize,
    num_rows: usize,
    /// Retained for API/ABI compatibility -- the decoder always emits raw
    /// photometric-encoded bits (T.6 white-runs as 0, black-runs as 1, per
    /// libtiff convention). Higher-level storage applies the photometric
    /// inversion if needed.
    white_value: u1,

    pub fn init(width: usize, num_rows: usize, white_value: u1) Decoder {
        return .{ .width = width, .num_rows = num_rows, .white_value = white_value };
    }

    pub fn decode(self: *Decoder, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        var bit_reader: io.BitReader(.big) = .{ .reader = reader };

        const W = self.width;
        if (W == 0) return;

        // Two run-length arrays: cur_runs (this row, being written), ref_runs
        // (previous row, being read). Generous sizing: worst case we get an
        // alternating white/black pixel pattern (W transitions); add a few
        // extra slots for the final SETVALUE(0) terminator and pb pair-step
        // overrun guards (we allow pb to read up to two slots beyond pa).
        const allocator = std.heap.page_allocator;
        const nruns: usize = W + 8;
        var cur_runs = try allocator.alloc(u32, nruns);
        defer allocator.free(cur_runs);
        var ref_runs = try allocator.alloc(u32, nruns);
        defer allocator.free(ref_runs);

        // Initial reference row = imaginary all-white: [W, 0].
        ref_runs[0] = @intCast(W);
        ref_runs[1] = 0;
        var ref_count: usize = 2;

        // Zero unused tail of ref so CHECK_b1's pair-step on a sparse prev row
        // sees defined zeros (advancing b1 by 0+0 each step), terminated by
        // the bounds check.
        for (ref_runs[ref_count..]) |*v| v.* = 0;

        var bits_in: u16 = 0;

        var row: usize = 0;
        while (row < self.num_rows) : (row += 1) {
            // Zero cur_runs entirely before decode -- we only fill the prefix,
            // and the next iter (after swap) treats this as ref with safe zero
            // padding.
            for (cur_runs) |*v| v.* = 0;
            const cur_count = try decodeRow(self, &bit_reader, &bits_in, ref_runs, cur_runs);
            try emitRow(self, writer, cur_runs[0..cur_count]);
            std.mem.swap([]u32, &ref_runs, &cur_runs);
            ref_count = cur_count;
        }
    }

    /// Decode one scan line into a run-length array. Mirrors libtiff's
    /// EXPAND2D macro: maintains a0 (column of last transition placed),
    /// pa (write index in `cur`), pb (read index in `ref`), b1 (column of
    /// next reference transition with color OPPOSITE a0's current color),
    /// and RunLength (pending accumulator for horizontal makeup codes).
    fn decodeRow(
        self: *Decoder,
        bit_reader: *io.BitReader(.big),
        bits_in: *u16,
        ref: []const u32,
        cur: []u32,
    ) !usize {
        const lastx: i64 = @intCast(self.width);

        var a0: i64 = 0;
        var pa: usize = 0; // write index in cur
        var pb: usize = 0; // read index in ref
        var run_length: u32 = 0;

        // b1 = absolute position of first reference transition.
        if (ref.len == 0) return error.InvalidData;
        var b1: i64 = @intCast(ref[pb]);
        pb += 1;

        while (a0 < lastx) {
            const m = try readMode(bit_reader, bits_in);
            switch (m) {
                .pass => {
                    try checkB1(&b1, &pb, ref, a0, lastx, pa);
                    if (pb + 1 > ref.len) return error.InvalidData;
                    b1 += @as(i64, @intCast(ref[pb]));
                    pb += 1;
                    run_length += @intCast(b1 - a0);
                    a0 = b1;
                    if (pb >= ref.len) return error.InvalidData;
                    b1 += @as(i64, @intCast(ref[pb]));
                    pb += 1;
                },
                .vertical => |k| {
                    try checkB1(&b1, &pb, ref, a0, lastx, pa);
                    const target: i64 = b1 + @as(i64, k);
                    if (target < a0) return error.InvalidData;
                    if (k < 0 and target > b1) return error.InvalidData; // sanity
                    const run: i64 = target - a0;
                    if (pa >= cur.len) return error.InvalidData;
                    cur[pa] = run_length + @as(u32, @intCast(run));
                    pa += 1;
                    a0 = target;
                    run_length = 0;
                    if (k < 0) {
                        // VL: roll b1 back to the previous reference transition.
                        // libtiff: b1 -= *--pb;
                        if (pb == 0) return error.InvalidData;
                        pb -= 1;
                        b1 -= @as(i64, @intCast(ref[pb]));
                    } else {
                        // V0 / VR: step b1 forward to next reference transition.
                        // libtiff: b1 += *pb++;
                        if (pb >= ref.len) return error.InvalidData;
                        b1 += @as(i64, @intCast(ref[pb]));
                        pb += 1;
                    }
                },
                .horizontal => {
                    // Two run-length codes. First color = current color
                    // (the color a0 is "in" / about to extend). pa even means
                    // next write is a white run; pa odd means black run.
                    const first_white: bool = (pa & 1) == 0;
                    const r1 = try readRunLength(bit_reader, bits_in, first_white);
                    const r2 = try readRunLength(bit_reader, bits_in, !first_white);
                    if (pa + 1 >= cur.len) return error.InvalidData;
                    cur[pa] = run_length + r1;
                    pa += 1;
                    cur[pa] = r2;
                    pa += 1;
                    a0 += @as(i64, @intCast(r1));
                    a0 += @as(i64, @intCast(r2));
                    run_length = 0;
                    try checkB1(&b1, &pb, ref, a0, lastx, pa);
                },
                .eofb => return error.InvalidData,
            }
        }

        if (a0 > lastx) return error.InvalidData;

        // Imaginary terminator: SETVALUE(0) -- writes any pending run_length.
        if (pa >= cur.len) return error.InvalidData;
        cur[pa] = run_length;
        pa += 1;
        // libtiff also pads to even pa via fillruns guard: if pa is odd,
        // append a 0 so the pair convention (white,black,white,black,...) holds.
        if ((pa & 1) != 0) {
            if (pa >= cur.len) return error.InvalidData;
            cur[pa] = 0;
            pa += 1;
        }
        return pa;
    }

    /// CHECK_b1: while b1 has fallen behind a0, advance b1 forward one PAIR
    /// of reference runs (preserving its color-flip parity). Pair-step skip
    /// matches libtiff's tif_fax3.h:CHECK_b1 macro exactly.
    fn checkB1(b1: *i64, pb: *usize, ref: []const u32, a0: i64, lastx: i64, pa: usize) !void {
        if (pa == 0) return;
        while (b1.* <= a0 and b1.* < lastx) {
            if (pb.* + 1 >= ref.len) return error.InvalidData;
            b1.* += @as(i64, @intCast(ref[pb.*]));
            b1.* += @as(i64, @intCast(ref[pb.* + 1]));
            pb.* += 2;
        }
    }

    /// Render one row of run lengths to packed bits. `runs` alternates white
    /// then black starting with white (run[0] = first white run length).
    fn emitRow(self: *Decoder, writer: *std.Io.Writer, runs: []const u32) !void {
        // Per ITU-T T.6 / libtiff convention, "white" runs are runs of 0-bits in
        // the source bitstream and "black" runs are runs of 1-bits, REGARDLESS
        // of TIFF photometric interpretation. The decoder thus emits raw
        // photometric-encoded bits (matching what the file would contain
        // uncompressed); higher-level storage code handles photometric
        // inversion. self.white_value is retained for API compatibility but
        // intentionally unused here.
        _ = self.white_value;
        const W: u32 = @intCast(self.width);
        var bw: io.BitWriter(.big) = .{ .writer = writer };
        var col: u32 = 0;
        var idx: usize = 0;
        var color_white = true;
        while (col < W and idx < runs.len) : (idx += 1) {
            const run_len = runs[idx];
            const bit: u1 = if (color_white) 0 else 1;
            var k: u32 = 0;
            while (k < run_len and col < W) : (k += 1) {
                _ = bw.writeBits(bit, 1) catch return;
                col += 1;
            }
            color_white = !color_white;
        }
        // If runs underfilled the row, pad with the last color.
        while (col < W) : (col += 1) {
            const bit: u1 = if (color_white) 0 else 1;
            _ = bw.writeBits(bit, 1) catch return;
        }
        bw.flushBits() catch {};
    }
};

const Mode = union(enum) {
    pass: void,
    vertical: i8, // -3 .. +3
    horizontal: void,
    eofb: void,
};

/// Decode the next 2D mode prefix per ITU-T T.6 (1988) Table 1.
fn readMode(bit_reader: *io.BitReader(.big), bits_in: *u16) !Mode {
    const b1 = try bit_reader.readBits(u1, 1, bits_in);
    if (b1 == 1) return .{ .vertical = 0 };
    const b2 = try bit_reader.readBits(u1, 1, bits_in);
    if (b2 == 1) {
        const b3 = try bit_reader.readBits(u1, 1, bits_in);
        if (b3 == 1) return .{ .vertical = 1 };
        return .{ .vertical = -1 };
    }
    const b3 = try bit_reader.readBits(u1, 1, bits_in);
    if (b3 == 1) return .{ .horizontal = {} };
    const b4 = try bit_reader.readBits(u1, 1, bits_in);
    if (b4 == 1) return .{ .pass = {} };
    const b5 = try bit_reader.readBits(u1, 1, bits_in);
    if (b5 == 1) {
        const b6 = try bit_reader.readBits(u1, 1, bits_in);
        if (b6 == 1) return .{ .vertical = 2 };
        return .{ .vertical = -2 };
    }
    const b6 = try bit_reader.readBits(u1, 1, bits_in);
    if (b6 == 1) {
        const b7 = try bit_reader.readBits(u1, 1, bits_in);
        if (b7 == 1) return .{ .vertical = 3 };
        return .{ .vertical = -3 };
    }
    // 000000... -- EOFB candidate (24 bits total: two 000000000001 codes).
    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        if ((try bit_reader.readBits(u1, 1, bits_in)) != 0) return error.InvalidData;
    }
    if ((try bit_reader.readBits(u1, 1, bits_in)) != 1) return error.InvalidData;
    i = 0;
    while (i < 11) : (i += 1) {
        if ((try bit_reader.readBits(u1, 1, bits_in)) != 0) return error.InvalidData;
    }
    if ((try bit_reader.readBits(u1, 1, bits_in)) != 1) return error.InvalidData;
    return .{ .eofb = {} };
}

/// Read a possibly-composite T.4 run-length code (makeup codes followed by a
/// terminating code) from the white or black tables.
fn readRunLength(bit_reader: *io.BitReader(.big), bits_in: *u16, white: bool) !u32 {
    var total: u32 = 0;
    while (true) {
        const code_value: u32 = try matchCode(bit_reader, bits_in, white);
        total += code_value & 0x7FFFFFFF;
        if ((code_value & 0x80000000) == 0) return total;
    }
}

/// Match the next variable-length T.4 run-length code. Bit 31 of the result
/// is set when the matched code was a make-up; caller continues matching.
fn matchCode(bit_reader: *io.BitReader(.big), bits_in: *u16, white: bool) !u32 {
    var code: u16 = 0;
    var len: u8 = 0;
    while (len < 14) {
        code = (code << 1) | try bit_reader.readBits(u1, 1, bits_in);
        len += 1;
        if (matchTerminating(code, len, white)) |rl| return @intCast(rl);
        if (matchMakeup(code, len, white)) |rl| return 0x80000000 | @as(u32, rl);
    }
    return error.InvalidData;
}

fn matchTerminating(code: u16, len: u8, white: bool) ?u16 {
    const tbl = if (white) &ccitt.white_terminating_codes else &ccitt.black_terminating_codes;
    for (tbl) |c| {
        if (c.code_length == len and c.code == code) return c.run_length;
    }
    return null;
}

fn matchMakeup(code: u16, len: u8, white: bool) ?u16 {
    const tbl = if (white) &ccitt.white_make_up_codes else &ccitt.black_make_up_codes;
    for (tbl) |c| {
        if (c.code_length == len and c.code == code) return c.run_length;
    }
    for (ccitt.additional_make_up_codes) |c| {
        if (c.code_length == len and c.code == code) return c.run_length;
    }
    return null;
}
