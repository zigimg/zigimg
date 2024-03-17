const std = @import("std");
const testing = std.testing;
const math = @import("../src/math.zig");
const helpers = @import("helpers.zig");

test "2x2 matrix identity" {
    const identity_matrix = math.float2x2.identity();

    try helpers.expectEq(identity_matrix.matrix[0][0], 1);
    try helpers.expectEq(identity_matrix.matrix[0][1], 0);
    try helpers.expectEq(identity_matrix.matrix[1][0], 0);
    try helpers.expectEq(identity_matrix.matrix[1][1], 1);
}

test "2x2 matrix determinant" {
    const matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const determinant = matrix.determinant();

    try helpers.expectEq(determinant, -2);
}

test "2x2 matrix multiply to vector" {
    const matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const vector: math.float2 = .{ 5, 6 };

    const result = matrix.mulVector(vector);

    try helpers.expectEq(result[0], 17);
    try helpers.expectEq(result[1], 39);
}

test "2x2 matrix multiply to matrix" {
    const left_matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const right_matrix = math.float2x2.fromArray(.{
        5, 6,
        7, 8,
    });

    const result = left_matrix.mul(right_matrix);

    try helpers.expectEq(result.matrix[0][0], 19);
    try helpers.expectEq(result.matrix[0][1], 22);
    try helpers.expectEq(result.matrix[1][0], 43);
    try helpers.expectEq(result.matrix[1][1], 50);
}
