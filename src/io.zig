const std = @import("std");
const builtin = @import("builtin");

pub const ReadStream = union(enum) {
    memory: std.Io.Reader,
    file: std.fs.File.Reader,
    buffered_file: BufferedFileStream,

    pub const Error = SeekError || EndPosError;
    pub const SeekError = std.fs.File.Reader.SeekError;
    pub const EndPosError = std.fs.File.Reader.SizeError;

    const BufferedFileStream = struct {
        buffer: [4096]u8 = undefined,
        reader: std.fs.File.Reader = undefined,
    };

    pub fn initMemory(buffer: []const u8) ReadStream {
        return .{
            .memory = std.Io.Reader.fixed(buffer),
        };
    }

    pub fn initFile(file: std.fs.File, buffer: []u8) ReadStream {
        return .{
            .file = file.reader(buffer),
        };
    }

    pub fn initBufferedFile(file: std.fs.File) ReadStream {
        var file_stream: BufferedFileStream = .{};

        file_stream.reader = file.reader(file_stream.buffer[0..]);

        return .{
            .buffered_file = file_stream,
        };
    }

    pub fn reader(self: *ReadStream) *std.io.Reader {
        return switch (self.*) {
            .memory => |*memory_reader| memory_reader,
            .file => |*file_reader| &file_reader.interface,
            .buffered_file => |*buffered_file| &buffered_file.reader.interface,
        };
    }

    pub fn seekTo(self: *ReadStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                if (offset >= memory.end) {
                    return SeekError.Unseekable;
                }

                memory.seek = offset;
            },
            .file => |*file_reader| {
                const file_size = file_reader.getSize() catch {
                    return SeekError.Unseekable;
                };

                if (offset >= file_size) {
                    return SeekError.Unseekable;
                }

                try file_reader.seekTo(offset);
            },
            .buffered_file => |*buffered_file| {
                const file_size = buffered_file.reader.getSize() catch {
                    return SeekError.Unseekable;
                };

                if (offset >= file_size) {
                    return SeekError.Unseekable;
                }

                try buffered_file.reader.seekTo(offset);
            },
        }
    }

    pub fn seekBy(self: *ReadStream, offset: i64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                const new_pos: i64 = @as(i64, @intCast(memory.seek)) + offset;
                if (new_pos < 0 or new_pos >= memory.end) {
                    return std.fs.File.SeekError.Unseekable;
                }

                memory.seek = @intCast(new_pos);
            },
            .file => |*file_reader| {
                // Workaround seekBy not working properly (https://github.com/ziglang/zig/issues/25020)
                var new_pos: i64 = @intCast(@as(i64, @intCast(file_reader.interface.seek)) + offset);
                if (new_pos >= 0 and new_pos < file_reader.interface.end) {
                    file_reader.interface.seek = @intCast(new_pos);
                } else {
                    file_reader.interface.seek = 0;
                    file_reader.interface.end = 0;

                    new_pos = @as(i64, @intCast(file_reader.pos)) + offset;

                    const file_size = file_reader.getSize() catch {
                        return std.fs.File.SeekError.Unseekable;
                    };

                    if (new_pos < 0 or new_pos >= file_size) {
                        return std.fs.File.SeekError.Unseekable;
                    }

                    file_reader.pos = @intCast(new_pos);
                }
            },
            .buffered_file => |*buffered_file| {
                // Workaround seekBy not working properly (https://github.com/ziglang/zig/issues/25020)
                var new_pos: i64 = @intCast(@as(i64, @intCast(buffered_file.reader.interface.seek)) + offset);
                if (new_pos >= 0 and new_pos < buffered_file.reader.interface.end) {
                    buffered_file.reader.interface.seek = @intCast(new_pos);
                } else {
                    buffered_file.reader.interface.seek = 0;
                    buffered_file.reader.interface.end = 0;

                    new_pos = @as(i64, @intCast(buffered_file.reader.pos)) + offset;

                    const file_size = buffered_file.reader.getSize() catch {
                        return std.fs.File.SeekError.Unseekable;
                    };

                    if (new_pos < 0 or new_pos >= file_size) {
                        return std.fs.File.SeekError.Unseekable;
                    }

                    buffered_file.reader.pos = @intCast(new_pos);
                }
            },
        }
    }

    pub fn getPos(self: *const ReadStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.seek,
            .file => |*file_reader| file_reader.logicalPos(),
            .buffered_file => |*buffered_file| buffered_file.reader.logicalPos(),
        };
    }

    pub fn getEndPos(self: *ReadStream) EndPosError!u64 {
        return switch (self.*) {
            .memory => |*memory| memory.buffer.len,
            .file => |*file_reader| file_reader.getSize(),
            .buffered_file => |*buffered_file| buffered_file.reader.getSize(),
        };
    }
};
