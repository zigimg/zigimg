const std = @import("std");
const zigimg = @import("zigimg");

pub const zigimg_test_allocator = std.testing.allocator;
pub const fixtures_path = "../test-suite/fixtures/";

pub const TestInput = struct {
    x: u32 = 0,
    y: u32 = 0,
    hex: u32 = 0,
};

pub inline fn expectEq(actual: anytype, expected: anytype) !void {
    try std.testing.expectEqual(@as(@TypeOf(actual), expected), actual);
}

pub inline fn expectEqSlice(comptime T: type, actual: []const T, expected: []const T) !void {
    try std.testing.expectEqualSlices(T, expected, actual);
}

pub inline fn expectError(actual: anytype, expected: anyerror) !void {
    try std.testing.expectError(expected, actual);
}

pub inline fn expectApproxEqAbs(actual: anytype, expected: anytype, tolerance: anytype) !void {
    return try std.testing.expectApproxEqAbs(expected, actual, tolerance);
}

pub inline fn expectApproxEqRel(actual: anytype, expected: anytype, tolerance: anytype) !void {
    return try std.testing.expectApproxEqRel(expected, actual, tolerance);
}

pub fn testOpenFile(io: std.Io, file_path: []const u8) !std.Io.File {
    return std.Io.Dir.cwd().openFile(io, file_path, .{}) catch |err|
        if (err == error.FileNotFound) return error.SkipZigTest else return err;
}

pub fn testDetectFormatFromFilePath(io: std.Io, file_path: []const u8, buffer: []u8) !zigimg.Image.Format {
    return zigimg.Image.detectFormatFromFilePath(io, file_path, buffer) catch |err|
        if (err == error.FileNotFound) return error.SkipZigTest else return err;
}

pub fn testImageFromFileWithAllocator(allocator: std.mem.Allocator, io: std.Io, image_path: []const u8, buffer: []u8) !zigimg.Image {
    return zigimg.Image.fromFilePath(allocator, io, image_path, buffer) catch |err|
        if (err == error.FileNotFound) return error.SkipZigTest else return err;
}

pub fn testImageFromFile(io: std.Io, image_path: []const u8, buffer: []u8) !zigimg.Image {
    return testImageFromFileWithAllocator(zigimg_test_allocator, io, image_path, buffer);
}

pub fn testReadFile(io: std.Io, file_path: []const u8, buffer: []u8) ![]u8 {
    return std.Io.Dir.cwd().readFile(io, file_path, buffer) catch |err|
        if (err == error.FileNotFound) return error.SkipZigTest else return err;
}
