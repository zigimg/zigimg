const std = @import("std");

const io = std.io;
const mem = std.mem;

const Crc = std.hash.crc.Crc32;

/// Writer based on buffered writer that will write whole chunks of data of [buffer size]
pub fn ChunkWriter(comptime buffer_size: usize, comptime WriterType: type) type {
    return struct {
        unbuffered_writer: WriterType,
        buf: [buffer_size]u8 = undefined,
        end: usize = 0,
        section_id: [4]u8,

        pub const Error = WriterType.Error;
        pub const Writer = io.GenericWriter(*Self, Error, write);

        const Self = @This();

        pub fn flush(self: *Self) !void {
            try self.unbuffered_writer.writeInt(u32, @as(u32, @truncate(self.end)), .big);

            var crc = Crc.init();

            crc.update(&self.section_id);
            try self.unbuffered_writer.writeAll(&self.section_id);
            crc.update(self.buf[0..self.end]);
            try self.unbuffered_writer.writeAll(self.buf[0..self.end]);

            try self.unbuffered_writer.writeInt(u32, crc.final(), .big);

            self.end = 0;
        }

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: *Self, bytes: []const u8) Error!usize {
            if (self.end + bytes.len > self.buf.len) {
                try self.flush();
                if (bytes.len > self.buf.len)
                    return self.unbuffered_writer.write(bytes);
            }

            @memcpy(self.buf[self.end..][0..bytes.len], bytes);
            self.end += bytes.len;
            return bytes.len;
        }
    };
}

const ChunkBufferSize = 1 << 14; // 16 kb

pub fn chunkWriter(underlying_stream: anytype, comptime id: []const u8) ChunkWriter(ChunkBufferSize, @TypeOf(underlying_stream)) {
    if (id.len != 4)
        @compileError("PNG chunk id must be 4 characters");

    return .{ .unbuffered_writer = underlying_stream, .section_id = std.mem.bytesToValue([4]u8, id[0..4]) };
}

// TODO: test idat writer
