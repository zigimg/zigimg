const std = @import("std");
const builtin = @import("builtin");

pub const DEFAULT_BUFFER_SIZE = 4096;

pub const ReadStream = union(enum) {
    memory: std.Io.Reader,
    file: std.fs.File.Reader,

    pub const Error = SeekError || EndPosError || std.Io.Reader.Error;
    pub const SeekError = std.fs.File.Reader.SeekError;
    pub const EndPosError = std.fs.File.Reader.SizeError;

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

    pub fn reader(self: *ReadStream) *std.io.Reader {
        return switch (self.*) {
            .memory => |*memory_reader| memory_reader,
            .file => |*file_reader| &file_reader.interface,
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
        }
    }

    pub fn getPos(self: *const ReadStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.seek,
            .file => |*file_reader| file_reader.logicalPos(),
        };
    }

    pub fn getEndPos(self: *ReadStream) EndPosError!u64 {
        return switch (self.*) {
            .memory => |*memory| memory.buffer.len,
            .file => |*file_reader| file_reader.getSize(),
        };
    }
};

pub const WriteStream = union(enum) {
    memory: std.Io.Writer,
    file: std.fs.File.Writer,

    pub const Error = SeekError || std.Io.Writer.Error;
    pub const SeekError = std.fs.File.SeekError;

    pub fn initMemory(buffer: []u8) WriteStream {
        return .{
            .memory = std.Io.Writer.fixed(buffer),
        };
    }

    pub fn initFile(file: std.fs.File, buffer: []u8) WriteStream {
        return .{
            .file = file.writer(buffer),
        };
    }

    pub fn writer(self: *WriteStream) *std.io.Writer {
        return switch (self.*) {
            .memory => |*memory_writer| memory_writer,
            .file => |*file_writer| &file_writer.interface,
        };
    }

    pub fn seekTo(self: *WriteStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                if (offset >= memory.buffer.len) {
                    return SeekError.Unseekable;
                }

                memory.end = offset;
            },
            .file => |*file_writer| {
                self.flush() catch {
                    return SeekError.Unexpected;
                };
                file_writer.interface.end = 0;
                try file_writer.seekTo(offset);
            },
        }
    }

    pub fn getPos(self: *const WriteStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.end,
            .file => |*file_writer| file_writer.pos + file_writer.interface.end,
        };
    }

    pub fn flush(self: *WriteStream) std.Io.Writer.Error!void {
        return switch (self.*) {
            .memory => |*memory| memory.flush(),
            .file => |*file_writer| file_writer.interface.flush(),
        };
    }
};
