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

test "load 2x2 matrix from array" {
    const result = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    try helpers.expectEq(result.matrix[0][0], 1);
    try helpers.expectEq(result.matrix[0][1], 2);

    try helpers.expectEq(result.matrix[1][0], 3);
    try helpers.expectEq(result.matrix[1][1], 4);
}

test "2x2 matrix determinant" {
    const matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const determinant = matrix.determinant();

    try helpers.expectEq(determinant, -2);
}

test "2x2 matrix inverse" {
    const matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const result = matrix.inverse();

    try helpers.expectApproxEqAbs(result.matrix[0][0], -2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 1, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[1][0], 1.5, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][1], -0.5, 0.1);
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

test "2x2 matrix transpose" {
    const matrix = math.float2x2.fromArray(.{
        1, 2,
        3, 4,
    });

    const result = matrix.transpose();

    try helpers.expectEq(result.matrix[0][0], 1);
    try helpers.expectEq(result.matrix[0][1], 3);
    try helpers.expectEq(result.matrix[1][0], 2);
    try helpers.expectEq(result.matrix[1][1], 4);
}

test "3x3 matrix identity" {
    const identity_matrix = math.float3x3.identity();

    try helpers.expectEq(identity_matrix.matrix[0][0], 1);
    try helpers.expectEq(identity_matrix.matrix[0][1], 0);
    try helpers.expectEq(identity_matrix.matrix[0][2], 0);

    try helpers.expectEq(identity_matrix.matrix[1][0], 0);
    try helpers.expectEq(identity_matrix.matrix[1][1], 1);
    try helpers.expectEq(identity_matrix.matrix[1][2], 0);

    try helpers.expectEq(identity_matrix.matrix[2][0], 0);
    try helpers.expectEq(identity_matrix.matrix[2][1], 0);
    try helpers.expectEq(identity_matrix.matrix[2][2], 1);
}

test "load 3x3 matrix from array" {
    const result = math.float3x3.fromArray(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });

    try helpers.expectEq(result.matrix[0][0], 1);
    try helpers.expectEq(result.matrix[0][1], 2);
    try helpers.expectEq(result.matrix[0][2], 3);

    try helpers.expectEq(result.matrix[1][0], 4);
    try helpers.expectEq(result.matrix[1][1], 5);
    try helpers.expectEq(result.matrix[1][2], 6);

    try helpers.expectEq(result.matrix[2][0], 7);
    try helpers.expectEq(result.matrix[2][1], 8);
    try helpers.expectEq(result.matrix[2][2], 9);
}

test "3x3 matrix determinant" {
    const matrix = math.float3x3.fromArray(.{
        2, 3, 4,
        4, 4, 6,
        5, 6, 6,
    });

    const determinant = matrix.determinant();
    try helpers.expectEq(determinant, 10);

    const non_determinant_matrix = math.float3x3.fromArray(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });

    const non_determinant = non_determinant_matrix.determinant();
    try helpers.expectEq(non_determinant, 0);
}

test "3x3 matrix inverse" {
    const matrix = math.float3x3.fromArray(.{
        2, 3, 4,
        4, 4, 6,
        5, 6, 6,
    });

    const result = matrix.inverse();

    try helpers.expectApproxEqAbs(result.matrix[0][0], -1.2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 0.6, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][2], 0.2, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[1][0], 0.6, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][1], -0.8, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][2], 0.4, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[2][0], 0.4, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][1], 0.3, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][2], -0.4, 0.1);
}

test "3x3 matrix multiply to vector" {
    const matrix = math.float3x3.fromArray(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });

    const vector: math.float3 = .{ 5, 6, 7 };

    const result = matrix.mulVector(vector);

    try helpers.expectEq(result[0], 38);
    try helpers.expectEq(result[1], 92);
    try helpers.expectEq(result[2], 146);
}

test "3x3 matrix multiply to matrix" {
    const left_matrix = math.float3x3.fromArray(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });

    const right_matrix = math.float3x3.fromArray(.{
        9, 8, 7,
        6, 5, 4,
        3, 2, 11,
    });

    const result = left_matrix.mul(right_matrix);

    try helpers.expectEq(result.matrix[0][0], 30);
    try helpers.expectEq(result.matrix[0][1], 24);
    try helpers.expectEq(result.matrix[0][2], 48);

    try helpers.expectEq(result.matrix[1][0], 84);
    try helpers.expectEq(result.matrix[1][1], 69);
    try helpers.expectEq(result.matrix[1][2], 114);

    try helpers.expectEq(result.matrix[2][0], 138);
    try helpers.expectEq(result.matrix[2][1], 114);
    try helpers.expectEq(result.matrix[2][2], 180);
}

test "3x3 matrix transpose" {
    const matrix = math.float3x3.fromArray(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });

    const result = matrix.transpose();

    try helpers.expectEq(result.matrix[0][0], 1);
    try helpers.expectEq(result.matrix[0][1], 4);
    try helpers.expectEq(result.matrix[0][2], 7);

    try helpers.expectEq(result.matrix[1][0], 2);
    try helpers.expectEq(result.matrix[1][1], 5);
    try helpers.expectEq(result.matrix[1][2], 8);

    try helpers.expectEq(result.matrix[2][0], 3);
    try helpers.expectEq(result.matrix[2][1], 6);
    try helpers.expectEq(result.matrix[2][2], 9);
}

test "4x4 matrix identity" {
    const identity_matrix = math.float4x4.identity();

    try helpers.expectEq(identity_matrix.matrix[0][0], 1);
    try helpers.expectEq(identity_matrix.matrix[0][1], 0);
    try helpers.expectEq(identity_matrix.matrix[0][2], 0);
    try helpers.expectEq(identity_matrix.matrix[0][3], 0);

    try helpers.expectEq(identity_matrix.matrix[1][0], 0);
    try helpers.expectEq(identity_matrix.matrix[1][1], 1);
    try helpers.expectEq(identity_matrix.matrix[1][2], 0);
    try helpers.expectEq(identity_matrix.matrix[1][3], 0);

    try helpers.expectEq(identity_matrix.matrix[2][0], 0);
    try helpers.expectEq(identity_matrix.matrix[2][1], 0);
    try helpers.expectEq(identity_matrix.matrix[2][2], 1);
    try helpers.expectEq(identity_matrix.matrix[2][3], 0);

    try helpers.expectEq(identity_matrix.matrix[3][0], 0);
    try helpers.expectEq(identity_matrix.matrix[3][1], 0);
    try helpers.expectEq(identity_matrix.matrix[3][2], 0);
    try helpers.expectEq(identity_matrix.matrix[3][3], 1);
}

test "load 4x4 matrix from array" {
    const matrix = math.float4x4.fromArray(.{
        2, 3, 4, 5,
        4, 4, 6, 7,
        5, 6, 6, 8,
        6, 1, 2, 3,
    });

    try helpers.expectEq(matrix.matrix[0][0], 2);
    try helpers.expectEq(matrix.matrix[0][1], 3);
    try helpers.expectEq(matrix.matrix[0][2], 4);
    try helpers.expectEq(matrix.matrix[0][3], 5);

    try helpers.expectEq(matrix.matrix[1][0], 4);
    try helpers.expectEq(matrix.matrix[1][1], 4);
    try helpers.expectEq(matrix.matrix[1][2], 6);
    try helpers.expectEq(matrix.matrix[1][3], 7);

    try helpers.expectEq(matrix.matrix[2][0], 5);
    try helpers.expectEq(matrix.matrix[2][1], 6);
    try helpers.expectEq(matrix.matrix[2][2], 6);
    try helpers.expectEq(matrix.matrix[2][3], 8);

    try helpers.expectEq(matrix.matrix[3][0], 6);
    try helpers.expectEq(matrix.matrix[3][1], 1);
    try helpers.expectEq(matrix.matrix[3][2], 2);
    try helpers.expectEq(matrix.matrix[3][3], 3);
}

test "4x4 matrix determinant" {
    const matrix = math.float4x4.fromArray(.{
        2, 3, 4, 5,
        4, 4, 6, 7,
        5, 6, 6, 8,
        6, 1, 2, 3,
    });

    const determinant = matrix.determinant();
    try helpers.expectEq(determinant, 18);
}

test "4x4 matrix inverse" {
    const matrix = math.float4x4.fromArray(.{
        2, 3, 4, 5,
        4, 4, 6, 7,
        5, 6, 6, 8,
        6, 1, 2, 3,
    });

    const result = matrix.inverse();

    try helpers.expectApproxEqAbs(result.matrix[0][0], -0.5, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 0.2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][2], 0.1, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][3], 0.1, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[1][0], -1.3, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][1], 0.3, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][2], 0.6, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][3], -0.3, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[2][0], -2.5, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][1], 2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][2], 0, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][3], -0.5, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[3][0], 3.2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][1], -1.8, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][2], -0.4, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][3], 0.5, 0.1);
}

test "4x4 matrix multiply to vector" {
    const matrix = math.float4x4.fromArray(.{
        2,  3,  4,  5,
        6,  7,  8,  9,
        10, 11, 12, 13,
        14, 15, 16, 17,
    });

    const vector: math.float4 = .{ 2, 3, 4, 5 };

    const result = matrix.mulVector(vector);

    try helpers.expectEq(result[0], 54);
    try helpers.expectEq(result[1], 110);
    try helpers.expectEq(result[2], 166);
    try helpers.expectEq(result[3], 222);
}

test "4x4 matrix multiply to matrix" {
    const left_matrix = math.float4x4.fromArray(.{
        2,  3,  4,  5,
        6,  7,  8,  9,
        10, 11, 12, 13,
        14, 15, 16, 17,
    });

    const right_matrix = math.float4x4.fromArray(.{
        1, 5, 9,  13,
        2, 6, 10, 14,
        3, 7, 11, 15,
        4, 8, 12, 16,
    });

    const result = left_matrix.mul(right_matrix);

    try helpers.expectApproxEqAbs(result.matrix[0][0], 40, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 96, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][2], 152, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][3], 208, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[1][0], 80, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][1], 200, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][2], 320, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][3], 440, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[2][0], 120, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][1], 304, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][2], 488, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][3], 672, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[3][0], 160, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][1], 408, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][2], 656, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][3], 904, 0.1);
}

test "4x4 matrix transpose" {
    const matrix = math.float4x4.fromArray(.{
        2,  3,  4,  5,
        6,  7,  8,  9,
        10, 11, 12, 13,
        14, 15, 16, 17,
    });

    const result = matrix.transpose();

    try helpers.expectApproxEqAbs(result.matrix[0][0], 2, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 6, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][2], 10, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[0][3], 14, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[1][0], 3, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][1], 7, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][2], 11, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[1][3], 15, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[2][0], 4, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][1], 8, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][2], 12, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[2][3], 16, 0.1);

    try helpers.expectApproxEqAbs(result.matrix[3][0], 5, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][1], 9, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][2], 13, 0.1);
    try helpers.expectApproxEqAbs(result.matrix[3][3], 17, 0.1);
}
