const std = @import("std");
const io = std.io;

const adler32 = @This();

pub fn Adler32Writer(comptime WriterType: type) type {
    return struct {
        raw_writer: WriterType,
        adler: u32 = 1,

        pub const Error = WriterType.Error;
        pub const Writer = io.Writer(*Self, Error, write);

        const Self = @This();

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: *Self, bytes: []const u8) Error!usize {
            var s1 = self.adler & 0xffff;
            var s2 = (self.adler >> 16) & 0xffff;

            const amt = try self.raw_writer.write(bytes);
            for (bytes[0..amt]) |b| {
                s1 = (s1 + b) % 65521;
                s2 = (s2 + s1) % 65521;
            }
            self.adler = (s2 << 16) + s1; 

            return amt;
        }
    };
}

pub fn writer(underlying_stream: anytype) Adler32Writer(@TypeOf(underlying_stream)) {
    return .{ .raw_writer = underlying_stream };
}

test "adler32" {
    var buf = std.BoundedArray(u8, 512).init(0) catch unreachable;
    var adl_writer = adler32.writer(buf.writer());
    var adl_wr = adl_writer.writer();

    var fifo = std.fifo.LinearFifo(u8, .{ .Static = 512 }).init();
    try fifo.write("\x63\xF8\xFF\xFF\x3F\x00");

    var decomp = try std.compress.deflate.decompressor(std.heap.page_allocator, fifo.reader(), null);

    var buf2: [512]u8 = undefined;
    var read = try decomp.read(&buf2);

    // Taken from a valid png file I have
    try adl_wr.writeAll(buf2[0..read]);

    try std.testing.expectEqual(@as(u32, 0x05FE02FE), adl_writer.adler);
}