const std = @import("std");

pub const ReadStream = union(enum) {
    memory: std.Io.Reader,
    file: FileStream,

    pub const Error = SeekError || EndPosError;
    pub const SeekError = std.fs.File.FileReader.SeekError;
    pub const EndPosError = std.fs.File.FileReader.SizeError;

    const FileStream = struct {
        buffer: [4096]u8 = undefined,
        reader: std.fs.File.Reader = undefined,
    };

    pub fn initMemory(buffer: []const u8) ReadStream {
        return .{
            .memory = std.Io.Reader.fixed(buffer),
        };
    }

    pub fn initFile(file: std.fs.File) ReadStream {
        var file_stream: FileStream = .{};

        file_stream.reader = file.reader(file_stream.buffer[0..]);

        return .{
            .file = file_stream,
        };
    }

    pub fn reader(self: *ReadStream) *std.io.Reader {
        return switch (self.*) {
            .memory => |*memory_reader| memory_reader,
            .file => |*file| &file.reader.interface,
        };
    }

    pub fn seekTo(self: *ReadStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                memory.seek = offset;
            },
            .file => |*file| {
                try file.reader.seekTo(offset);
            },
        }
    }

    pub fn seekBy(self: *ReadStream, offset: i64) SeekError!void {
        switch (self.*) {
            .memory => |*memory| {
                memory.seek += offset;
            },
            .file => |*file| {
                try file.reader.seekBy(offset);
            },
        }
    }

    pub fn getPos(self: *const ReadStream) u64 {
        return switch (self.*) {
            .memory => |*memory| memory.seek,
            .file => |*file| file.reader.logicalPos(),
        };
    }

    pub fn getEndPos(self: *ReadStream) EndPosError!u64 {
        return switch (self.*) {
            .memory => |*memory| memory.buffer.len,
            .file => |*file| try file.reader.getSize(),
        };
    }
};
