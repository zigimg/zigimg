const std = @import("std");

// Using HLSL nomenclature for the vector and matrix types
pub const float2 = @Vector(2, f32);
pub const float3 = @Vector(3, f32);
pub const float4 = @Vector(4, f32);

pub const float2x2 = Matrix([2]float2);
pub const float3x3 = Matrix([3]float3);
pub const float4x4 = Matrix([4]float4);

pub fn Matrix(comptime T: type) type {
    return struct {
        matrix: T,

        const ComponentSize = @typeInfo(T).Array.len;
        const VectorType = @Vector(ComponentSize, f32);
        const Self = @This();

        pub fn determinant(self: Self) f32 {
            if (ComponentSize == 2) {
                return self.matrix[0][0] * self.matrix[1][1] - self.matrix[0][1] * self.matrix[1][0];
            } else {
                var temp_matrix = self;

                for (0..(ComponentSize - 1)) |row| {
                    for ((row + 1)..ComponentSize) |next_row| {
                        const factor = temp_matrix.matrix[next_row][row] / temp_matrix.matrix[row][row];

                        for (0..ComponentSize) |column| {
                            temp_matrix.matrix[next_row][column] = temp_matrix.matrix[next_row][column] - factor * temp_matrix.matrix[row][column];
                        }
                    }
                }

                var result: f32 = temp_matrix.matrix[0][0];

                for (1..ComponentSize) |diagonal| {
                    result *= temp_matrix.matrix[diagonal][diagonal];
                }

                return result;
            }
        }

        pub fn fromArray(array: [ComponentSize * ComponentSize]f32) Self {
            var result: Self = undefined;

            for (0..ComponentSize) |row| {
                const stride = row * ComponentSize;
                for (0..ComponentSize) |column| {
                    result.matrix[row][column] = array[stride + column];
                }
            }

            return result;
        }

        pub fn identity() Self {
            var result: Self = undefined;

            inline for (0..ComponentSize) |row| {
                inline for (0..ComponentSize) |column| {
                    result.matrix[row][column] = if (row == column) 1 else 0;
                }
            }

            return result;
        }

        pub fn mulVector(self: Self, vector: VectorType) VectorType {
            var result: VectorType = std.mem.zeroes(VectorType);

            inline for (0..ComponentSize) |row| {
                result[row] = @reduce(.Add, self.matrix[row] * vector);
            }

            return result;
        }

        pub fn mul(self: Self, right: Self) Self {
            var result = std.mem.zeroes(Self);

            const transposed_right = right.transpose();

            for (0..ComponentSize) |row| {
                for (0..ComponentSize) |column| {
                    result.matrix[row][column] = @reduce(.Add, self.matrix[row] * transposed_right.matrix[column]);
                }
            }

            return result;
        }

        pub fn transpose(self: Self) Self {
            var result = std.mem.zeroes(Self);

            for (0..ComponentSize) |row| {
                for (0..ComponentSize) |column| {
                    result.matrix[row][column] = self.matrix[column][row];
                }
            }

            return result;
        }
    };
}
