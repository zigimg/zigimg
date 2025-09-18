const builtin = @import("builtin");
const std = @import("std");

const native_endian = builtin.target.cpu.arch.endian();

pub const StructReadError = error{InvalidData} || std.Io.Reader.Error;
pub const StructWriteError = std.io.StreamSource.WriteError;

pub fn FixedStorage(comptime T: type, comptime storage_size: usize) type {
    return struct {
        data: []T = &.{},
        storage: [storage_size]T = undefined,

        const Self = @This();

        pub fn resize(self: *Self, size: usize) void {
            self.data = self.storage[0..size];
        }
    };
}

pub fn toMagicNumberNative(magic: []const u8) u32 {
    var result: u32 = 0;
    for (magic, 0..) |character, index| {
        result |= (@as(u32, character) << @intCast((index * 8)));
    }
    return result;
}

pub fn toMagicNumberForeign(magic: []const u8) u32 {
    var result: u32 = 0;
    for (magic, 0..) |character, index| {
        result |= (@as(u32, character) << @intCast((magic.len - 1 - index) * 8));
    }
    return result;
}

pub inline fn toMagicNumber(magic: []const u8, comptime wanted_endian: std.builtin.Endian) u32 {
    return switch (native_endian) {
        .little => {
            return switch (wanted_endian) {
                .little => toMagicNumberNative(magic),
                .big => toMagicNumberForeign(magic),
            };
        },
        .big => {
            return switch (wanted_endian) {
                .little => toMagicNumberForeign(magic),
                .big => toMagicNumberNative(magic),
            };
        },
    };
}

// Only keeping this for PNG load header that can load invalid enum values so std.mem.byteSwapAllFields() is not valid
fn checkEnumFields(data: anytype) StructReadError!void {
    const T = @typeInfo(@TypeOf(data)).pointer.child;
    inline for (std.meta.fields(T)) |entry| {
        switch (@typeInfo(entry.type)) {
            .@"enum" => {
                const value = @intFromEnum(@field(data, entry.name));
                _ = std.enums.fromInt(entry.type, value) orelse return StructReadError.InvalidData;
            },
            .@"struct" => {
                try checkEnumFields(&@field(data, entry.name));
            },
            else => {},
        }
    }
}

// Only keeping this for PNG load header that can load invalid enum values so std.mem.byteSwapAllFields() is not valid
// Deprecated, try to use peek/take Struct from std.Io.Reader instead.
pub fn takeStructNative(reader: *std.Io.Reader, comptime T: type) StructReadError!T {
    const raw_data = try reader.take(@sizeOf(T));
    var result: T = std.mem.bytesToValue(T, raw_data);
    try checkEnumFields(&result);
    return result;
}

// TODO: Remove ?
pub fn writeStructNative(writer: anytype, value: anytype) StructWriteError!void {
    try writer.writeStruct(value);
}

// TODO: Remove ?
pub fn writeStructForeign(writer: anytype, value: anytype) StructWriteError!void {
    const T = @typeInfo(@TypeOf(value));
    inline for (std.meta.fields(T)) |field| {
        switch (@typeInfo(field.type)) {
            .int => {
                try writer.writeIntForeign(field.type, @field(value, field.name));
            },
            .@"struct" => {
                try writeStructForeign(writer, @field(value, field.name));
            },
            .@"enum" => {
                const enum_value = @intFromEnum(@field(value, field.name));
                try writer.writeIntForeign(field.type, enum_value);
            },
            .bool => {
                try writer.writeByte(@intFromBool(@field(value, field.name)));
            },
            else => {
                @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(field.type) ++ " in writeStructForeign()");
            },
        }
    }
}

// Extend std.mem.byteSwapAllFields to support enums with invalid data
fn swapFieldBytes(data: anytype) StructReadError!void {
    const T = @typeInfo(@TypeOf(data)).pointer.child;
    inline for (std.meta.fields(T)) |entry| {
        switch (@typeInfo(entry.type)) {
            .int => |int| {
                if (int.bits > 8) {
                    @field(data, entry.name) = @byteSwap(@field(data, entry.name));
                }
            },
            .@"struct" => {
                try swapFieldBytes(&@field(data, entry.name));
            },
            .@"enum" => {
                const value = @intFromEnum(@field(data, entry.name));
                if (@bitSizeOf(@TypeOf(value)) > 8) {
                    @field(data, entry.name) = std.enums.fromInt(entry.type, @byteSwap(value)) orelse return StructReadError.InvalidData;
                } else {
                    _ = std.enums.fromInt(entry.type, value) orelse return StructReadError.InvalidData;
                }
            },
            .array => |array| {
                if (array.child != u8) {
                    @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(entry.type) ++ " in swapFieldBytes");
                }
            },
            .bool => {},
            else => {
                @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(entry.type) ++ " in swapFieldBytes");
            },
        }
    }
}

// Only keeping this for PNG load header that can load invalid enum values so std.mem.byteSwapAllFields() is not valid
// Deprecated, try to use peek/take Struct from std.Io.Reader instead.
pub fn takeStructForeign(reader: *std.Io.Reader, comptime T: type) StructReadError!T {
    const raw_data = try reader.take(@sizeOf(T));
    var result: T = std.mem.bytesToValue(T, raw_data);
    try swapFieldBytes(&result);
    return result;
}

// Only keeping this for PNG load header that can load invalid enum values so std.mem.byteSwapAllFields() is not valid
// Deprecated, try to use peek/take Struct from std.Io.Reader instead.
pub inline fn takeStruct(reader: *std.Io.Reader, comptime T: type, comptime wanted_endian: std.builtin.Endian) StructReadError!T {
    return switch (native_endian) {
        .little => {
            return switch (wanted_endian) {
                .little => takeStructNative(reader, T),
                .big => takeStructForeign(reader, T),
            };
        },
        .big => {
            return switch (wanted_endian) {
                .little => takeStructForeign(reader, T),
                .big => takeStructNative(reader, T),
            };
        },
    };
}

// TODO: Remove ?
pub inline fn writeStruct(writer: anytype, value: anytype, comptime wanted_endian: std.builtin.Endian) StructWriteError!void {
    return switch (native_endian) {
        .little => {
            return switch (wanted_endian) {
                .little => writeStructNative(writer, value),
                .big => writeStructForeign(writer, value),
            };
        },
        .big => {
            return switch (wanted_endian) {
                .little => writeStructForeign(writer, value),
                .big => writeStructNative(writer, value),
            };
        },
    };
}
