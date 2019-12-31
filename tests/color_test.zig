const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const color = @import("zigimg").color;
usingnamespace @import("helpers.zig");

test "Convert color to premultipled alpha" {
    const originalColor = color.Color.initRGBA(100, 128, 210, 100);
    const premultipliedAlpha = originalColor.premultipliedAlpha();

    expectEq(premultipliedAlpha.R, 39);
    expectEq(premultipliedAlpha.G, 50);
    expectEq(premultipliedAlpha.B, 82);
    expectEq(premultipliedAlpha.A, 100);
}