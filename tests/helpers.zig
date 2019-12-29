const testing = @import("std").testing;

pub fn expectEq(actual: var, expected: var) void {
    testing.expectEqual(@as(@TypeOf(actual), expected), actual);
}

pub fn expectEqSlice(comptime T: type, actual: []const T, expected: []const T) void {
    testing.expectEqualSlices(T, expected, actual);
}

pub fn expectError(actual: var, expected: anyerror) void {
    testing.expectError(expected, actual);
}
