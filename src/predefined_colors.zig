const color = @import("../src/color.zig");
const std = @import("std");

/// This a generic function to generate a struct with a set of predefined colors
pub fn Colors(comptime T: type) type {
    return struct {
        pub const Red: T =
            T.from.color(color.Colorf32.from.rgb(1.0, 0.0, 0.0));

        pub const Green: T =
            T.from.color(color.Colorf32.from.rgb(0.0, 1.0, 0.0));

        pub const Blue: T =
            T.from.color(color.Colorf32.from.rgb(0.0, 0.0, 1.0));

        pub const White: T =
            T.from.color(color.Colorf32.from.rgb(1.0, 1.0, 1.0));

        pub const Black: T =
            T.from.color(color.Colorf32.from.rgb(0.0, 0.0, 0.0));

        pub const Cyan: T =
            T.from.color(color.Colorf32.from.rgb(0.0, 1.0, 1.0));

        pub const Magenta: T =
            T.from.color(color.Colorf32.from.rgb(1.0, 0.0, 1.0));

        pub const Yellow: T =
            T.from.color(color.Colorf32.from.rgb(1.0, 1.0, 0.0));
    };
}
