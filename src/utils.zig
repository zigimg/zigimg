const builtin = @import("builtin");
const io = @import("std").io;

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
    comptime assert(@typeInfo(T).Struct.layout != builtin.TypeInfo.ContainerLayout.Auto);

    var result: T = undefined;
    inline while (field_i < @memberCount(T)) : (field_i += 1) {
        const currentType = @TypeOf(@field(result, @memberName(T, field_i)));
        switch (@typeInfo(currentType)) {
            .ComptimeInt, .Int => {
                @field(result, @memberName(T, field_i)) = try inStream.readIntForeign(currentType);
            },
            .Struct => {
                @field(result, @memberName(T, field_i)) = try readStructForeign(inStream, currentType);
            },
            .Enum => {
                @field(result, @memberName(T, field_i)) = try inStream.readEnum(currentType, switch (builtin.endian) {
                    builtin.Endian.Little => builtin.Endian.Big,
                    builtin.Endian.Big => builtin.Endian.Little,
                });
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
