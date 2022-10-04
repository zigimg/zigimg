const std = @import("std");
const io = std.io;

const crc = @This();

var crc_table: ?[256]u32 = null;

fn make_crc_table() void {
    const magic_n = 0xedb88320;

    crc_table = @as([256]u32, undefined);

    var n: u32 = 0;
    while (n < 256) : (n += 1) {
        var c: u32 = n;
        var k: usize = 0;
        while (k < 8) : (k += 1) {
            if (c & 1 != 0) {
                c = magic_n ^ (c >> 1);
            } else {
                c >>= 1;
            }
        }
        crc_table.?[n] = c;
    }
}

pub fn CrcWriter(comptime WriterType: type) type {
    return struct {
        raw_writer: WriterType,
        crc: u32 = 0xffffffff,
        count: u64 = 0,

        pub const Error = WriterType.Error;
        pub const Writer = io.Writer(*Self, Error, write);

        const Self = @This();

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: *Self, bytes: []const u8) Error!usize {
            if (crc_table == null)
                make_crc_table();

            const amt = try self.raw_writer.write(bytes);
            for (bytes[0..amt]) |b| {
                const c = self.crc;
                self.crc = crc_table.?[(c ^ b) & 0xff] ^ (c >> 8);
            }
            self.count += amt;

            return amt;
        }

        pub fn getCrc(self: Self) u32 {
            return ~self.crc;
        }

        pub fn clearCrc(self: *Self) void {
            self.crc = 0;
        }
    };
}

pub fn writer(underlying_stream: anytype) CrcWriter(@TypeOf(underlying_stream)) {
    return .{ .raw_writer = underlying_stream };
}

test "crc" {
    var buf = std.BoundedArray(u8, 512).init(0) catch unreachable;
    var crc_writer = crc.writer(buf.writer());
    var crc_wr = crc_writer.writer();

    // Taken from a valid png file I have
    try crc_wr.writeAll("IHDR");
    try crc_wr.writeIntBig(u32, 770);
    try crc_wr.writeIntBig(u32, 807);
    try crc_wr.writeIntBig(u8, 8); // 8 bit color depth
    try crc_wr.writeIntBig(u8, 6); // true color with alpha
    try crc_wr.writeIntBig(u8, 0); // default compression (only standard)
    try crc_wr.writeIntBig(u8, 0); // default filter (only standard)
    try crc_wr.writeIntBig(u8, 0); // no interlace

    try std.testing.expectEqual(@as(u32, 0x8DDDE53D), crc_writer.getCrc());
}
