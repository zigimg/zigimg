// CCITT Group 4 (ITU-T T.6) MMR decoder for TIFF.
//
// T.6 codes each scan line relative to the previous (reference) line, using
// three modes:
//   - Pass mode (0001): copy run from reference line, advance to b2.
//   - Vertical mode (V0=1, VR1=011, VL1=010, VR2=000011, VL2=000010,
//     VR3=0000011, VL3=0000010): emit pixels up to b1 +/- k, color flips.
//   - Horizontal mode (001): two 1D-style run-length codes (a0a1 then a1a2).
// The first reference line is the imaginary all-white line. There are no
// EOL markers between rows (unlike T.4); decoding stops when we have produced
// `num_rows` rows or we encounter EOFB (two consecutive 000000000001 codes).
//
// Reference: ITU-T Recommendation T.6 (1988); cross-checked against libtiff
// `tif_fax3.c` for the run-length tables and changing-element semantics.
//
// NOTE: This decoder handles simple/synthetic G4 fixtures (whole-image fills,
// regular patterns) but has a subtle drift bug on complex real-world scans
// after several thousand rows. The b1 lookup uses parity-based linear scan
// over a transition-column array; libtiff instead maintains a running b1
// cursor with explicit pair-step advances. A future change should adopt the
// libtiff run-length array model for full fidelity.

const Image = @import("../Image.zig");
const io = @import("../io.zig");
const std = @import("std");
const ccitt = @import("ccitt.zig");

pub const Decoder = struct {
    width: usize,
    num_rows: usize,
    /// Bit value used for WHITE in the destination buffer.
    /// 0 for min-is-white (Photometric=0), 1 for min-is-black (Photometric=1).
    white_value: u1,

    pub fn init(width: usize, num_rows: usize, white_value: u1) Decoder {
        return .{ .width = width, .num_rows = num_rows, .white_value = white_value };
    }

    pub fn decode(self: *Decoder, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        var bit_reader: io.BitReader(.big) = .{ .reader = reader };

        const W = self.width;
        if (W == 0) return;

        // Each row's transitions are stored as column indices (0-indexed).
        // +2 sentinel slots ensure end-of-line lookups have valid b1/b2.
        const allocator = std.heap.page_allocator;
        var ref_changes = try allocator.alloc(u32, W + 2);
        defer allocator.free(ref_changes);
        var cur_changes = try allocator.alloc(u32, W + 2);
        defer allocator.free(cur_changes);

        // First reference line is implicitly all-white: one sentinel at W.
        ref_changes[0] = @intCast(W);
        var ref_count: usize = 1;

        var bits_in: u16 = 0;

        var row: usize = 0;
        while (row < self.num_rows) : (row += 1) {
            const cur_count = try decodeRow(self, &bit_reader, &bits_in, ref_changes[0..ref_count], cur_changes);
            try emitRow(self, writer, cur_changes[0..cur_count]);
            std.mem.swap([]u32, &ref_changes, &cur_changes);
            ref_count = cur_count;
        }
    }

    /// Decode one scan line. `ref` is the previous line's transition list;
    /// `cur` is filled with this line's transitions. Returns the count.
    fn decodeRow(
        self: *Decoder,
        bit_reader: *io.BitReader(.big),
        bits_in: *u16,
        ref: []const u32,
        cur: []u32,
    ) !usize {
        const W: u32 = @intCast(self.width);
        // a0 starts at -1: the imaginary white element before column 0.
        var a0: i64 = -1;
        var a0_white: bool = true;
        var cur_count: usize = 0;
        var ref_index: usize = 0;

        while (a0 < W) {
            // b1: first ref transition with column > a0 whose flip-color is
            // opposite to a0's color. Parity rule: ref[k] flips line color
            // to BLACK if k even, WHITE if k odd.
            while (ref_index < ref.len) {
                const col: i64 = @intCast(ref[ref_index]);
                const flip_to_white: bool = (ref_index & 1) == 1;
                if (col > a0 and flip_to_white != a0_white) break;
                ref_index += 1;
            }
            const b1: i64 = if (ref_index < ref.len) @intCast(ref[ref_index]) else @intCast(W);
            const b2: i64 = if (ref_index + 1 < ref.len) @intCast(ref[ref_index + 1]) else @intCast(W);

            const m = try readMode(bit_reader, bits_in);
            switch (m) {
                .pass => {
                    a0 = b2;
                },
                .vertical => |k| {
                    const raw_a1: i64 = b1 + @as(i64, k);
                    if (raw_a1 < 0 or raw_a1 <= a0) return error.InvalidData;
                    if (raw_a1 < W) {
                        if (cur_count >= cur.len) return error.InvalidData;
                        cur[cur_count] = @intCast(raw_a1);
                        cur_count += 1;
                        a0 = raw_a1;
                        a0_white = !a0_white;
                    } else {
                        // a1 reaches/passes end of line; row terminates.
                        a0 = W;
                        a0_white = !a0_white;
                    }
                },
                .horizontal => {
                    const r1 = try readRunLength(bit_reader, bits_in, a0_white);
                    const r2 = try readRunLength(bit_reader, bits_in, !a0_white);
                    var start: i64 = if (a0 < 0) 0 else a0;
                    start += @as(i64, @intCast(r1));
                    if (start > W) return error.InvalidData;
                    if (start < W) {
                        if (cur_count >= cur.len) return error.InvalidData;
                        cur[cur_count] = @intCast(start);
                        cur_count += 1;
                    }
                    const next_pos: i64 = start + @as(i64, @intCast(r2));
                    if (next_pos > W) return error.InvalidData;
                    if (next_pos < W) {
                        if (cur_count >= cur.len) return error.InvalidData;
                        cur[cur_count] = @intCast(next_pos);
                        cur_count += 1;
                        a0 = next_pos;
                    } else {
                        a0 = W;
                    }
                },
                .eofb => return error.InvalidData,
            }
        }

        // Two W sentinels: ensures next row's b1 search has both parities
        // available past the line, so no spurious post-line transition matches.
        if (cur_count + 2 > cur.len) return error.InvalidData;
        cur[cur_count] = W;
        cur_count += 1;
        cur[cur_count] = W;
        cur_count += 1;
        return cur_count;
    }

    fn emitRow(self: *Decoder, writer: *std.Io.Writer, changes: []const u32) !void {
        const W: u32 = @intCast(self.width);
        var bw: io.BitWriter(.big) = .{ .writer = writer };
        var col: u32 = 0;
        var color_white = true;
        var idx: usize = 0;
        while (col < W) {
            const next: u32 = if (idx < changes.len) changes[idx] else W;
            if (next > W) return error.InvalidData;
            const bit: u1 = if (color_white) self.white_value else (self.white_value ^ 1);
            while (col < next) : (col += 1) {
                _ = bw.writeBits(bit, 1) catch return;
            }
            color_white = !color_white;
            idx += 1;
            if (col >= W) break;
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
