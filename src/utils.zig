const builtin = @import("builtin");
const std = @import("std");

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
    return switch (builtin.target.cpu.arch.endian()) {
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
