const std = @import("std");

pub fn BufferedIStream(comptime buffer_size: usize, comptime ReaderType: type, comptime SeekableStreamType: type) type {
    return struct {
        const Self = @This();

        unbuffered_reader: ReaderType,
        underlying_stream: SeekableStreamType,
        fifo: FifoType = FifoType.init(),

        pub const ReadError = ReaderType.Error;
        pub const Reader = std.io.Reader(*Self, ReadError, read);

        pub const SeekError = SeekableStreamType.SeekError;
        pub const GetSeekPosError = SeekableStreamType.GetSeekPosError;
        pub const SeekableStream = std.io.SeekableStream(*Self, SeekError, GetSeekPosError, seekTo, seekBy, getPos, getEndPos);

        const FifoType = std.fifo.LinearFifo(u8, std.fifo.LinearFifoBufferType{ .Static = buffer_size });

        pub fn read(self: *Self, dest: []u8) ReadError!usize {
            var dest_index: usize = 0;
            while (dest_index < dest.len) {
                const written = self.fifo.read(dest[dest_index..]);
                if (written == 0) {
                    // fifo empty, fill it
                    const writable = self.fifo.writableSlice(0);
                    std.debug.assert(writable.len > 0);
                    const n = try self.unbuffered_reader.read(writable);
                    if (n == 0) {
                        // reading from the unbuffered stream returned nothing
                        // so we have nothing left to read.
                        return dest_index;
                    }
                    self.fifo.update(n);
                }
                dest_index += written;
            }
            return dest.len;
        }

        pub fn reader(self: *Self) Reader {
            return .{ .context = self };
        }

        pub fn seekTo(self: *Self, pos: u64) SeekError!void {
            self.fifo.discard(self.fifo.count);
            try self.underlying_stream.seekTo(pos);
        }

        pub fn seekBy(self: *Self, amt: i64) SeekError!void {
            if (amt != 0) {
                self.fifo.discard(self.fifo.count);
            }
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

pub fn bufferedIStream(reader: anytype, seekable_stream: anytype) BufferedIStream(4096, @TypeOf(reader), @TypeOf(seekable_stream)) {
    return .{ .unbuffered_reader = reader, .underlying_stream = seekable_stream };
}

test "BufferedIStream" {
    const str = "a1b2 thisisatest";
    var fbs = std.io.fixedBufferStream(str);
    var istream = bufferedIStream(fbs.reader(), fbs.seekableStream());
    var reader = istream.reader();
    var seekable_stream = istream.seekableStream();

    var buffer: [16]u8 = undefined;
    try reader.readNoEof(buffer[0..]);
    try std.testing.expectEqual(@as(usize, 16), fbs.pos);
    try std.testing.expectEqual(@as(u64, 16), try seekable_stream.getPos());
    try std.testing.expectEqualStrings(str, buffer[0..]);

    try seekable_stream.seekTo(2);
    try std.testing.expectEqual(@as(usize, 2), fbs.pos);
    try std.testing.expectEqual(@as(u64, 2), try seekable_stream.getPos());

    try std.testing.expectError(error.EndOfStream, reader.readNoEof(buffer[0..]));
    try std.testing.expectEqual(@as(usize, 16), fbs.pos);
    try std.testing.expectEqual(@as(u64, 16), try seekable_stream.getPos());
    try std.testing.expectEqualStrings(str[2..], buffer[0..14]);

    try seekable_stream.seekBy(-5);
    try std.testing.expectEqual(@as(usize, 11), fbs.pos);
    try std.testing.expectEqual(@as(u64, 11), try seekable_stream.getPos());

    try std.testing.expectError(error.EndOfStream, reader.readNoEof(buffer[0..]));
    try std.testing.expectEqual(@as(usize, 16), fbs.pos);
    try std.testing.expectEqual(@as(u64, 16), try seekable_stream.getPos());
    try std.testing.expectEqualStrings(str[11..], buffer[0..5]);
}
