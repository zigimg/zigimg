const std = @import("std");

pub fn BufferedOStream(comptime buffer_size: usize, comptime WriterType: type, comptime SeekableStreamType: type) type {
    return struct {
        const Self = @This();

        unbuffered_writer: WriterType,
        underlying_stream: SeekableStreamType,
        fifo: FifoType = FifoType.init(),

        pub const WriteError = WriterType.Error;
        pub const Writer = std.io.Writer(*Self, WriteError, write);

        pub const SeekError = SeekableStreamType.SeekError || WriteError;
        pub const GetSeekPosError = SeekableStreamType.GetSeekPosError;
        pub const SeekableStream = std.io.SeekableStream(*Self, SeekError, GetSeekPosError, seekTo, seekBy, getPos, getEndPos);

        const FifoType = std.fifo.LinearFifo(u8, std.fifo.LinearFifoBufferType{ .Static = buffer_size });

        pub fn flush(self: *Self) !void {
            while (true) {
                const slice = self.fifo.readableSlice(0);
                if (slice.len == 0) break;
                try self.unbuffered_writer.writeAll(slice);
                self.fifo.discard(slice.len);
            }
        }

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            if (bytes.len >= self.fifo.writableLength()) {
                try self.flush();
                return self.unbuffered_writer.write(bytes);
            }
            self.fifo.writeAssumeCapacity(bytes);
            return bytes.len;
        }

        pub fn seekTo(self: *Self, pos: u64) SeekError!void {
            try self.flush();
            try self.underlying_stream.seekTo(pos);
        }

        pub fn seekBy(self: *Self, amt: i64) SeekError!void {
            try self.flush();
            try self.underlying_stream.seekBy(amt);
        }

        pub fn getEndPos(self: *Self) GetSeekPosError!u64 {
            return self.underlying_stream.getEndPos();
        }

        pub fn getPos(self: *Self) GetSeekPosError!u64 {
            return self.underlying_stream.getPos();
        }

        pub fn seekableStream(self: *Self) SeekableStream {
            return .{ .context = self };
        }
    };
}

pub fn bufferedOStream(writer: anytype, seekable_stream: anytype) BufferedOStream(4096, @TypeOf(writer), @TypeOf(seekable_stream)) {
    return .{ .unbuffered_writer = writer, .underlying_stream = seekable_stream };
}

test "BufferedOStream" {
    var buffer = [_]u8{0} ** 4096;
    var fbs = std.io.fixedBufferStream(buffer[0..]);
    var ostream = bufferedOStream(fbs.writer(), fbs.seekableStream());
    var writer = ostream.writer();
    var seekable_stream = ostream.seekableStream();

    try writer.writeAll("abcd1234");
    try ostream.flush();
    try std.testing.expectEqual(@as(usize, 8), fbs.pos);
    try std.testing.expectEqual(@as(u64, 8), try seekable_stream.getPos());
    try std.testing.expectEqualStrings(
        "abcd1234",
        buffer[0..8],
    );

    try seekable_stream.seekTo(1);
    try std.testing.expectEqual(@as(usize, 1), fbs.pos);
    try std.testing.expectEqual(@as(u64, 1), try seekable_stream.getPos());

    try writer.writeAll("cde2345");
    try ostream.flush();
    try std.testing.expectEqual(@as(usize, 8), fbs.pos);
    try std.testing.expectEqual(@as(u64, 8), try seekable_stream.getPos());
    try std.testing.expectEqualStrings("acde2345", buffer[0..8]);

    try seekable_stream.seekBy(1);
    try std.testing.expectEqual(@as(usize, 9), fbs.pos);
    try std.testing.expectEqual(@as(u64, 9), try seekable_stream.getPos());

    try writer.writeAll("foo");
    try ostream.flush();
    try std.testing.expectEqual(@as(usize, 12), fbs.pos);
    try std.testing.expectEqual(@as(u64, 12), try seekable_stream.getPos());
    try std.testing.expectEqualStrings("acde2345\x00foo", buffer[0..12]);
}
