const io = @import("../io.zig");
const simd = @import("../simd.zig");
const std = @import("std");
const utils = @import("../utils.zig");

pub const CompressorParameters = struct {
    IntType: type,
    PacketFormatterType: type,
    minimum_length: usize = 1,
    maximum_length: usize,
    vector_length: ?comptime_int = null,
};

pub fn Compressor(
    params: CompressorParameters,
) type {
    return struct {
        pub const StreamEncoder = struct {
            similar_count: usize = 0,
            window: utils.FixedDynamicArray(params.IntType, params.maximum_length) = .{},
            state: State = .unique,

            const State = enum {
                unique,
                repeated,
            };

            const Self = @This();

            pub fn clear(self: *Self) void {
                self.window.clear();
                self.similar_count = 0;
            }

            pub fn encodeSlice(self: *Self, writer: *std.Io.Writer, slice: []const params.IntType) std.Io.Writer.Error!void {
                for (slice) |value| {
                    try self.encode(writer, value);
                }
            }

            pub fn encode(self: *Self, writer: *std.Io.Writer, value: params.IntType) std.Io.Writer.Error!void {
                switch (self.state) {
                    .unique => {
                        if (self.window.len > 0) {
                            if (self.window.len >= params.maximum_length) {
                                try params.PacketFormatterType.flushRaw(params.IntType, writer, self.window.constSlice());
                                self.window.clear();
                                self.similar_count = 0;
                            } else {
                                if (self.window.last() == value) {
                                    self.similar_count = 2;

                                    self.state = .repeated;
                                    return;
                                } else {
                                    self.similar_count = 0;
                                }
                            }
                        }

                        self.window.append(value) catch {
                            return std.Io.Writer.Error.WriteFailed;
                        };
                    },
                    .repeated => {
                        if (self.window.last() == value) {
                            self.similar_count += 1;
                        } else {
                            try self.flush(writer);

                            self.window.append(value) catch {
                                return std.Io.Writer.Error.WriteFailed;
                            };

                            self.state = .unique;
                        }
                    },
                }
            }

            pub fn flush(self: *Self, writer: *std.Io.Writer) !void {
                switch (self.state) {
                    .unique => {
                        try params.PacketFormatterType.flushRaw(params.IntType, writer, self.window.constSlice());
                    },
                    .repeated => {
                        if (self.window.len > 1) {
                            const raw_slice = self.window.constSlice()[0..((self.window.len - 2) + 1)];
                            try params.PacketFormatterType.flushRaw(params.IntType, writer, raw_slice);
                        }

                        if (self.similar_count > 0) {
                            var remaining_similar_count = self.similar_count;
                            while (remaining_similar_count > 0) {
                                const effective_similar_count = @min(remaining_similar_count, params.maximum_length);

                                if (effective_similar_count >= params.minimum_length) {
                                    try params.PacketFormatterType.flushRLE(params.IntType, writer, self.window.last(), effective_similar_count);
                                } else {
                                    var buffer: [params.maximum_length]params.IntType = @splat(self.window.last());
                                    const slice = buffer[0..effective_similar_count];
                                    try params.PacketFormatterType.flushRaw(params.IntType, writer, slice);
                                }

                                remaining_similar_count -= effective_similar_count;
                            }
                        }
                    },
                }

                self.clear();
            }
        };

        pub const Simple = struct {
            pub fn encode(source_data: []const u8, writer: *std.Io.Writer) !void {
                if (source_data.len == 0) {
                    return;
                }

                var fixed_stream = io.ReadStream.initMemory(source_data);
                const reader = fixed_stream.reader();

                var stream_encoder: StreamEncoder = .{};

                while (fixed_stream.getPos() < (try fixed_stream.getEndPos())) {
                    const read_value = try reader.takeInt(params.IntType, .little);

                    try stream_encoder.encode(writer, read_value);
                }

                try stream_encoder.flush(writer);
            }
        };

        pub const Simd = struct {
            const MaskType = std.meta.Int(.unsigned, VECTOR_LENGTH);
            const VectorType = @Vector(VECTOR_LENGTH, params.IntType);

            const VECTOR_LENGTH = std.simd.suggestVectorLength(params.IntType) orelse 4;
            const BYTES_PER_PIXELS = (@typeInfo(params.IntType).int.bits + 7) / 8;
            const INDEX_STEP = VECTOR_LENGTH * BYTES_PER_PIXELS;

            comptime {
                if (!std.math.isPowerOfTwo(@typeInfo(params.IntType).int.bits)) {
                    @compileError("Only power of two integers are supported by the run-length SIMD encoder");
                }
            }

            pub fn encode(source_data: []const u8, writer: *std.Io.Writer) !void {
                if (source_data.len == 0) {
                    return;
                }

                var fixed_stream = io.ReadStream.initMemory(source_data);
                const reader = fixed_stream.reader();

                var stream_encoder: StreamEncoder = .{};
                var index: usize = 0;
                while (index < source_data.len and ((index + INDEX_STEP) <= source_data.len)) {
                    switch (stream_encoder.state) {
                        .unique => {
                            if (stream_encoder.window.len >= params.maximum_length) {
                                try params.PacketFormatterType.flushRaw(params.IntType, writer, stream_encoder.window.constSlice());
                                stream_encoder.clear();
                            }

                            const read_value = try reader.takeInt(params.IntType, .little);

                            const current_value_splatted: VectorType = @splat(read_value);
                            const compare_chunk = simd.loadBytes(source_data[index..], VectorType, 0);

                            const compare_mask = (current_value_splatted == compare_chunk);
                            const inverted_mask = ~@as(MaskType, @bitCast(compare_mask));
                            const current_similar_count = @ctz(inverted_mask);

                            if (current_similar_count == VECTOR_LENGTH) {
                                stream_encoder.window.append(read_value) catch return std.Io.Writer.Error.WriteFailed;

                                stream_encoder.similar_count += current_similar_count;
                                stream_encoder.state = .repeated;

                                try reader.discardAll((current_similar_count - 1) * BYTES_PER_PIXELS);
                                index += current_similar_count * BYTES_PER_PIXELS;
                            } else if ((current_similar_count > 0 and stream_encoder.window.len > 0 and stream_encoder.window.last() == read_value) or current_similar_count > 1) {
                                if (stream_encoder.window.len == 0 or stream_encoder.window.last() != read_value) {
                                    stream_encoder.window.append(read_value) catch return std.Io.Writer.Error.WriteFailed;
                                }
                                stream_encoder.state = .repeated;
                                stream_encoder.similar_count += current_similar_count;

                                try stream_encoder.flush(writer);

                                stream_encoder.state = .unique;

                                try reader.discardAll((current_similar_count - 1) * BYTES_PER_PIXELS);
                                index += current_similar_count * BYTES_PER_PIXELS;
                            } else {
                                stream_encoder.window.append(read_value) catch return std.Io.Writer.Error.WriteFailed;
                                index += BYTES_PER_PIXELS;
                            }
                        },
                        .repeated => {
                            const read_value = try reader.takeInt(params.IntType, .little);

                            const current_value_splatted: VectorType = @splat(read_value);
                            const compare_chunk = simd.loadBytes(source_data[index..], VectorType, 0);

                            const compare_mask = (current_value_splatted == compare_chunk);
                            const inverted_mask = ~@as(MaskType, @bitCast(compare_mask));
                            const current_similar_count = @ctz(inverted_mask);

                            if (current_similar_count == VECTOR_LENGTH and read_value == stream_encoder.window.last()) {
                                stream_encoder.similar_count += current_similar_count;

                                try reader.discardAll((current_similar_count - 1) * BYTES_PER_PIXELS);
                                index += current_similar_count * BYTES_PER_PIXELS;
                            } else if (current_similar_count > 0 and read_value == stream_encoder.window.last()) {
                                stream_encoder.similar_count += current_similar_count;

                                try stream_encoder.flush(writer);

                                stream_encoder.state = .unique;

                                try reader.discardAll((current_similar_count - 1) * BYTES_PER_PIXELS);
                                index += current_similar_count * BYTES_PER_PIXELS;
                            } else {
                                try stream_encoder.flush(writer);

                                stream_encoder.window.append(read_value) catch return std.Io.Writer.Error.WriteFailed;
                                stream_encoder.state = .unique;

                                index += BYTES_PER_PIXELS;
                            }
                        },
                    }
                }

                // Process the rest sequentially
                while (index < source_data.len) {
                    const read_value = try reader.takeInt(params.IntType, .little);
                    index += BYTES_PER_PIXELS;

                    try stream_encoder.encode(writer, read_value);
                }

                try stream_encoder.flush(writer);
            }
        };
    };
}
