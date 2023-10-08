const builtin = @import("builtin");
const std = @import("std");

const native_endian = builtin.target.cpu.arch.endian();

pub const StructReadError = error{ EndOfStream, InvalidData } || std.io.StreamSource.ReadError;
pub const StructWriteError = std.io.StreamSource.WriteError;

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

pub const toMagicNumberBig = switch (native_endian) {
    .Little => toMagicNumberForeign,
    .Big => toMagicNumberNative,
};

pub const toMagicNumberLittle = switch (native_endian) {
    .Little => toMagicNumberNative,
    .Big => toMagicNumberForeign,
};

fn checkEnumFields(data: anytype) StructReadError!void {
    const T = @typeInfo(@TypeOf(data)).Pointer.child;
    inline for (std.meta.fields(T)) |entry| {
        switch (@typeInfo(entry.type)) {
            .Enum => {
                const value = @intFromEnum(@field(data, entry.name));
                _ = std.meta.intToEnum(entry.type, value) catch return StructReadError.InvalidData;
            },
            .Struct => {
                try checkEnumFields(&@field(data, entry.name));
            },
            else => {},
        }
    }
}

pub fn readStructNative(reader: std.io.StreamSource.Reader, comptime T: type) StructReadError!T {
    var result: T = try reader.readStruct(T);
    try checkEnumFields(&result);
    return result;
}

pub fn writeStructNative(writer: std.io.StreamSource.Writer, value: anytype) StructWriteError!void {
    try writer.writeStruct(value);
}

pub fn writeStructForeign(writer: std.io.StreamSource.Writer, value: anytype) StructWriteError!void {
    const T = @typeInfo(@TypeOf(value));
    inline for (std.meta.fields(T)) |field| {
        switch (@typeInfo(field.type)) {
            .Int => {
                try writer.writeIntForeign(field.type, @field(value, field.name));
            },
            .Struct => {
                try writeStructForeign(writer, @field(value, field.name));
            },
            .Enum => {
                const enum_value = @intFromEnum(@field(value, field.name));
                try writer.writeIntForeign(field.type, enum_value);
            },
            .Bool => {
                try writer.writeByte(@intFromBool(@field(value, field.name)));
            },
            else => {
                @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(field.type) ++ " in writeStructForeign()");
            },
        }
    }
}

fn swapFieldBytes(data: anytype) StructReadError!void {
    const T = @typeInfo(@TypeOf(data)).Pointer.child;
    inline for (std.meta.fields(T)) |entry| {
        switch (@typeInfo(entry.type)) {
            .Int => |int| {
                if (int.bits > 8) {
                    @field(data, entry.name) = @byteSwap(@field(data, entry.name));
                }
            },
            .Struct => {
                try swapFieldBytes(&@field(data, entry.name));
            },
            .Enum => {
                const value = @intFromEnum(@field(data, entry.name));
                if (@bitSizeOf(@TypeOf(value)) > 8) {
                    @field(data, entry.name) = try std.meta.intToEnum(entry.type, @byteSwap(value));
                } else {
                    _ = std.meta.intToEnum(entry.type, value) catch return StructReadError.InvalidData;
                }
            },
            .Array => |array| {
                if (array.child != u8) {
                    @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(entry.type) ++ " in swapFieldBytes");
                }
            },
            .Bool => {},
            else => {
                @compileError("Add support for type " ++ @typeName(T) ++ "." ++ @typeName(entry.type) ++ " in swapFieldBytes");
            },
        }
    }
}

pub fn readStructForeign(reader: std.io.StreamSource.Reader, comptime T: type) StructReadError!T {
    var result: T = try reader.readStruct(T);
    try swapFieldBytes(&result);
    return result;
}

pub const readStructLittle = switch (native_endian) {
    .Little => readStructNative,
    .Big => readStructForeign,
};

pub const readStructBig = switch (native_endian) {
    .Little => readStructForeign,
    .Big => readStructNative,
};

pub const writeStructLittle = switch (native_endian) {
    .Little => writeStructNative,
    .Big => writeStructForeign,
};

pub const writeStructBig = switch (native_endian) {
    .Little => writeStructForeign,
    .Big => writeStructNative,
};
