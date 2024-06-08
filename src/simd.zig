const std = @import("std");

pub fn load(comptime SourceType: type, source: []const SourceType, comptime VectorType: type, comptime length: u32) VectorType {
    var result: VectorType = @splat(@as(vectorInnerType(VectorType), 0));
    const vector_len = if (length == 0) vectorLength(VectorType) else length;
    comptime var index: u32 = 0;
    inline while (index < vector_len) : (index += 1) {
        result[index] = source[index];
    }
    return result;
}

pub fn loadBytes(source: []const u8, comptime VectorType: type, comptime length: u32) VectorType {
    const mem = std.mem.bytesAsSlice(vectorInnerType(VectorType), source);
    var result: VectorType = @splat(@as(vectorInnerType(VectorType), 0));
    const vector_len = if (length == 0) vectorLength(VectorType) else length;
    comptime var index: u32 = 0;
    inline while (index < vector_len) : (index += 1) {
        result[index] = mem[index];
    }
    return result;
}

pub fn store(comptime DestinationType: type, destination: []DestinationType, vector: anytype, comptime length: u32) void {
    const VectorType = @TypeOf(vector);
    const vector_length = if (length == 0) vectorLength(VectorType) else length;

    comptime var index: u32 = 0;
    inline while (index < vector_length) : (index += 1) {
        destination[index] = vector[index];
    }
}

pub fn intToFloat(comptime DestinationType: type, source: anytype, comptime length: u32) @Vector(length, DestinationType) {
    var result: @Vector(length, DestinationType) = @splat(@as(DestinationType, 0));

    comptime var index: u32 = 0;
    inline while (index < length) : (index += 1) {
        result[index] = @floatFromInt(source[index]);
    }
    return result;
}

pub fn floatToInt(comptime DestinationType: type, source: anytype, comptime length: u32) @Vector(length, DestinationType) {
    var result: @Vector(length, DestinationType) = @splat(@as(DestinationType, 0));

    comptime var index: u32 = 0;
    inline while (index < length) : (index += 1) {
        result[index] = @intFromFloat(source[index]);
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
