const std = @import("std");
const testing = std.testing;

pub const zigimg_test_allocator = &zigimg_test_allocator_instance.allocator;
pub var zigimg_test_allocator_instance = testing.LeakCountAllocator.init(&zigimg_base_allocator_instance.allocator);

pub var zigimg_base_allocator_instance = std.heap.ThreadSafeFixedBufferAllocator.init(zigimg_allocator_mem[0..]);
var zigimg_allocator_mem: [4 * 1024 * 1024]u8 = undefined;

pub fn expectEq(actual: anytype, expected: anytype) void {
    testing.expectEqual(@as(@TypeOf(actual), expected), actual);
}

pub fn expectEqSlice(comptime T: type, actual: []const T, expected: []const T) void {
    testing.expectEqualSlices(T, expected, actual);
}

pub fn expectError(actual: anytype, expected: anyerror) void {
    testing.expectError(expected, actual);
}

pub fn testOpenFile(allocator: *std.mem.Allocator, file_path: []const u8) !std.fs.File {
    const cwd = std.fs.cwd();

    var resolved_path = try std.fs.path.resolve(allocator, &[_][]const u8{file_path});
    defer allocator.free(resolved_path);

    return cwd.openFile(resolved_path, .{});
}
