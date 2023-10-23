const std = @import("std");

pub fn load(mem: []const u8, comptime T: type, comptime len: u32) T {
    var result: T = @splat(@as(vectorInnerType(T), 0));
    comptime var vector_len = if (len == 0) vectorLength(T) else len;
    comptime var i: u32 = 0;
    inline while (i < vector_len) : (i += 1) {
        result[i] = mem[i];
    }
    return result;
}

fn vectorLength(comptime VectorType: type) comptime_int {
    return switch (@typeInfo(VectorType)) {
        .Vector => |info| info.len,
        .Array => |info| info.len,
        else => @compileError("Invalid type " ++ @typeName(VectorType)),
    };
}

fn vectorInnerType(comptime VectorType: type) type {
    return switch (@typeInfo(VectorType)) {
        .Vector => |info| info.child,
        .Array => |info| info.child,
        else => @compileError("Invalid type " ++ @typeName(VectorType)),
    };
}
