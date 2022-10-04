const std = @import("std");
const adler32 = @import("adler32.zig");
const io = std.io;
const defl = std.compress.deflate;

/// Zlib Compressor (Deflate) with a writer interface
pub fn ZlibCompressor(comptime WriterType: type) type {
    return struct {
        raw_writer: WriterType,
        compressor: defl.Compressor(WriterType),
        adler32_writer: adler32.Adler32Writer(defl.Compressor(WriterType).Writer),
        
        const Self = @This();

        // TODO: find why doing it an other way segfaults
        /// Inits a zlibcompressor
        /// This is made this way because not doing it in place segfaults for a reason
        pub fn init(self: *Self, alloc: std.mem.Allocator, stream: WriterType) !void {
            self.raw_writer = stream;
            self.compressor = try defl.compressor(alloc, self.raw_writer, .{});
            self.adler32_writer = adler32.writer(self.compressor.writer());
        }

        /// Begins a zlib block with the header
        pub fn begin(self: *Self) !void {
            // TODO: customize
            const cmf = 0x78; // 8 = deflate, 7 = log(window size (see std.compress.deflate)) - 8
            const flg = blk: {
                var ret: u8 = 0b10000000; // 11 = max compression
                const rem: u8 = @truncate(u8, ((@intCast(usize, cmf) << 8) + ret) % 31);
                ret += 31 - @truncate(u8, rem);
                break :blk ret;
            };

            //std.debug.assert(((@intCast(usize, cmf) << 8) + flg) % 31 == 0);
            // write the header
            var wr = self.raw_writer;
            try wr.writeByte(cmf);
            try wr.writeByte(flg);
        }

        const Writer = adler32.Adler32Writer(defl.Compressor(WriterType).Writer).Writer;

        /// Gets a writer for the compressor
        pub fn writer(self: *Self) Writer {
            return self.adler32_writer.writer();
        }

        /// Ends a zlib block with the checksum
        pub fn end(self: *Self) !void {
            try self.compressor.flush();
            self.compressor.deinit();
            // Write the checksum
            var wr = self.raw_writer;
            try wr.writeIntBig(u32, self.adler32_writer.adler);
        }
    };
}

test "zlib compressor" {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const alloc = gpa.allocator();

    {
        var fifo = std.fifo.LinearFifo(u8, .Dynamic).init(alloc);
        defer fifo.deinit();

        var comp: ZlibCompressor(@TypeOf(fifo.writer())) = undefined;
        try comp.init(alloc, fifo.writer());

        const content = "hey abcdef aaaaaa abcdef";

        try comp.begin();

        var adler32_writer = adler32.writer(comp.writer());
        var adl_wr = adler32_writer.writer();
        try adl_wr.writeAll(content);
        try comp.end();

        var decomp = try std.compress.zlib.zlibStream(alloc, fifo.reader());
        defer decomp.deinit();

        var out: [512]u8 = undefined;

        const size = try decomp.read(&out);

        const checksum = try fifo.reader().readIntBig(u32);

        try std.testing.expectEqual(adler32_writer.adler, checksum);
        try std.testing.expectEqualSlices(u8, content, out[0..size]);
    }

    const leaks = gpa.deinit();
    try std.testing.expect(!leaks);
}