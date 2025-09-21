const std = @import("std");
const io = std.io;
const assert = std.debug.assert;
const testing = std.testing;
const expect = testing.expect;
const print = std.debug.print;

const Token = @import("deflate/Token.zig");
const consts = @import("deflate/consts.zig");
const BlockWriter = @import("deflate/BlockWriter.zig");
const Container = @import("deflate/container.zig").Container;
const SlidingWindow = @import("deflate/SlidingWindow.zig");
const Lookup = @import("deflate/Lookup.zig");

pub const Options = struct {
    level: Level = .default,
};

/// Trades between speed and compression size.
/// Starts with level 4: in [zlib](https://github.com/madler/zlib/blob/abd3d1a28930f89375d4b41408b39f6c1be157b2/deflate.c#L115C1-L117C43)
/// levels 1-3 are using different algorithm to perform faster but with less
/// compression. That is not implemented here.
pub const Level = enum(u4) {
    // zig fmt: off
    fast = 0xb,         level_4 = 4,
                        level_5 = 5,
    default = 0xc,      level_6 = 6,
                        level_7 = 7,
                        level_8 = 8,
    best = 0xd,         level_9 = 9,
    // zig fmt: on
};

/// Algorithm knobs for each level.
const LevelArgs = struct {
    good: u16, // Do less lookups if we already have match of this length.
    nice: u16, // Stop looking for better match if we found match with at least this length.
    lazy: u16, // Don't do lazy match find if got match with at least this length.
    chain: u16, // How many lookups for previous match to perform.

    pub fn get(level: Level) LevelArgs {
        // zig fmt: off
        return switch (level) {
            .fast,    .level_4 => .{ .good =  4, .lazy =   4, .nice =  16, .chain =   16 },
                      .level_5 => .{ .good =  8, .lazy =  16, .nice =  32, .chain =   32 },
            .default, .level_6 => .{ .good =  8, .lazy =  16, .nice = 128, .chain =  128 },
                      .level_7 => .{ .good =  8, .lazy =  32, .nice = 128, .chain =  256 },
                      .level_8 => .{ .good = 32, .lazy = 128, .nice = 258, .chain = 1024 },
            .best,    .level_9 => .{ .good = 32, .lazy = 258, .nice = 258, .chain = 4096 },
        };
        // zig fmt: on
    }
};

/// Compress plain data from reader into compressed stream written to writer.
pub fn compress(comptime container: Container, reader: *std.Io.Writer, writer: *std.Io.Writer, options: Options) !void {
    var c = try compressor(container, writer, options);
    try c.compress(reader);
    try c.finish();
}

/// Create compressor for writer type.
pub fn compressor(comptime container: Container, writer: *std.Io.Writer, options: Options) !Compressor(container) {
    return try Compressor(container).init(writer, options);
}

/// Compressor type.
pub fn Compressor(comptime container: Container) type {
    return Deflate(container);
}

/// Default compression algorithm. Has two steps: tokenization and token
/// encoding.
///
/// Tokenization takes uncompressed input stream and produces list of tokens.
/// Each token can be literal (byte of data) or match (backrefernce to previous
/// data with length and distance). Tokenization accumulators 32K tokens, when
/// full or `flush` is called tokens are passed to the `block_writer`. Level
/// defines how hard (how slow) it tries to find match.
///
/// Block writer will decide which type of deflate block to write (stored, fixed,
/// dynamic) and encode tokens to the output byte stream. Client has to call
/// `finish` to write block with the final bit set.
///
/// Container defines type of header and footer which can be gzip, zlib or raw.
/// They all share same deflate body. Raw has no header or footer just deflate
/// body.
///
/// Compression algorithm explained in rfc-1951 (slightly edited for this case):
///
///   The compressor uses a chained hash table `lookup` to find duplicated
///   strings, using a hash function that operates on 4-byte sequences. At any
///   given point during compression, let XYZW be the next 4 input bytes
///   (lookahead) to be examined (not necessarily all different, of course).
///   First, the compressor examines the hash chain for XYZW. If the chain is
///   empty, the compressor simply writes out X as a literal byte and advances
///   one byte in the input. If the hash chain is not empty, indicating that the
///   sequence XYZW (or, if we are unlucky, some other 4 bytes with the same
///   hash function value) has occurred recently, the compressor compares all
///   strings on the XYZW hash chain with the actual input data sequence
///   starting at the current point, and selects the longest match.
///
///   To improve overall compression, the compressor defers the selection of
///   matches ("lazy matching"): after a match of length N has been found, the
///   compressor searches for a longer match starting at the next input byte. If
///   it finds a longer match, it truncates the previous match to a length of
///   one (thus producing a single literal byte) and then emits the longer
///   match. Otherwise, it emits the original match, and, as described above,
///   advances N bytes before continuing.
///
///
/// Allocates statically ~400K (192K lookup, 128K tokens, 64K window).
///
/// Deflate function accepts BlockWriterType so we can change that in test to test
/// just tokenization part.
///
fn Deflate(comptime container: Container) type {
    return struct {
        lookup: Lookup = .{},
        win: SlidingWindow = .{},
        tokens: Tokens = .{},
        source_writer: *std.Io.Writer,
        block_writer: BlockWriter,
        level: LevelArgs,
        hasher: container.Hasher() = .{},
        writer: std.Io.Writer = .{
            .buffer = &.{},
            .vtable = &std.Io.Writer.VTable{
                .drain = drain,
                .flush = flush,
            },
        },

        // Match and literal at the previous position.
        // Used for lazy match finding in processWindow.
        prev_match: ?Token = null,
        prev_literal: ?u8 = null,

        const Self = @This();

        pub fn init(wrt: *std.Io.Writer, options: Options) !Self {
            const self = Self{
                .source_writer = wrt,
                .block_writer = BlockWriter.init(wrt),
                .level = LevelArgs.get(options.level),
            };
            try container.writeHeader(self.source_writer);
            return self;
        }

        const FlushOption = enum { none, flush, final };

        // Process data in window and create tokens. If token buffer is full
        // flush tokens to the token writer. In the case of `flush` or `final`
        // option it will process all data from the window. In the `none` case
        // it will preserve some data for the next match.
        fn tokenize(self: *Self, flush_opt: FlushOption) !void {
            // flush - process all data from window
            const should_flush = (flush_opt != .none);

            // While there is data in active lookahead buffer.
            while (self.win.activeLookahead(should_flush)) |lh| {
                var step: u16 = 1; // 1 in the case of literal, match length otherwise
                const pos: u16 = self.win.pos();
                const literal = lh[0]; // literal at current position
                const min_len: u16 = if (self.prev_match) |m| m.length() else 0;

                // Try to find match at least min_len long.
                if (self.findMatch(pos, lh, min_len)) |match| {
                    // Found better match than previous.
                    try self.addPrevLiteral();

                    // Is found match length good enough?
                    if (match.length() >= self.level.lazy) {
                        // Don't try to lazy find better match, use this.
                        step = try self.addMatch(match);
                    } else {
                        // Store this match.
                        self.prev_literal = literal;
                        self.prev_match = match;
                    }
                } else {
                    // There is no better match at current pos then it was previous.
                    // Write previous match or literal.
                    if (self.prev_match) |m| {
                        // Write match from previous position.
                        step = try self.addMatch(m) - 1; // we already advanced 1 from previous position
                    } else {
                        // No match at previous position.
                        // Write previous literal if any, and remember this literal.
                        try self.addPrevLiteral();
                        self.prev_literal = literal;
                    }
                }
                // Advance window and add hashes.
                self.windowAdvance(step, lh, pos);
            }

            if (should_flush) {
                // In the case of flushing, last few lookahead buffers were smaller then min match len.
                // So only last literal can be unwritten.
                assert(self.prev_match == null);
                try self.addPrevLiteral();
                self.prev_literal = null;

                try self.flushTokens(flush_opt);
            }
        }

        fn windowAdvance(self: *Self, step: u16, lh: []const u8, pos: u16) void {
            // current position is already added in findMatch
            self.lookup.bulkAdd(lh[1..], step - 1, pos + 1);
            self.win.advance(step);
        }

        // Add previous literal (if any) to the tokens list.
        fn addPrevLiteral(self: *Self) !void {
            if (self.prev_literal) |l| try self.addToken(Token.initLiteral(l));
        }

        // Add match to the tokens list, reset prev pointers.
        // Returns length of the added match.
        fn addMatch(self: *Self, m: Token) !u16 {
            try self.addToken(m);
            self.prev_literal = null;
            self.prev_match = null;
            return m.length();
        }

        fn addToken(self: *Self, token: Token) !void {
            self.tokens.add(token);
            if (self.tokens.full()) try self.flushTokens(.none);
        }

        // Finds largest match in the history window with the data at current pos.
        fn findMatch(self: *Self, pos: u16, lh: []const u8, min_len: u16) ?Token {
            var len: u16 = min_len;
            // Previous location with the same hash (same 4 bytes).
            var prev_pos = self.lookup.add(lh, pos);
            // Last found match.
            var match: ?Token = null;

            // How much back-references to try, performance knob.
            var chain: usize = self.level.chain;
            if (len >= self.level.good) {
                // If we've got a match that's good enough, only look in 1/4 the chain.
                chain >>= 2;
            }

            // Hot path loop!
            while (prev_pos > 0 and chain > 0) : (chain -= 1) {
                const distance = pos - prev_pos;
                if (distance > consts.match.max_distance)
                    break;

                const new_len = self.win.match(prev_pos, pos, len);
                if (new_len > len) {
                    match = Token.initMatch(@intCast(distance), new_len);
                    if (new_len >= self.level.nice) {
                        // The match is good enough that we don't try to find a better one.
                        return match;
                    }
                    len = new_len;
                }
                prev_pos = self.lookup.prev(prev_pos);
            }

            return match;
        }

        fn flushTokens(self: *Self, flush_opt: FlushOption) !void {
            // Pass tokens to the token writer
            try self.block_writer.write(self.tokens.tokens(), flush_opt == .final, self.win.tokensBuffer());
            // Stored block ensures byte alignment.
            // It has 3 bits (final, block_type) and then padding until byte boundary.
            // After that everything is aligned to the boundary in the stored block.
            // Empty stored block is Ob000 + (0-7) bits of padding + 0x00 0x00 0xFF 0xFF.
            // Last 4 bytes are byte aligned.
            if (flush_opt == .flush) {
                try self.block_writer.storedBlock("", false);
            }
            if (flush_opt != .none) {
                // Safe to call only when byte aligned or it is OK to add
                // padding bits (on last byte of the final block).
                try self.block_writer.flush();
            }
            // Reset internal tokens store.
            self.tokens.reset();
            // Notify win that tokens are flushed.
            self.win.flush();
        }

        // Slide win and if needed lookup tables.
        fn slide(self: *Self) void {
            const n = self.win.slide();
            self.lookup.slide(n);
        }

        /// Compresses as much data as possible, stops when the reader becomes
        /// empty. It will introduce some output latency (reading input without
        /// producing all output) because some data are still in internal
        /// buffers.
        ///
        /// It is up to the caller to call flush (if needed) or finish (required)
        /// when is need to output any pending data or complete stream.
        ///
        pub fn compress(self: *Self, reader: *std.Io.Reader) !void {
            while (true) {
                // Fill window from reader
                const buf = self.win.writable();
                if (buf.len == 0) {
                    try self.tokenize(.none);
                    self.slide();
                    continue;
                }
                const n = try reader.readSliceShort(buf);
                self.hasher.update(buf[0..n]);
                self.win.written(n);
                // Process window
                try self.tokenize(.none);
                // Exit when no more data in reader
                if (n < buf.len) break;
            }
        }

        /// Completes deflate bit stream by writing any pending data as deflate
        /// final deflate block. HAS to be called once all data are written to
        /// the compressor as a signal that next block has to have final bit
        /// set.
        ///
        pub fn finish(self: *Self) !void {
            try self.tokenize(.final);
            try container.writeFooter(&self.hasher, self.source_writer);
        }

        /// Use another writer while preserving history. Most probably flush
        /// should be called on old writer before setting new.
        pub fn setWriter(self: *Self, new_writer: *std.Io.Writer) void {
            self.block_writer.setWriter(new_writer);
            self.source_writer = new_writer;
        }

        // Writer interface
        /// Write `input` of uncompressed data.
        /// See compress.
        pub fn write(self: *Self, input: []const u8) !usize {
            var fixed_reader = std.Io.Reader.fixed(input);
            try self.compress(&fixed_reader);
            return input.len;
        }

        fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
            const self: *Self = @alignCast(@fieldParentPtr("writer", w));

            if (data.len == 0) {
                return 0;
            }

            var written: usize = 0;
            for (data[0 .. data.len - 1]) |bytes| {
                var fixed_reader = std.Io.Reader.fixed(bytes);
                self.compress(&fixed_reader) catch return std.Io.Writer.Error.WriteFailed;
                written += bytes.len;
            }
            const pattern = data[data.len - 1];
            return switch (pattern.len) {
                0 => return written,
                else => {
                    for (0..splat) |_| {
                        var fixed_reader = std.Io.Reader.fixed(pattern);
                        self.compress(&fixed_reader) catch return std.Io.Writer.Error.WriteFailed;
                        written += pattern.len;
                    }

                    return written;
                },
            };
        }

        fn flush(w: *std.Io.Writer) std.Io.Writer.Error!void {
            const self: *Self = @alignCast(@fieldParentPtr("writer", w));

            self.finish() catch return std.Io.Writer.Error.WriteFailed;
        }
    };
}

// Tokens store
const Tokens = struct {
    list: [consts.deflate.tokens]Token = undefined,
    pos: usize = 0,

    fn add(self: *Tokens, t: Token) void {
        self.list[self.pos] = t;
        self.pos += 1;
    }

    fn full(self: *Tokens) bool {
        return self.pos == self.list.len;
    }

    fn reset(self: *Tokens) void {
        self.pos = 0;
    }

    fn tokens(self: *Tokens) []const Token {
        return self.list[0..self.pos];
    }
};

/// Creates huffman only deflate blocks. Disables Lempel-Ziv match searching and
/// only performs Huffman entropy encoding. Results in faster compression, much
/// less memory requirements during compression but bigger compressed sizes.
pub const huffman = struct {
    pub fn compress(comptime container: Container, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        var c = try huffman.compressor(container, writer);
        try c.compress(reader);
        try c.finish();
    }

    pub fn Compressor(comptime container: Container) type {
        return SimpleCompressor(.huffman, container);
    }

    pub fn compressor(comptime container: Container, writer: *std.Io.Writer) !huffman.Compressor(container) {
        return try huffman.Compressor(container).init(writer);
    }
};

/// Creates store blocks only. Data are not compressed only packed into deflate
/// store blocks. That adds 9 bytes of header for each block. Max stored block
/// size is 64K. Block is emitted when flush is called on on finish.
pub const store = struct {
    pub fn compress(comptime container: Container, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        var c = try store.compressor(container, writer);
        try c.compress(reader);
        try c.finish();
    }

    pub fn Compressor(comptime container: Container) type {
        return SimpleCompressor(.store, container);
    }

    pub fn compressor(comptime container: Container, writer: *std.Io.Writer) !store.Compressor(container) {
        return try store.Compressor(container).init(writer);
    }
};

const SimpleCompressorKind = enum {
    huffman,
    store,
};

fn simpleCompressor(
    comptime kind: SimpleCompressorKind,
    comptime container: Container,
    writer: *std.Io.Writer,
) !SimpleCompressor(kind, container) {
    return try SimpleCompressor(kind, container).init(writer);
}

fn SimpleCompressor(
    comptime kind: SimpleCompressorKind,
    comptime container: Container,
) type {
    return struct {
        buffer: [65535]u8 = undefined, // because store blocks are limited to 65535 bytes
        wp: usize = 0,

        wrt: *std.Io.Writer,
        block_writer: BlockWriter,
        hasher: container.Hasher() = .{},

        const Self = @This();

        pub fn init(wrt: *std.Io.Writer) !Self {
            const self = Self{
                .wrt = wrt,
                .block_writer = BlockWriter.init(wrt),
            };
            try container.writeHeader(self.wrt);
            return self;
        }

        pub fn flush(self: *Self) !void {
            try self.flushBuffer(false);
            try self.block_writer.storedBlock("", false);
            try self.block_writer.flush();
        }

        pub fn finish(self: *Self) !void {
            try self.flushBuffer(true);
            try self.block_writer.flush();
            try container.writeFooter(&self.hasher, self.wrt);
        }

        fn flushBuffer(self: *Self, final: bool) !void {
            const buf = self.buffer[0..self.wp];
            switch (kind) {
                .huffman => try self.block_writer.huffmanBlock(buf, final),
                .store => try self.block_writer.storedBlock(buf, final),
            }
            self.wp = 0;
        }

        // Writes all data from the input reader of uncompressed data.
        // It is up to the caller to call flush or finish if there is need to
        // output compressed blocks.
        pub fn compress(self: *Self, reader: *std.Io.Reader) !void {
            while (true) {
                // read from rdr into buffer
                const buf = self.buffer[self.wp..];
                if (buf.len == 0) {
                    try self.flushBuffer(false);
                    continue;
                }
                const n = try reader.readSliceShort(buf);
                self.hasher.update(buf[0..n]);
                self.wp += n;
                if (n < buf.len) break; // no more data in reader
            }
        }

        // Writer interface
        // Write `input` of uncompressed data.
        pub fn write(self: *Self, input: []const u8) !usize {
            var fixed_reader = std.Io.Reader.fixed(input);
            try self.compress(&fixed_reader);
            return input.len;
        }
    };
}
