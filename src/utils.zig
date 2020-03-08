const builtin = std.builtin;
const std = @import("std");
const io = std.io;
const meta = std.meta;

pub fn toMagicNumberNative(comptime magic: []const u8) u32 {
    var result: u32 = 0;
    inline for (magic) |character, index| {
        result |= (@as(u32, character) << (index * 8));
    }
    return result;
}

pub fn toMagicNumberForeign(comptime magic: []const u8) u32 {
    var result: u32 = 0;
    inline for (magic) |character, index| {
        result |= (@as(u32, character) << ((magic.len - 1 - index) * 8));
    }
    return result;
}

pub const toMagicNumberBig = switch (builtin.endian) {
    builtin.Endian.Little => toMagicNumberForeign,
    builtin.Endian.Big => toMagicNumberNative,
};

pub const toMagicNumberLittle = switch (builtin.endian) {
    builtin.Endian.Little => toMagicNumberNative,
    builtin.Endian.Big => toMagicNumberForeign,
};

pub fn readStructNative(inStream: io.StreamSource.InStream, comptime T: type) !T {
    return try inStream.readStruct(T);
}

pub fn readStructForeign(inStream: io.StreamSource.InStream, comptime T: type) !T {
    comptime std.debug.assert(@typeInfo(T).Struct.layout != builtin.TypeInfo.ContainerLayout.Auto);

    var result: T = undefined;

    inline for (meta.fields(T)) |entry| {
        switch (@typeInfo(entry.field_type)) {
            .ComptimeInt, .Int => {
                @field(result, entry.name) = try inStream.readIntForeign(entry.field_type);
            },
            .Struct => {
                @field(result, entry.name) = try readStructForeign(inStream, entry.field_type);
            },
            .Enum => {
                @field(result, entry.name) = try inStream.readEnum(entry.field_type, switch (builtin.endian) {
                    builtin.Endian.Little => builtin.Endian.Big,
                    builtin.Endian.Big => builtin.Endian.Little,
                });
            },
            else => {
                std.debug.panic("Add support for type {} in readStructForeign", .{@typeName(entry.field_type)});
            },
        }
    }

    return result;
}

pub const readStructLittle = switch (builtin.endian) {
    builtin.Endian.Little => readStructNative,
    builtin.Endian.Big => readStructForeign,
};

pub const readStructBig = switch (builtin.endian) {
    builtin.Endian.Little => readStructForeign,
    builtin.Endian.Big => readStructNative,
};
