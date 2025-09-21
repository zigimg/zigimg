const std = @import("std");
const types = @import("types.zig");

source_writer: *std.Io.Writer = undefined,
buffer: [CHUNK_BUFFER_SIZE]u8 = undefined,
chunk: types.Chunk = undefined,
writer: std.Io.Writer = undefined,

const ChunkWriter = @This();

const CHUNK_BUFFER_SIZE = 1 << 14; // 16 Kb

const vtable: std.Io.Writer.VTable = .{
    .drain = drain,
    .flush = flush,
};

pub fn init(self: *ChunkWriter, source_writer: *std.Io.Writer, chunk: types.Chunk) void {
    self.source_writer = source_writer;
    self.writer = .{
        .buffer = self.buffer[0..],
        .vtable = &vtable,
    };
    self.chunk = chunk;
}

fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    const self: *ChunkWriter = @alignCast(@fieldParentPtr("writer", w));

    var crc: std.hash.Crc32 = .init();

    // CRC the chunk name
    crc.update(self.chunk.name[0..]);

    var written: usize = 0;

    // First compute CRC32 and written count for internal buffer and incoming data
    if (w.end > 0) {
        written += w.end;
        crc.update(w.buffered());
    }
    if (data.len > 0) {
        for (data[0 .. data.len - 1]) |bytes| {
            crc.update(bytes);
            written += bytes.len;
        }
        const pattern = data[data.len - 1];
        if (pattern.len > 0) {
            for (0..splat) |_| {
                crc.update(pattern);
                written += pattern.len;
            }
        }
    }

    // Write chunk header
    try self.source_writer.writeInt(u32, @as(u32, @truncate(written)), .big);
    try self.source_writer.writeInt(u32, self.chunk.id, .big);

    // Write remaining of the buffer and the incoming data
    if (w.end > 0) {
        try self.source_writer.writeAll(w.buffered());
        w.end = 0;
    }
    // Write incoming data
    if (data.len > 0) {
        _ = try self.source_writer.writeSplat(data, splat);
    }

    // Write chunk footer (CRC32 checksum)
    try self.source_writer.writeInt(u32, crc.final(), .big);

    return written;
}

fn flush(w: *std.Io.Writer) std.Io.Writer.Error!void {
    const drainFn = w.vtable.drain;

    // Always drain something even if we haven't written yet, like the IEND chunk
    _ = try drainFn(w, &.{""}, 1);
    while (w.end != 0) {
        _ = try drainFn(w, &.{""}, 1);
    }
}
