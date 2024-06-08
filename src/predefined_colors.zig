const color = @import("../src/color.zig");
const std = @import("std");

/// This a generic function to generate a struct with a set of predefined colors
pub fn Colors(comptime T: type) type {
    return struct {
        const RedT = std.meta.fieldInfo(T, .r).type;
        const GreenT = std.meta.fieldInfo(T, .g).type;
        const BlueT = std.meta.fieldInfo(T, .b).type;

        inline fn toColorValue(comptime TargetType: type, value: f32) TargetType {
            if (TargetType == f32) {
                return value;
            }

            return color.toIntColor(TargetType, value);
        }

        pub const Red = T.initRgb(
            toColorValue(RedT, 1.0),
            toColorValue(GreenT, 0.0),
            toColorValue(BlueT, 0.0),
        );

        pub const Green = T.initRgb(
            toColorValue(RedT, 0.0),
            toColorValue(GreenT, 1.0),
            toColorValue(BlueT, 0.0),
        );

        pub const Blue = T.initRgb(
            toColorValue(RedT, 0.0),
            toColorValue(GreenT, 0.0),
            toColorValue(BlueT, 1.0),
        );

        pub const White = T.initRgb(
            toColorValue(RedT, 1.0),
            toColorValue(GreenT, 1.0),
            toColorValue(BlueT, 1.0),
        );

        pub const Black = T.initRgb(
            toColorValue(RedT, 0.0),
            toColorValue(GreenT, 0.0),
            toColorValue(BlueT, 0.0),
        );

        pub const Cyan = T.initRgb(
            toColorValue(RedT, 0.0),
            toColorValue(GreenT, 1.0),
            toColorValue(BlueT, 1.0),
        );

        pub const Magenta = T.initRgb(
            toColorValue(RedT, 1.0),
            toColorValue(GreenT, 0.0),
            toColorValue(BlueT, 1.0),
        );

        pub const Yellow = T.initRgb(
            toColorValue(RedT, 1.0),
            toColorValue(GreenT, 1.0),
            toColorValue(BlueT, 0.0),
        );
    };
}
