const std = @import("std");
const testing = std.testing;
const color = @import("../src/color.zig");
const helpers = @import("helpers.zig");

test "Convert color to premultipled alpha" {
    const originalColor = color.Colorf32.from.rgba(100 / 255, 128 / 255, 210 / 255, 100 / 255);
    const premultipliedAlpha = originalColor.to.premultipliedAlpha();

    try helpers.expectEq(premultipliedAlpha.r, 39 / 255);
    try helpers.expectEq(premultipliedAlpha.g, 50 / 255);
    try helpers.expectEq(premultipliedAlpha.b, 82 / 255);
    try helpers.expectEq(premultipliedAlpha.a, 100 / 255);

    const expectedRgba32 = premultipliedAlpha.to.color(color.Rgba32);
    const originalRgba32 = originalColor.to.color(color.Rgba32);
    const premultipliedAlphaRgba32 = originalRgba32.to.premultipliedAlpha();
    try helpers.expectEq(premultipliedAlphaRgba32, expectedRgba32);

    const expectedRgba64 = premultipliedAlpha.to.color(color.Rgba64);
    const originalRgba64 = originalColor.to.color(color.Rgba64);
    const premultipliedAlphaRgba64 = originalRgba64.to.premultipliedAlpha();
    try helpers.expectEq(premultipliedAlphaRgba64, expectedRgba64);
}

test "Convert Rgb24 to Colorf32" {
    const originalColor = color.Rgb24.from.rgb(100, 128, 210);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 100);
    try helpers.expectEq(result.g, 128);
    try helpers.expectEq(result.b, 210);
    try helpers.expectEq(result.a, 255);
}

test "Convert Rgb48 to Colorf32" {
    const originalColor = color.Rgb48.from.rgb(25500, 32640, 53550);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba64);

    try helpers.expectEq(result.r, 25500);
    try helpers.expectEq(result.g, 32640);
    try helpers.expectEq(result.b, 53550);
    try helpers.expectEq(result.a, 65535);
}

test "Convert Rgba32 to Colorf32" {
    const originalColor = color.Rgba32.from.rgba(1, 2, 3, 4);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 1);
    try helpers.expectEq(result.g, 2);
    try helpers.expectEq(result.b, 3);
    try helpers.expectEq(result.a, 4);
}

test "Convert Rgba64 to Colorf32" {
    const originalColor = color.Rgba64.from.rgba(1, 2, 3, 4);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba64);

    try helpers.expectEq(result.r, 1);
    try helpers.expectEq(result.g, 2);
    try helpers.expectEq(result.b, 3);
    try helpers.expectEq(result.a, 4);
}

test "Convert Rgb332 to Colorf32" {
    const originalColor = color.Rgb332.from.rgb(7, 4, 2);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 255);
    try helpers.expectEq(result.g, 146);
    try helpers.expectEq(result.b, 170);
    try helpers.expectEq(result.a, 255);
}

test "Convert Rgb565 to Colorf32" {
    const originalColor = color.Rgb565.from.rgb(10, 30, 20);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 82);
    try helpers.expectEq(result.g, 121);
    try helpers.expectEq(result.b, 165);
    try helpers.expectEq(result.a, 255);
}

test "Convert Rgb555 to Colorf32" {
    const originalColor = color.Rgb555.from.rgb(16, 20, 24);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 132);
    try helpers.expectEq(result.g, 165);
    try helpers.expectEq(result.b, 197);
    try helpers.expectEq(result.a, 255);
}

test "Convert Bgra32 to Colorf32" {
    const originalColor = color.Bgra32.from.rgba(50, 100, 150, 200);
    const result = originalColor.to.color(color.Colorf32).to.color(color.Rgba32);

    try helpers.expectEq(result.r, 50);
    try helpers.expectEq(result.g, 100);
    try helpers.expectEq(result.b, 150);
    try helpers.expectEq(result.a, 200);
}

test "Convert Grayscale1 to Colorf32" {
    const white = color.Grayscale1{ .value = 1 };
    const whiteColor = white.toColorf32().to.color(color.Rgba32);

    try helpers.expectEq(whiteColor.r, 255);
    try helpers.expectEq(whiteColor.g, 255);
    try helpers.expectEq(whiteColor.b, 255);
    try helpers.expectEq(whiteColor.a, 255);

    const black = color.Grayscale1{ .value = 0 };
    const blackColor = black.toColorf32().to.color(color.Rgba32);

    try helpers.expectEq(blackColor.r, 0);
    try helpers.expectEq(blackColor.g, 0);
    try helpers.expectEq(blackColor.b, 0);
    try helpers.expectEq(blackColor.a, 255);
}

test "Convert Grayscale8 to Colorf32" {
    const original = color.Grayscale8{ .value = 128 };
    const result = original.toColorf32().to.color(color.Rgba32);

    try helpers.expectEq(result.r, 128);
    try helpers.expectEq(result.g, 128);
    try helpers.expectEq(result.b, 128);
    try helpers.expectEq(result.a, 255);
}

test "Convert Grayscale16 to Colorf32" {
    const original = color.Grayscale16{ .value = 21845 };
    const result = original.toColorf32().to.color(color.Rgba32);

    try helpers.expectEq(result.r, 85);
    try helpers.expectEq(result.g, 85);
    try helpers.expectEq(result.b, 85);
    try helpers.expectEq(result.a, 255);
}

test "Rgb from and to U32" {
    const expected = color.Rgba32.from.rgba(0x87, 0x63, 0x47, 0xff);
    const actualU32 = expected.to.u32Rgba();
    const actual = color.Rgba32.from.u32Rgba(actualU32);

    try helpers.expectEq(actualU32, 0x876347FF);
    try helpers.expectEq(actual, expected);

    const actualRgb = color.Rgba32.from.u32Rgb(0x876347);

    try helpers.expectEq(actualRgb.r, 0x87);
    try helpers.expectEq(actualRgb.g, 0x63);
    try helpers.expectEq(actualRgb.b, 0x47);
    try helpers.expectEq(actualRgb.a, 0xff);
}

test "ScaleValue" {
    const toU8 = color.ScaleValue(u8);
    try helpers.expectEq(toU8(@as(f32, 0)), 0);
    try helpers.expectEq(toU8(@as(f32, 0.33)), 84);
    try helpers.expectEq(toU8(@as(f32, 1)), 255);
    try helpers.expectEq(toU8(@as(f32, 1.33)), 255);
    try helpers.expectEq(toU8(@as(f32, -0.33)), 0);

    const toU16 = color.ScaleValue(u16);
    try helpers.expectEq(toU16(@as(f32, 0)), 0);
    try helpers.expectEq(toU16(@as(f32, 0.33)), 21627);
    try helpers.expectEq(toU16(@as(f32, 1)), 65535);
    try helpers.expectEq(toU16(@as(f32, 1.33)), 65535);
    try helpers.expectEq(toU16(@as(f32, -0.33)), 0);
}

test "Colorf32.toFromU32Rgba()" {
    const expected_u32 = [_]u32{ 0xb7e795d2, 0x9967044f, 0xefa1f714, 0x26ce0589, 0xf50f68ea };
    const expected_c32 = [_]color.Colorf32{
        color.Colorf32.from.rgba(0xb7.0 / 255.0, 0xe7.0 / 255.0, 0x95.0 / 255.0, 0xd2.0 / 255.0),
        color.Colorf32.from.rgba(0x99.0 / 255.0, 0x67.0 / 255.0, 0x04.0 / 255.0, 0x4f.0 / 255.0),
        color.Colorf32.from.rgba(0xef.0 / 255.0, 0xa1.0 / 255.0, 0xf7.0 / 255.0, 0x14.0 / 255.0),
        color.Colorf32.from.rgba(0x26.0 / 255.0, 0xce.0 / 255.0, 0x05.0 / 255.0, 0x89.0 / 255.0),
        color.Colorf32.from.rgba(0xf5.0 / 255.0, 0x0f.0 / 255.0, 0x68.0 / 255.0, 0xea.0 / 255.0),
    };
    for (expected_u32, 0..) |expected, i| {
        const actual = color.Colorf32.from.u32Rgba(expected);
        try helpers.expectEq(actual, expected_c32[i]);
        try helpers.expectEq(actual.to.u32Rgba(), expected);
    }
}

test "Colorf32.toFromU64Rgba()" {
    const expected_u64 = [_]u64{ 0xf034da495288b4f0, 0x8f43957daf1fad51, 0xb2c84b7efea70316, 0x68bb87b393a1c104, 0x48b7f617a4520099 };
    const expected_c32 = [_]color.Colorf32{
        color.Colorf32.from.rgba(0xf034.0 / 65535.0, 0xda49.0 / 65535.0, 0x5288.0 / 65535.0, 0xb4f0.0 / 65535.0),
        color.Colorf32.from.rgba(0x8f43.0 / 65535.0, 0x957d.0 / 65535.0, 0xaf1f.0 / 65535.0, 0xad51.0 / 65535.0),
        color.Colorf32.from.rgba(0xb2c8.0 / 65535.0, 0x4b7e.0 / 65535.0, 0xfea7.0 / 65535.0, 0x0316.0 / 65535.0),
        color.Colorf32.from.rgba(0x68bb.0 / 65535.0, 0x87b3.0 / 65535.0, 0x93a1.0 / 65535.0, 0xc104.0 / 65535.0),
        color.Colorf32.from.rgba(0x48b7.0 / 65535.0, 0xf617.0 / 65535.0, 0xa452.0 / 65535.0, 0x0099.0 / 65535.0),
    };
    for (expected_u64, 0..) |expected, i| {
        const actual = color.Colorf32.from.u64Rgba(expected);
        try helpers.expectEq(actual, expected_c32[i]);
        try helpers.expectEq(actual.to.u64Rgba(), expected);
    }
}

test "Rgb.toFromU32Rgba()" {
    const expected_u32 = [_]u32{ 0xb7e795d2, 0x9967044f, 0xefa1f714, 0x26ce0589, 0xf50f68ea };
    const expected_rgb24_from_rgba = [_]color.Rgb24{
        color.Rgb24.from.rgb(0xb7, 0xe7, 0x95),
        color.Rgb24.from.rgb(0x99, 0x67, 0x04),
        color.Rgb24.from.rgb(0xef, 0xa1, 0xf7),
        color.Rgb24.from.rgb(0x26, 0xce, 0x05),
        color.Rgb24.from.rgb(0xf5, 0x0f, 0x68),
    };
    const expected_rgb24_from_rgb = [_]color.Rgb24{
        color.Rgb24.from.rgb(0xe7, 0x95, 0xd2),
        color.Rgb24.from.rgb(0x67, 0x04, 0x4f),
        color.Rgb24.from.rgb(0xa1, 0xf7, 0x14),
        color.Rgb24.from.rgb(0xce, 0x05, 0x89),
        color.Rgb24.from.rgb(0x0f, 0x68, 0xea),
    };
    const expected_rgb555_from_rgb = [_]color.Rgb555{
        color.Rgb555.from.rgb(0xe7 >> 3, 0x95 >> 3, 0xd2 >> 3),
        color.Rgb555.from.rgb(0x67 >> 3, 0x04 >> 3, 0x4f >> 3),
        color.Rgb555.from.rgb(0xa1 >> 3, 0xf7 >> 3, 0x14 >> 3),
        color.Rgb555.from.rgb(0xce >> 3, 0x05 >> 3, 0x89 >> 3),
        color.Rgb555.from.rgb(0x0f >> 3, 0x68 >> 3, 0xea >> 3),
    };
    const expected_rgb565_from_rgb = [_]color.Rgb565{
        color.Rgb565.from.rgb(0xe7 >> 3, 0x95 >> 2, 0xd2 >> 3),
        color.Rgb565.from.rgb(0x67 >> 3, 0x04 >> 2, 0x4f >> 3),
        color.Rgb565.from.rgb(0xa1 >> 3, 0xf7 >> 2, 0x14 >> 3),
        color.Rgb565.from.rgb(0xce >> 3, 0x05 >> 2, 0x89 >> 3),
        color.Rgb565.from.rgb(0x0f >> 3, 0x68 >> 2, 0xea >> 3),
    };

    const expected_colorf32 = [_]color.Colorf32{
        expected_rgb24_from_rgba[0].to.color(color.Colorf32),
        expected_rgb24_from_rgba[1].to.color(color.Colorf32),
        expected_rgb24_from_rgba[2].to.color(color.Colorf32),
        expected_rgb24_from_rgba[3].to.color(color.Colorf32),
        expected_rgb24_from_rgba[4].to.color(color.Colorf32),
    };

    const expected_rgb48_from_rgba = [_]color.Rgb48{
        color.Rgb48.from.rgb(0xb7 * 257, 0xe7 * 257, 0x95 * 257),
        color.Rgb48.from.rgb(0x99 * 257, 0x67 * 257, 0x04 * 257),
        color.Rgb48.from.rgb(0xef * 257, 0xa1 * 257, 0xf7 * 257),
        color.Rgb48.from.rgb(0x26 * 257, 0xce * 257, 0x05 * 257),
        color.Rgb48.from.rgb(0xf5 * 257, 0x0f * 257, 0x68 * 257),
    };
    const expected_rgb48_from_rgb = [_]color.Rgb48{
        color.Rgb48.from.rgb(0xe7 * 257, 0x95 * 257, 0xd2 * 257),
        color.Rgb48.from.rgb(0x67 * 257, 0x04 * 257, 0x4f * 257),
        color.Rgb48.from.rgb(0xa1 * 257, 0xf7 * 257, 0x14 * 257),
        color.Rgb48.from.rgb(0xce * 257, 0x05 * 257, 0x89 * 257),
        color.Rgb48.from.rgb(0x0f * 257, 0x68 * 257, 0xea * 257),
    };
    for (expected_u32, 0..) |expected, i| {
        const actual24_from_rgba = color.Rgb24.from.u32Rgba(expected);
        try helpers.expectEq(actual24_from_rgba, expected_rgb24_from_rgba[i]);
        try helpers.expectEq(actual24_from_rgba.to.u32Rgba(), expected | 0xff);
        const actual24_from_rgb = color.Rgb24.from.u32Rgb(expected);
        try helpers.expectEq(actual24_from_rgb, expected_rgb24_from_rgb[i]);
        try helpers.expectEq(actual24_from_rgb.to.u32Rgba(), expected << 8 | 0xff);
        const actual555_from_rgb = color.Rgb555.from.u32Rgb(expected);
        try helpers.expectEq(actual555_from_rgb, expected_rgb555_from_rgb[i]);
        try helpers.expectEq(actual555_from_rgb.to.u32Rgba(), expected_rgb555_from_rgb[i].to.color(color.Colorf32).to.u32Rgba());
        const actual565_from_rgb = color.Rgb565.from.u32Rgb(expected);
        try helpers.expectEq(actual565_from_rgb, expected_rgb565_from_rgb[i]);
        try helpers.expectEq(actual565_from_rgb.to.u32Rgba(), expected_rgb565_from_rgb[i].to.color(color.Colorf32).to.u32Rgba());

        // We make sure that conversion through u32 give the same result as through f32
        try helpers.expectEq(actual24_from_rgba.to.u32Rgba(), expected_colorf32[i].to.u32Rgba());

        const actual48_from_rgba = color.Rgb48.from.u32Rgba(expected);
        try helpers.expectEq(actual48_from_rgba, expected_rgb48_from_rgba[i]);
        try helpers.expectEq(actual48_from_rgba.to.u32Rgba(), expected | 0xff);
        const actual48_from_rgb = color.Rgb48.from.u32Rgb(expected);
        try helpers.expectEq(actual48_from_rgb, expected_rgb48_from_rgb[i]);
        try helpers.expectEq(actual48_from_rgb.to.u32Rgba(), expected << 8 | 0xff);

        // We make sure that conversion through u64 give the same result as through f32
        try helpers.expectEq(actual48_from_rgba.to.u64Rgba(), expected_colorf32[i].to.u64Rgba());
    }
}

test "Rgb.toFromU64Rgba()" {
    const expected_u64 = [_]u64{ 0xf034da495288b4f0, 0x8f43957daf1fad51, 0xb2c84b7efea70316, 0x68bb87b393a1c104, 0x48b7f617a4520099 };
    const expected_rgb48_from_rgba = [_]color.Rgb48{
        color.Rgb48.from.rgb(0xf034, 0xda49, 0x5288),
        color.Rgb48.from.rgb(0x8f43, 0x957d, 0xaf1f),
        color.Rgb48.from.rgb(0xb2c8, 0x4b7e, 0xfea7),
        color.Rgb48.from.rgb(0x68bb, 0x87b3, 0x93a1),
        color.Rgb48.from.rgb(0x48b7, 0xf617, 0xa452),
    };
    const expected_rgb48_from_rgb = [_]color.Rgb48{
        color.Rgb48.from.rgb(0xda49, 0x5288, 0xb4f0),
        color.Rgb48.from.rgb(0x957d, 0xaf1f, 0xad51),
        color.Rgb48.from.rgb(0x4b7e, 0xfea7, 0x0316),
        color.Rgb48.from.rgb(0x87b3, 0x93a1, 0xc104),
        color.Rgb48.from.rgb(0xf617, 0xa452, 0x0099),
    };

    const expected_colorf32 = [_]color.Colorf32{
        expected_rgb48_from_rgba[0].to.color(color.Colorf32),
        expected_rgb48_from_rgba[1].to.color(color.Colorf32),
        expected_rgb48_from_rgba[2].to.color(color.Colorf32),
        expected_rgb48_from_rgba[3].to.color(color.Colorf32),
        expected_rgb48_from_rgba[4].to.color(color.Colorf32),
    };
    for (expected_u64, 0..) |expected, i| {
        const actual_from_rgba = color.Rgb48.from.u64Rgba(expected);
        try helpers.expectEq(actual_from_rgba, expected_rgb48_from_rgba[i]);
        try helpers.expectEq(actual_from_rgba.to.u64Rgba(), expected | 0xffff);
        const actual_from_rgb = color.Rgb48.from.u64Rgb(expected);
        try helpers.expectEq(actual_from_rgb, expected_rgb48_from_rgb[i]);
        try helpers.expectEq(actual_from_rgb.to.u64Rgba(), expected << 16 | 0xffff);

        // We make sure that conversion through u64 give the same result as through f32
        try helpers.expectEq(actual_from_rgba.to.u64Rgba(), expected_colorf32[i].to.u64Rgba());
    }
}

test "Rgba.toFromU32Rgba()" {
    const expected_u32 = [_]u32{ 0xb7e795d2, 0x9967044f, 0xefa1f714, 0x26ce0589, 0xf50f68ea };
    const expected_rgba32_from_rgba = [_]color.Rgba32{
        color.Rgba32.from.rgba(0xb7, 0xe7, 0x95, 0xd2),
        color.Rgba32.from.rgba(0x99, 0x67, 0x04, 0x4f),
        color.Rgba32.from.rgba(0xef, 0xa1, 0xf7, 0x14),
        color.Rgba32.from.rgba(0x26, 0xce, 0x05, 0x89),
        color.Rgba32.from.rgba(0xf5, 0x0f, 0x68, 0xea),
    };

    const expected_colorf32 = [_]color.Colorf32{
        expected_rgba32_from_rgba[0].to.color(color.Colorf32),
        expected_rgba32_from_rgba[1].to.color(color.Colorf32),
        expected_rgba32_from_rgba[2].to.color(color.Colorf32),
        expected_rgba32_from_rgba[3].to.color(color.Colorf32),
        expected_rgba32_from_rgba[4].to.color(color.Colorf32),
    };

    const expected_rgba64_from_rgba = [_]color.Rgba64{
        color.Rgba64.from.rgba(0xb7 * 257, 0xe7 * 257, 0x95 * 257, 0xd2 * 257),
        color.Rgba64.from.rgba(0x99 * 257, 0x67 * 257, 0x04 * 257, 0x4f * 257),
        color.Rgba64.from.rgba(0xef * 257, 0xa1 * 257, 0xf7 * 257, 0x14 * 257),
        color.Rgba64.from.rgba(0x26 * 257, 0xce * 257, 0x05 * 257, 0x89 * 257),
        color.Rgba64.from.rgba(0xf5 * 257, 0x0f * 257, 0x68 * 257, 0xea * 257),
    };
    for (expected_u32, 0..) |expected, i| {
        const actual32_from_rgba = color.Rgba32.from.u32Rgba(expected);
        try helpers.expectEq(actual32_from_rgba, expected_rgba32_from_rgba[i]);
        try helpers.expectEq(actual32_from_rgba.to.u32Rgba(), expected);

        // We make sure that conversion through u32 give the same result as through f32
        try helpers.expectEq(actual32_from_rgba.to.u32Rgba(), expected_colorf32[i].to.u32Rgba());

        const actual64_from_rgba = color.Rgba64.from.u32Rgba(expected);
        try helpers.expectEq(actual64_from_rgba, expected_rgba64_from_rgba[i]);
        try helpers.expectEq(actual64_from_rgba.to.u32Rgba(), expected);

        // We make sure that conversion through u64 give the same result as through f32
        try helpers.expectEq(actual64_from_rgba.to.u64Rgba(), expected_colorf32[i].to.u64Rgba());
    }
}

test "Rgba.toFromU64Rgba())" {
    const expected_u64 = [_]u64{ 0xf034da495288b4f0, 0x8f43957daf1fad51, 0xb2c84b7efea70316, 0x68bb87b393a1c104, 0x48b7f617a4520099 };
    const expected_rgba64_from_rgba = [_]color.Rgba64{
        color.Rgba64.from.rgba(0xf034, 0xda49, 0x5288, 0xb4f0),
        color.Rgba64.from.rgba(0x8f43, 0x957d, 0xaf1f, 0xad51),
        color.Rgba64.from.rgba(0xb2c8, 0x4b7e, 0xfea7, 0x0316),
        color.Rgba64.from.rgba(0x68bb, 0x87b3, 0x93a1, 0xc104),
        color.Rgba64.from.rgba(0x48b7, 0xf617, 0xa452, 0x0099),
    };

    const expected_colorf32 = [_]color.Colorf32{
        expected_rgba64_from_rgba[0].to.color(color.Colorf32),
        expected_rgba64_from_rgba[1].to.color(color.Colorf32),
        expected_rgba64_from_rgba[2].to.color(color.Colorf32),
        expected_rgba64_from_rgba[3].to.color(color.Colorf32),
        expected_rgba64_from_rgba[4].to.color(color.Colorf32),
    };
    for (expected_u64, 0..) |expected, i| {
        const actual_from_rgba = color.Rgba64.from.u64Rgba(expected);
        try helpers.expectEq(actual_from_rgba, expected_rgba64_from_rgba[i]);
        try helpers.expectEq(actual_from_rgba.to.u64Rgba(), expected);

        // We make sure that conversion through u64 give the same result as through f32
        try helpers.expectEq(actual_from_rgba.to.u64Rgba(), expected_colorf32[i].to.u64Rgba());
    }
}

test "Colorf32 from and to [4]f32 array" {
    const expected = [_]f32{ 0.12, 0.34, 0.56, 0.78 };
    const sample = color.Colorf32.from.array(expected);

    try helpers.expectEq(sample.r, 0.12);
    try helpers.expectEq(sample.g, 0.34);
    try helpers.expectEq(sample.b, 0.56);
    try helpers.expectEq(sample.a, 0.78);
    const actual = sample.to.array();
    try helpers.expectEqSlice(f32, actual[0..], expected[0..]);
}

test "Rgb.from.htmlHex() with valid inputs" {
    const inputs = [_][]const u8{
        "#fff",
        "#ffffff",
        "#000",
        "#000000",
        "#123456",
        "#123",
        "#AFCDEB",
    };

    const expected_colors = [_]color.Rgb24{
        color.Rgb24.from.rgb(0xff, 0xff, 0xff),
        color.Rgb24.from.rgb(0xff, 0xff, 0xff),
        color.Rgb24.from.rgb(0x00, 0x00, 0x00),
        color.Rgb24.from.rgb(0x00, 0x00, 0x00),
        color.Rgb24.from.rgb(0x12, 0x34, 0x56),
        color.Rgb24.from.rgb(0x11, 0x22, 0x33),
        color.Rgb24.from.rgb(0xAF, 0xCD, 0xEB),
    };

    std.debug.assert(inputs.len == expected_colors.len);

    var index: usize = 0;
    while (index < inputs.len) : (index += 1) {
        const actual_color = try color.Rgb24.from.htmlHex(inputs[index]);

        const expected_color = expected_colors[index];

        try helpers.expectEq(actual_color.r, expected_color.r);
        try helpers.expectEq(actual_color.g, expected_color.g);
        try helpers.expectEq(actual_color.b, expected_color.b);
    }
}

test "Rgba.from.htmlHex() with valid inputs" {
    const inputs = [_][]const u8{
        "#ffff",
        "#1234",
        "#ffffffff",
        "#12345678",
        "#ABCDEF9D",
        "#fedcba34",
    };

    const expected_colors = [_]color.Rgba32{
        color.Rgba32.from.rgba(0xff, 0xff, 0xff, 0xff),
        color.Rgba32.from.rgba(0x11, 0x22, 0x33, 0x44),
        color.Rgba32.from.rgba(0xff, 0xff, 0xff, 0xff),
        color.Rgba32.from.rgba(0x12, 0x34, 0x56, 0x78),
        color.Rgba32.from.rgba(0xAB, 0xCD, 0xEF, 0x9D),
        color.Rgba32.from.rgba(0xfe, 0xdc, 0xba, 0x34),
    };

    std.debug.assert(inputs.len == expected_colors.len);

    var index: usize = 0;
    while (index < inputs.len) : (index += 1) {
        const actual_color = try color.Rgba32.from.htmlHex(inputs[index]);

        const expected_color = expected_colors[index];

        try helpers.expectEq(actual_color.r, expected_color.r);
        try helpers.expectEq(actual_color.g, expected_color.g);
        try helpers.expectEq(actual_color.b, expected_color.b);
        try helpers.expectEq(actual_color.a, expected_color.a);
    }
}

test "Rgb.from.htmlHex() with invalid inputs" {
    const inputs = [_][]const u8{
        "#zzz",
        "#ag",
        "#agerty",
        "zxczfet",
        "ffFFFF",
        "abcdef",
        "123456",
        "",
        "#a",
        "#aaaa", // #RGBA should not be valid with Rgb24
        "#12345678", // #RRGGBBAA should not be valid with Rgb24
    };

    var index: usize = 0;
    while (index < inputs.len) : (index += 1) {
        const actual_error = color.Rgb24.from.htmlHex(inputs[index]);

        try helpers.expectError(actual_error, error.InvalidHtmlHexString);
    }
}

test "Rgba.from.htmlHex() with invalid inputs" {
    const inputs = [_][]const u8{
        "#zzz",
        "#ag",
        "#agerty",
        "zxczfet",
        "ffFFFF",
        "abcdef",
        "123456",
        "",
        "#a",
        "#zzzz",
        "12345678",
    };

    var index: usize = 0;
    while (index < inputs.len) : (index += 1) {
        const actual_error = color.Rgba32.from.htmlHex(inputs[index]);

        try helpers.expectError(actual_error, error.InvalidHtmlHexString);
    }
}

const RgbHslTestDataEntry = struct {
    rgb: color.Colorf32 = .{},
    hsl: color.Hsl = .{},
};

const RgbHslTestData = [_]RgbHslTestDataEntry{
    .{ .rgb = .{ .r = 1.0, .g = 1.0, .b = 1.0 }, .hsl = .{ .hue = 0.0, .saturation = 0.0, .luminance = 1.0 } },
    .{ .rgb = .{ .r = 0.5, .g = 0.5, .b = 0.5 }, .hsl = .{ .hue = 0.0, .saturation = 0.0, .luminance = 0.5 } },
    .{ .rgb = .{ .r = 0.0, .g = 0.0, .b = 0.0 }, .hsl = .{ .hue = 0.0, .saturation = 0.0, .luminance = 0.0 } },
    .{ .rgb = .{ .r = 1.0, .g = 0.0, .b = 0.0 }, .hsl = .{ .hue = 0.0, .saturation = 1.0, .luminance = 0.5 } },
    .{ .rgb = .{ .r = 0.750, .g = 0.750, .b = 0.000 }, .hsl = .{ .hue = 60.0, .saturation = 1.000, .luminance = 0.375 } },
    .{ .rgb = .{ .r = 0.000, .g = 0.500, .b = 0.000 }, .hsl = .{ .hue = 120.0, .saturation = 1.000, .luminance = 0.250 } },
    .{ .rgb = .{ .r = 0.500, .g = 1.000, .b = 1.000 }, .hsl = .{ .hue = 180.0, .saturation = 1.000, .luminance = 0.750 } },
    .{ .rgb = .{ .r = 0.500, .g = 0.500, .b = 1.000 }, .hsl = .{ .hue = 240.0, .saturation = 1.000, .luminance = 0.750 } },
    .{ .rgb = .{ .r = 0.750, .g = 0.250, .b = 0.750 }, .hsl = .{ .hue = 300.0, .saturation = 0.500, .luminance = 0.500 } },
    .{ .rgb = .{ .r = 0.628, .g = 0.643, .b = 0.142 }, .hsl = .{ .hue = 61.8, .saturation = 0.638, .luminance = 0.393 } },
    .{ .rgb = .{ .r = 0.255, .g = 0.104, .b = 0.918 }, .hsl = .{ .hue = 251.1, .saturation = 0.832, .luminance = 0.511 } },
    .{ .rgb = .{ .r = 0.116, .g = 0.675, .b = 0.255 }, .hsl = .{ .hue = 134.9, .saturation = 0.707, .luminance = 0.396 } },
    .{ .rgb = .{ .r = 0.941, .g = 0.785, .b = 0.053 }, .hsl = .{ .hue = 49.5, .saturation = 0.893, .luminance = 0.497 } },
    .{ .rgb = .{ .r = 0.704, .g = 0.187, .b = 0.897 }, .hsl = .{ .hue = 283.7, .saturation = 0.775, .luminance = 0.542 } },
    .{ .rgb = .{ .r = 0.931, .g = 0.463, .b = 0.316 }, .hsl = .{ .hue = 14.3, .saturation = 0.817, .luminance = 0.624 } },
    .{ .rgb = .{ .r = 0.998, .g = 0.974, .b = 0.532 }, .hsl = .{ .hue = 56.9, .saturation = 0.991, .luminance = 0.765 } },
    .{ .rgb = .{ .r = 0.099, .g = 0.795, .b = 0.591 }, .hsl = .{ .hue = 162.4, .saturation = 0.779, .luminance = 0.447 } },
    .{ .rgb = .{ .r = 0.211, .g = 0.149, .b = 0.597 }, .hsl = .{ .hue = 248.3, .saturation = 0.601, .luminance = 0.373 } },
    .{ .rgb = .{ .r = 0.495, .g = 0.493, .b = 0.721 }, .hsl = .{ .hue = 240.5, .saturation = 0.290, .luminance = 0.607 } },
};

test "RGB to HSL conversion" {
    for (RgbHslTestData) |entry| {
        const converted_hsl = color.Hsl.fromRgb(entry.rgb);

        try helpers.expectApproxEqAbs(converted_hsl.hue, entry.hsl.hue, 0.1);
        try helpers.expectApproxEqAbs(converted_hsl.saturation, entry.hsl.saturation, 0.1);
        try helpers.expectApproxEqAbs(converted_hsl.luminance, entry.hsl.luminance, 0.1);
    }
}

test "HSL to RGB conversion" {
    for (RgbHslTestData) |entry| {
        const converted_rgb = color.Hsl.toRgb(entry.hsl);

        try helpers.expectApproxEqAbs(converted_rgb.r, entry.rgb.r, 0.1);
        try helpers.expectApproxEqAbs(converted_rgb.g, entry.rgb.g, 0.1);
        try helpers.expectApproxEqAbs(converted_rgb.b, entry.rgb.b, 0.1);
    }
}

test "HSL to HSV conversion" {
    const hsl = color.Hsl{ .hue = 300.0, .saturation = 0.53, .luminance = 0.67 };
    const converted_hsv = hsl.toHsv();

    try helpers.expectApproxEqAbs(converted_hsv.hue, 300.0, 0.0001);
    try helpers.expectApproxEqAbs(converted_hsv.saturation, 0.4140, 0.0001);
    try helpers.expectApproxEqAbs(converted_hsv.value, 0.8449, 0.0001);
}

const RgbHsvTestDataEntry = struct {
    rgb: color.Colorf32 = .{},
    hsv: color.Hsv = .{},
};

const RgbHsvTestData = [_]RgbHsvTestDataEntry{
    .{ .rgb = .{ .r = 1.0, .g = 1.0, .b = 1.0 }, .hsv = .{ .hue = 0.0, .saturation = 0.0, .value = 1.0 } },
    .{ .rgb = .{ .r = 0.5, .g = 0.5, .b = 0.5 }, .hsv = .{ .hue = 0.0, .saturation = 0.0, .value = 0.5 } },
    .{ .rgb = .{ .r = 0.0, .g = 0.0, .b = 0.0 }, .hsv = .{ .hue = 0.0, .saturation = 0.0, .value = 0.0 } },
    .{ .rgb = .{ .r = 1.0, .g = 0.0, .b = 0.0 }, .hsv = .{ .hue = 0.0, .saturation = 1.0, .value = 1.0 } },
    .{ .rgb = .{ .r = 0.750, .g = 0.750, .b = 0.000 }, .hsv = .{ .hue = 60.0, .saturation = 1.000, .value = 0.750 } },
    .{ .rgb = .{ .r = 0.000, .g = 0.500, .b = 0.000 }, .hsv = .{ .hue = 120.0, .saturation = 1.000, .value = 0.500 } },
    .{ .rgb = .{ .r = 0.500, .g = 1.000, .b = 1.000 }, .hsv = .{ .hue = 180.0, .saturation = 0.500, .value = 1.00 } },
    .{ .rgb = .{ .r = 0.500, .g = 0.500, .b = 1.000 }, .hsv = .{ .hue = 240.0, .saturation = 0.500, .value = 1.00 } },
    .{ .rgb = .{ .r = 0.750, .g = 0.250, .b = 0.750 }, .hsv = .{ .hue = 300.0, .saturation = 0.667, .value = 0.750 } },
    .{ .rgb = .{ .r = 0.628, .g = 0.643, .b = 0.142 }, .hsv = .{ .hue = 61.8, .saturation = 0.779, .value = 0.643 } },
    .{ .rgb = .{ .r = 0.255, .g = 0.104, .b = 0.918 }, .hsv = .{ .hue = 251.1, .saturation = 0.887, .value = 0.918 } },
    .{ .rgb = .{ .r = 0.116, .g = 0.675, .b = 0.255 }, .hsv = .{ .hue = 134.9, .saturation = 0.828, .value = 0.675 } },
    .{ .rgb = .{ .r = 0.941, .g = 0.785, .b = 0.053 }, .hsv = .{ .hue = 49.5, .saturation = 0.944, .value = 0.941 } },
    .{ .rgb = .{ .r = 0.704, .g = 0.187, .b = 0.897 }, .hsv = .{ .hue = 283.7, .saturation = 0.792, .value = 0.897 } },
    .{ .rgb = .{ .r = 0.931, .g = 0.463, .b = 0.316 }, .hsv = .{ .hue = 14.3, .saturation = 0.661, .value = 0.931 } },
    .{ .rgb = .{ .r = 0.998, .g = 0.974, .b = 0.532 }, .hsv = .{ .hue = 56.9, .saturation = 0.467, .value = 0.998 } },
    .{ .rgb = .{ .r = 0.099, .g = 0.795, .b = 0.591 }, .hsv = .{ .hue = 162.4, .saturation = 0.875, .value = 0.795 } },
    .{ .rgb = .{ .r = 0.211, .g = 0.149, .b = 0.597 }, .hsv = .{ .hue = 248.3, .saturation = 0.750, .value = 0.597 } },
    .{ .rgb = .{ .r = 0.495, .g = 0.493, .b = 0.721 }, .hsv = .{ .hue = 240.5, .saturation = 0.316, .value = 0.721 } },
};

test "RGB to HSV conversion" {
    for (RgbHsvTestData) |entry| {
        const converted_hsv = color.Hsv.fromRgb(entry.rgb);

        try helpers.expectApproxEqAbs(converted_hsv.hue, entry.hsv.hue, 0.1);
        try helpers.expectApproxEqAbs(converted_hsv.saturation, entry.hsv.saturation, 0.1);
        try helpers.expectApproxEqAbs(converted_hsv.value, entry.hsv.value, 0.1);
    }
}

test "HSV to RGB conversion" {
    for (RgbHsvTestData) |entry| {
        const converted_rgb = color.Hsv.toRgb(entry.hsv);

        try helpers.expectApproxEqAbs(converted_rgb.r, entry.rgb.r, 0.1);
        try helpers.expectApproxEqAbs(converted_rgb.g, entry.rgb.g, 0.1);
        try helpers.expectApproxEqAbs(converted_rgb.b, entry.rgb.b, 0.1);
    }
}

test "HSV to HSL conversion" {
    const hsv = color.Hsv{ .hue = 300.0, .saturation = 0.4140, .value = 0.8449 };
    const converted_hsl = hsv.toHsl();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(converted_hsl.hue, 300.0, float_tolerance);
    try helpers.expectApproxEqAbs(converted_hsl.saturation, 0.53, float_tolerance);
    try helpers.expectApproxEqAbs(converted_hsl.luminance, 0.67, float_tolerance);
}

test "Compute Linear sRGB RGB to XYZ matrix" {
    const result = color.sRGB.rgba_to_xyza;

    const float_tolerance = 0.0001;

    try helpers.expectApproxEqAbs(result.matrix[0][0], 0.4124564, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[0][1], 0.3575761, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[0][2], 0.1804375, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[0][3], 0, float_tolerance);

    try helpers.expectApproxEqAbs(result.matrix[1][0], 0.2126729, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[1][1], 0.7151522, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[1][2], 0.0721750, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[1][3], 0, float_tolerance);

    try helpers.expectApproxEqAbs(result.matrix[2][0], 0.0193339, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[2][1], 0.1191920, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[2][2], 0.9503041, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[2][3], 0, float_tolerance);

    try helpers.expectApproxEqAbs(result.matrix[3][0], 0, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[3][1], 0, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[3][2], 0, float_tolerance);
    try helpers.expectApproxEqAbs(result.matrix[3][3], 1, float_tolerance);
}

test "Linear sRGB to CIE XYZ" {
    const color_to_convert = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.toXYZ(color_to_convert);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.x, 0.262599, float_tolerance);
    try helpers.expectApproxEqAbs(result.y, 0.171790, float_tolerance);
    try helpers.expectApproxEqAbs(result.z, 0.776029, float_tolerance);
}

test "Convert Linear sRGB color to AdobeWideGamutRGB" {
    const color_to_convert = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.convertColor(color.AdobeWideGamutRGB, color_to_convert);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.161246270, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.152638555, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.744218409, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 1.0, float_tolerance);
}

test "Convert Linear sRGB to DCI-P3 Display" {
    const color_to_convert = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.convertColor(color.DCIP3.Display, color_to_convert);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.182245, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.103319, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.739062, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 1.0, float_tolerance);
}

test "Convert Linear sRGB to BT709 (sanity check)" {
    const color_to_convert = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.convertColor(color.BT709, color_to_convert);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 1.0, float_tolerance);
}

test "Convert Linear sRGB to BT2020" {
    const color_to_convert = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.convertColor(color.BT2020, color_to_convert);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.193054512, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.114861697, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.728544116, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 1.0, float_tolerance);
}

test "Convert an array of Linear sRGB to ProPhotoRGB" {
    var colors = [_]color.Colorf32{
        color.Colorf32.from.rgb(0.2, 0.1, 0.8),
        color.Colorf32.from.rgb(1.0, 1.0, 1.0),
        color.Colorf32.from.rgb(0.5, 0.5, 0.0),
        color.Colorf32.from.rgb(0.0, 0.0, 0.0),
        color.Colorf32.from.rgb(0.0, 0.2, 0.4),
    };

    const expected_results = [_]color.Colorf32{
        color.Colorf32.from.rgb(0.251338661, 0.129547358, 0.707502544),
        color.Colorf32.from.rgb(1.0, 1.0, 1.0),
        color.Colorf32.from.rgb(0.429706693, 0.485920370, 0.0672753304),
        color.Colorf32.from.rgb(0.0, 0.0, 0.0),
        color.Colorf32.from.rgb(0.122260347, 0.185960293, 0.369714200),
    };

    color.sRGB.convertColors(color.ProPhotoRGB, colors[0..]);

    const float_tolerance = 0.0001;
    for (expected_results, 0..) |expected, index| {
        const result = colors[index];
        try helpers.expectApproxEqAbs(result.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(result.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(result.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(result.a, expected.a, float_tolerance);
    }
}

test "Convert a sRGB color to CIELab" {
    const source_color = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.toLab(source_color);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.47701, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.67469, float_tolerance);
}

test "Convert a sRGB color to CIELab with alpha" {
    const source_color = color.Colorf32.from.rgba(0.2, 0.1, 0.8, 0.5);

    const result = color.sRGB.toLabAlpha(source_color);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.47701, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.67469, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.5, float_tolerance);
}

test "Convert a CIELab color to sRGB XYZ" {
    const source_color = color.CIELab{ .l = 0.48485, .a = 0.47701, .b = -0.67469 };

    const result = source_color.toXYZ(color.sRGB.white);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.x, 0.262599, float_tolerance);
    try helpers.expectApproxEqAbs(result.y, 0.171790, float_tolerance);
    try helpers.expectApproxEqAbs(result.z, 0.776029, float_tolerance);
}

test "Convert a CIELab color to sRGB XYZ with alpha" {
    const source_color = color.CIELabAlpha{ .l = 0.48485, .a = 0.47701, .b = -0.67469, .alpha = 0.751534 };

    const result = source_color.toXYZAlpha(color.sRGB.white);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.x, 0.262599, float_tolerance);
    try helpers.expectApproxEqAbs(result.y, 0.171790, float_tolerance);
    try helpers.expectApproxEqAbs(result.z, 0.776029, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.751534, float_tolerance);
}

test "Convert a CIELab color to linear sRGB" {
    const source_color = color.CIELab{ .l = 0.48485, .a = 0.47701, .b = -0.67469 };

    const result = color.sRGB.fromLab(source_color, .none);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
}

test "Convert a CIELab color to linear sRGB with alpha" {
    const source_color = color.CIELabAlpha{ .l = 0.48485, .a = 0.47701, .b = -0.67469, .alpha = 0.751534 };

    const result = color.sRGB.fromLabAlpha(source_color, .none);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.751534, float_tolerance);

    const red_lab = color.CIELabAlpha{ .l = 0.532408, .a = 0.800925, .b = 0.672032, .alpha = 1.0 };

    const red_rgba_float = color.sRGB.fromLabAlpha(red_lab, .none);
    try helpers.expectApproxEqAbs(red_rgba_float.r, 1.0, 0.001);
    try helpers.expectApproxEqAbs(red_rgba_float.g, 0.0, 0.001);
    try helpers.expectApproxEqAbs(red_rgba_float.b, 0.0, 0.001);
    try helpers.expectApproxEqAbs(red_rgba_float.a, 1.0, 0.001);

    const red_rgba = red_rgba_float.to.color(color.Rgba32);
    try helpers.expectEq(red_rgba.r, 255);
    try helpers.expectEq(red_rgba.g, 0);
    try helpers.expectEq(red_rgba.b, 0);
    try helpers.expectEq(red_rgba.a, 255);
}

test "Convert a slice of RGBA colors to sRGB XYZ with alpha, in-place" {
    var colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIEXYZAlpha{
        .{ .x = 0.412456, .y = 0.212673, .z = 0.019334, .a = 1.0 }, // Red
        .{ .x = 0.357576, .y = 0.715152, .z = 0.119192, .a = 1.0 }, // Green
        .{ .x = 0.180437, .y = 0.072175, .z = 0.950304, .a = 1.0 }, // Blue
        .{ .x = 0.770033, .y = 0.927825, .z = 0.138526, .a = 1.0 }, // Yellow
        .{ .x = 0.592894, .y = 0.284848, .z = 0.969638, .a = 1.0 }, // Magenta
        .{ .x = 0.538014, .y = 0.787327, .z = 1.069496, .a = 1.0 }, // Cyan
        .{ .x = 0.950470, .y = 1.000000, .z = 1.088830, .a = 1.0 }, // White
        .{ .x = 0.000000, .y = 0.000000, .z = 0.000000, .a = 1.0 }, // Black
    };

    const slice_xyza = color.sRGB.sliceToXYZAlphaInPlace(colors[0..]);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_xyza[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.x, expected.x, float_tolerance);
        try helpers.expectApproxEqAbs(actual.y, expected.y, float_tolerance);
        try helpers.expectApproxEqAbs(actual.z, expected.z, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of RGBA colors to sRGB XYZ with alpha, copy" {
    const colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIEXYZAlpha{
        .{ .x = 0.412456, .y = 0.212673, .z = 0.019334, .a = 1.0 }, // Red
        .{ .x = 0.357576, .y = 0.715152, .z = 0.119192, .a = 1.0 }, // Green
        .{ .x = 0.180437, .y = 0.072175, .z = 0.950304, .a = 1.0 }, // Blue
        .{ .x = 0.770033, .y = 0.927825, .z = 0.138526, .a = 1.0 }, // Yellow
        .{ .x = 0.592894, .y = 0.284848, .z = 0.969638, .a = 1.0 }, // Magenta
        .{ .x = 0.538014, .y = 0.787327, .z = 1.069496, .a = 1.0 }, // Cyan
        .{ .x = 0.950470, .y = 1.000000, .z = 1.088830, .a = 1.0 }, // White
        .{ .x = 0.000000, .y = 0.000000, .z = 0.000000, .a = 1.0 }, // Black
    };

    const slice_xyza = try color.sRGB.sliceToXYZAlphaCopy(helpers.zigimg_test_allocator, colors[0..]);
    defer helpers.zigimg_test_allocator.free(slice_xyza);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_xyza[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.x, expected.x, float_tolerance);
        try helpers.expectApproxEqAbs(actual.y, expected.y, float_tolerance);
        try helpers.expectApproxEqAbs(actual.z, expected.z, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of RGBA colors to sRGB CIELab with alpha, in-place" {
    var colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIELabAlpha{
        .{ .l = 0.532408, .a = 0.800925, .b = 0.672032, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .a = -0.861827, .b = 0.831793, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .a = 0.791875, .b = -1.078602, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .a = -0.215537, .b = 0.944780, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .a = 0.982343, .b = -0.608249, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .a = -0.480875, .b = -0.141312, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_lab = color.sRGB.sliceToLabAlphaInPlace(colors[0..]);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_lab[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of RGBA colors to sRGB CIELab with alpha, copy" {
    const colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIELabAlpha{
        .{ .l = 0.532408, .a = 0.800925, .b = 0.672032, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .a = -0.861827, .b = 0.831793, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .a = 0.791875, .b = -1.078602, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .a = -0.215537, .b = 0.944780, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .a = 0.982343, .b = -0.608249, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .a = -0.480875, .b = -0.141312, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_lab = try color.sRGB.sliceToLabAlphaCopy(helpers.zigimg_test_allocator, colors[0..]);
    defer helpers.zigimg_test_allocator.free(slice_lab);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_lab[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of CIEXYZAlpha colors to linear sRGB RGBA, in-place" {
    var colors = [_]color.CIEXYZAlpha{
        .{ .x = 0.412456, .y = 0.212673, .z = 0.019334, .a = 1.0 }, // Red
        .{ .x = 0.357576, .y = 0.715152, .z = 0.119192, .a = 1.0 }, // Green
        .{ .x = 0.180437, .y = 0.072175, .z = 0.950304, .a = 1.0 }, // Blue
        .{ .x = 0.770033, .y = 0.927825, .z = 0.138526, .a = 1.0 }, // Yellow
        .{ .x = 0.592894, .y = 0.284848, .z = 0.969638, .a = 1.0 }, // Magenta
        .{ .x = 0.538014, .y = 0.787327, .z = 1.069496, .a = 1.0 }, // Cyan
        .{ .x = 0.950470, .y = 1.000000, .z = 1.088830, .a = 1.0 }, // White
        .{ .x = 0.000000, .y = 0.000000, .z = 0.000000, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = color.sRGB.sliceFromXYZAlphaInPlace(colors[0..]);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of CIEXYZAlpha colors to linear sRGB RGBA, copy" {
    const colors = [_]color.CIEXYZAlpha{
        .{ .x = 0.412456, .y = 0.212673, .z = 0.019334, .a = 1.0 }, // Red
        .{ .x = 0.357576, .y = 0.715152, .z = 0.119192, .a = 1.0 }, // Green
        .{ .x = 0.180437, .y = 0.072175, .z = 0.950304, .a = 1.0 }, // Blue
        .{ .x = 0.770033, .y = 0.927825, .z = 0.138526, .a = 1.0 }, // Yellow
        .{ .x = 0.592894, .y = 0.284848, .z = 0.969638, .a = 1.0 }, // Magenta
        .{ .x = 0.538014, .y = 0.787327, .z = 1.069496, .a = 1.0 }, // Cyan
        .{ .x = 0.950470, .y = 1.000000, .z = 1.088830, .a = 1.0 }, // White
        .{ .x = 0.000000, .y = 0.000000, .z = 0.000000, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = try color.sRGB.sliceFromXYZAlphaCopy(helpers.zigimg_test_allocator, colors[0..]);
    defer helpers.zigimg_test_allocator.free(slice_rgba);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of CIELabAlpha colors to linear sRGB RGBA, in-place" {
    var colors = [_]color.CIELabAlpha{
        .{ .l = 0.532408, .a = 0.800925, .b = 0.672032, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .a = -0.861827, .b = 0.831793, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .a = 0.791875, .b = -1.078602, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .a = -0.215537, .b = 0.944780, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .a = 0.982343, .b = -0.608249, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .a = -0.480875, .b = -0.141312, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = color.sRGB.sliceFromLabAlphaInPlace(colors[0..], .none);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of CIELabAlpha colors to linear sRGB RGBA, Copy" {
    const colors = [_]color.CIELabAlpha{
        .{ .l = 0.532408, .a = 0.800925, .b = 0.672032, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .a = -0.861827, .b = 0.831793, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .a = 0.791875, .b = -1.078602, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .a = -0.215537, .b = 0.944780, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .a = 0.982343, .b = -0.608249, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .a = -0.480875, .b = -0.141312, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = try color.sRGB.sliceFromLabAlphaCopy(helpers.zigimg_test_allocator, colors[0..], .none);
    defer helpers.zigimg_test_allocator.free(slice_rgba);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Reduce brightness by 25% of a slice of sRGB RGBA color using CIELab as a intermediate" {
    var colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 0.6434, .g = 0.0000, .b = 0.0000, .a = 1.0 }, // Red
        .{ .r = 0.0000, .g = 0.5196, .b = 0.0000, .a = 1.0 }, // Green
        .{ .r = 0.0000, .g = 0.0000, .b = 0.7990, .a = 1.0 }, // Blue
        .{ .r = 0.4588, .g = 0.4962, .b = 0.0000, .a = 1.0 }, // Yellow
        .{ .r = 0.6320, .g = 0.0000, .b = 0.6532, .a = 1.0 }, // Magenta
        .{ .r = 0.0000, .g = 0.5125, .b = 0.5191, .a = 1.0 }, // Cyan
        .{ .r = 0.4827, .g = 0.4827, .b = 0.4827, .a = 1.0 }, // White
        .{ .r = 0.0000, .g = 0.0000, .b = 0.0000, .a = 1.0 }, // Black
    };

    const slice_lab = color.sRGB.sliceToLabAlphaInPlace(colors[0..]);

    for (slice_lab) |*lab| {
        lab.l *= (1.0 - 0.25);
    }

    const slice_rgba = color.sRGB.sliceFromLabAlphaInPlace(slice_lab, .clamp);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert Colorf32 to Cmykf32" {
    const colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
        .{ .r = 0.2, .g = 0.1, .b = 0.8, .a = 1.0 }, // #3319cc
    };

    const expected_results = [_]color.Cmykf32{
        .{ .c = 0.0000, .m = 1.0000, .y = 1.0000, .k = 0.00 }, // Red
        .{ .c = 1.0000, .m = 0.0000, .y = 1.0000, .k = 0.00 }, // Green
        .{ .c = 1.0000, .m = 1.0000, .y = 0.0000, .k = 0.00 }, // Blue
        .{ .c = 0.0000, .m = 0.0000, .y = 1.0000, .k = 0.00 }, // Yellow
        .{ .c = 0.0000, .m = 1.0000, .y = 0.0000, .k = 0.00 }, // Magenta
        .{ .c = 1.0000, .m = 0.0000, .y = 0.0000, .k = 0.00 }, // Cyan
        .{ .c = 0.0000, .m = 0.0000, .y = 0.0000, .k = 0.00 }, // White
        .{ .c = 0.0000, .m = 0.0000, .y = 0.0000, .k = 1.00 }, // Black
        .{ .c = 0.7500, .m = 0.8750, .y = 0.0000, .k = 0.20 }, // #3319cc
    };

    const float_tolerance = 0.0001;

    for (0..expected_results.len) |index| {
        const actual = color.Cmykf32.fromColorf32(colors[index]);
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.c, expected.c, float_tolerance);
        try helpers.expectApproxEqAbs(actual.m, expected.m, float_tolerance);
        try helpers.expectApproxEqAbs(actual.y, expected.y, float_tolerance);
        try helpers.expectApproxEqAbs(actual.k, expected.k, float_tolerance);
    }
}

test "Convert Cmykf32 to Colorf32" {
    const colors = [_]color.Cmykf32{
        .{ .c = 0.0000, .m = 1.0000, .y = 1.0000, .k = 0.00 }, // Red
        .{ .c = 1.0000, .m = 0.0000, .y = 1.0000, .k = 0.00 }, // Green
        .{ .c = 1.0000, .m = 1.0000, .y = 0.0000, .k = 0.00 }, // Blue
        .{ .c = 0.0000, .m = 0.0000, .y = 1.0000, .k = 0.00 }, // Yellow
        .{ .c = 0.0000, .m = 1.0000, .y = 0.0000, .k = 0.00 }, // Magenta
        .{ .c = 1.0000, .m = 0.0000, .y = 0.0000, .k = 0.00 }, // Cyan
        .{ .c = 0.0000, .m = 0.0000, .y = 0.0000, .k = 0.00 }, // White
        .{ .c = 0.0000, .m = 0.0000, .y = 0.0000, .k = 1.00 }, // Black
        .{ .c = 0.7500, .m = 0.8750, .y = 0.0000, .k = 0.20 }, // #3319cc
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
        .{ .r = 0.2, .g = 0.1, .b = 0.8, .a = 1.0 }, // #3319cc
    };

    const float_tolerance = 0.0001;

    for (0..expected_results.len) |index| {
        const actual = color.Cmykf32.toColorF32(colors[index]);
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert from CIE Lab to CIE LCh(ab)" {
    const lab = color.CIELab{ .l = 0.48485, .a = 0.47701, .b = -0.67469 };

    const result = lab.toLCHab();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 0.82628, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 5.32780, float_tolerance);
}

test "Convert from CIE LCh(ab) to CIE Lab" {
    const lch = color.CIELCHab{ .l = 0.48485, .c = 0.82628, .h = 5.32780 };

    const result = lch.toLab();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.47701, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.67469, float_tolerance);
}

test "Convert from CIE Lab with alpha to CIELCh(ab) with alpha" {
    const lab = color.CIELabAlpha{ .l = 0.48485, .a = 0.47701, .b = -0.67469, .alpha = 0.4567 };

    const result = lab.toLCHabAlpha();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 0.82628, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 5.32780, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.4567, float_tolerance);
}

test "Convert from CIELCh(ab) with alpha to CIE Lab with alpha" {
    const lch = color.CIELCHabAlpha{ .l = 0.48485, .c = 0.82628, .h = 5.32780, .alpha = 0.4567 };

    const result = lch.toLabAlpha();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.47701, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.67469, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.4567, float_tolerance);
}

test "Convert a sRGB RGBA to CIELuv" {
    const rgba = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.toLuv(rgba);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.u, 0.03422, float_tolerance);
    try helpers.expectApproxEqAbs(result.v, -1.06609, float_tolerance);
}

test "Conveert a CIELuv to linear sRGB RGBA" {
    const luv = color.CIELuv{ .l = 0.48485, .u = 0.03422, .v = -1.06609 };

    const result = color.sRGB.fromLuv(luv, .none);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
}

test "Convert a sRGB RGBA to CIELuvAlpha" {
    const rgba = color.Colorf32.from.rgb(0.2, 0.1, 0.8);

    const result = color.sRGB.toLuvAlpha(rgba);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.u, 0.03422, float_tolerance);
    try helpers.expectApproxEqAbs(result.v, -1.06609, float_tolerance);
}

test "Conveert a CIELuvAlpha to linear sRGB RGBA" {
    const luv = color.CIELuvAlpha{ .l = 0.48485, .u = 0.03422, .v = -1.06609, .alpha = 0.12345 };

    const result = color.sRGB.fromLuvAlpha(luv, .none);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.12345, float_tolerance);
}

test "Convert a slice of RGBA colors to sRGB CIELuv with alpha, in-place" {
    var colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIELuvAlpha{
        .{ .l = 0.532408, .u = 1.75015, .v = 0.377564, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .u = -0.830776, .v = 1.073985, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .u = -0.094054, .v = -1.303423, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .u = 0.077056, .v = 1.067866, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .u = 0.840714, .v = -1.086834, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .u = -0.704773, .v = -0.152042, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .u = 0.0, .v = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .u = 0.0, .v = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_luv = color.sRGB.sliceToLuvAlphaInPlace(colors[0..]);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_luv[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.u, expected.u, float_tolerance);
        try helpers.expectApproxEqAbs(actual.v, expected.v, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of RGBA colors to sRGB CIELuv with alpha, copy" {
    const colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.CIELuvAlpha{
        .{ .l = 0.532408, .u = 1.75015, .v = 0.377564, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .u = -0.830776, .v = 1.073985, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .u = -0.094054, .v = -1.303423, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .u = 0.077056, .v = 1.067866, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .u = 0.840714, .v = -1.086834, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .u = -0.704773, .v = -0.152042, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .u = 0.0, .v = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .u = 0.0, .v = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_luv = try color.sRGB.sliceToLuvAlphaCopy(helpers.zigimg_test_allocator, colors[0..]);
    defer helpers.zigimg_test_allocator.free(slice_luv);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_luv[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.u, expected.u, float_tolerance);
        try helpers.expectApproxEqAbs(actual.v, expected.v, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of CIELuvAlpha colors to linear sRGB with alpha, in-place" {
    var colors = [_]color.CIELuvAlpha{
        .{ .l = 0.532408, .u = 1.75015, .v = 0.377564, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .u = -0.830776, .v = 1.073985, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .u = -0.094054, .v = -1.303423, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .u = 0.077056, .v = 1.067866, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .u = 0.840714, .v = -1.086834, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .u = -0.704773, .v = -0.152042, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .u = 0.0, .v = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .u = 0.0, .v = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = color.sRGB.sliceFromLuvAlphaInPlace(colors[0..], .clamp);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of CIELuvAlpha colors to linear sRGB with alpha, copy" {
    const colors = [_]color.CIELuvAlpha{
        .{ .l = 0.532408, .u = 1.75015, .v = 0.377564, .alpha = 1.0 }, // Red
        .{ .l = 0.877347, .u = -0.830776, .v = 1.073985, .alpha = 1.0 }, // Green
        .{ .l = 0.322970, .u = -0.094054, .v = -1.303423, .alpha = 1.0 }, // Blue
        .{ .l = 0.971393, .u = 0.077056, .v = 1.067866, .alpha = 1.0 }, // Yellow
        .{ .l = 0.603242, .u = 0.840714, .v = -1.086834, .alpha = 1.0 }, // Magenta
        .{ .l = 0.911132, .u = -0.704773, .v = -0.152042, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .u = 0.0, .v = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .u = 0.0, .v = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = try color.sRGB.sliceFromLuvAlphaCopy(helpers.zigimg_test_allocator, colors[0..], .clamp);
    defer helpers.zigimg_test_allocator.free(slice_rgba);

    const float_tolerance = 0.0001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert from CIE Luv to CIE LCh(uv)" {
    const luv = color.CIELuv{ .l = 0.48485, .u = 0.034216, .v = -1.066091 };

    const result = luv.toLCHuv();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 1.066640, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 4.744472, float_tolerance);
}

test "Convert from CIE LCh(uv) to CIE Luv" {
    const lch = color.CIELCHuv{ .l = 0.48485, .c = 1.066640, .h = 4.744472 };

    const result = lch.toLuv();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.u, 0.034216, float_tolerance);
    try helpers.expectApproxEqAbs(result.v, -1.066091, float_tolerance);
}

test "Convert from CIE Luv with alpha to CIE LCh(uv) with alpha" {
    const luv = color.CIELuvAlpha{ .l = 0.48485, .u = 0.034216, .v = -1.066091, .alpha = 0.12345 };

    const result = luv.toLCHuvAlpha();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 1.066640, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 4.744472, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.12345, float_tolerance);
}

test "Convert from CIE LCh(uv) with alpha to CIE Luv with alpha" {
    const lch = color.CIELCHuvAlpha{ .l = 0.48485, .c = 1.066640, .h = 4.744472, .alpha = 0.12345 };

    const result = lch.toLuvAlpha();

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.l, 0.48485, float_tolerance);
    try helpers.expectApproxEqAbs(result.u, 0.034216, float_tolerance);
    try helpers.expectApproxEqAbs(result.v, -1.066091, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.12345, float_tolerance);
}

test "Convert a HSLuv color to gamma sRGB color" {
    const hsluv = color.HSLuv{ .h = std.math.degreesToRadians(243.0), .s = 0.61, .l = 0.51 };

    const linear = color.sRGB.fromHSLuv(hsluv, .none);

    const result = color.sRGB.toGamma(linear);

    // #537da6
    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.324444026, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.490519762, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.651108801, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 1.0, float_tolerance);

    const rgba = result.to.color(color.Rgba32);
    try helpers.expectEq(rgba.r, 0x53);
    try helpers.expectEq(rgba.g, 0x7d);
    try helpers.expectEq(rgba.b, 0xa6);
    try helpers.expectEq(rgba.a, 0xFF);
}

test "Convert a gamma sRGB color to HSLuv" {
    // #537da6
    const srgb = color.Colorf32{ .r = 0.32549, .g = 0.4902, .b = 0.65098, .a = 1.0 };
    const source = color.sRGB.toLinear(srgb);

    const result = color.sRGB.toHSLuv(source);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.h, 4.24362755, float_tolerance);
    try helpers.expectApproxEqAbs(result.s, 0.607237875, float_tolerance);
    try helpers.expectApproxEqAbs(result.l, 0.509887099, float_tolerance);
}

test "Convert a HSLuv with alpha color to gamma sRGB color with alpha" {
    const hsluv = color.HSLuvAlpha{ .h = std.math.degreesToRadians(243.0), .s = 0.61, .l = 0.51, .alpha = 0.12345 };

    const linear = color.sRGB.fromHSLuvAlpha(hsluv, .none);

    const result = color.sRGB.toGamma(linear);

    // #537da6
    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.r, 0.324444026, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.490519762, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.651108801, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.12345, float_tolerance);

    const rgba = result.to.color(color.Rgba32);
    try helpers.expectEq(rgba.r, 0x53);
    try helpers.expectEq(rgba.g, 0x7d);
    try helpers.expectEq(rgba.b, 0xa6);
    try helpers.expectEq(rgba.a, 0x1f);
}

test "Convert a gamma sRGB color with alpha to HSLuv with alpha" {
    // #537da6
    const srgb = color.Colorf32{ .r = 0.32549, .g = 0.4902, .b = 0.65098, .a = 0.12345 };
    const source = color.sRGB.toLinear(srgb);

    const result = color.sRGB.toHSLuvAlpha(source);

    const float_tolerance = 0.0001;
    try helpers.expectApproxEqAbs(result.h, 4.24362755, float_tolerance);
    try helpers.expectApproxEqAbs(result.s, 0.607237875, float_tolerance);
    try helpers.expectApproxEqAbs(result.l, 0.509887099, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.12345, float_tolerance);
}

test "Convert CIE XYZA to Oklab Alpha" {
    const xyza = [_]color.CIEXYZAlpha{
        .{ .x = 0.950, .y = 1.000, .z = 1.089, .a = 1.0 },
        .{ .x = 1.000, .y = 0.000, .z = 0.000, .a = 1.0 },
        .{ .x = 0.000, .y = 1.000, .z = 0.000, .a = 1.0 },
        .{ .x = 0.000, .y = 0.000, .z = 1.000, .a = 1.0 },
    };

    const lab = [_]color.OklabAlpha{
        .{ .l = 1.000, .a = 0.000, .b = 0.000, .alpha = 1.0 },
        .{ .l = 0.450, .a = 1.236, .b = -0.019, .alpha = 1.0 },
        .{ .l = 0.922, .a = -0.671, .b = 0.263, .alpha = 1.0 },
        .{ .l = 0.153, .a = -1.415, .b = -0.449, .alpha = 1.0 },
    };

    for (0..lab.len) |index| {
        const actual = color.OklabAlpha.fromXYZAlpha(xyza[index]);
        const expected = lab[index];

        const float_tolerance = 0.001;
        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert linear sRGB to Oklab" {
    const rgba = color.Colorf32{ .r = 0.2, .g = 0.1, .b = 0.8, .a = 1.0 };

    const result = color.sRGB.toOklab(rgba);

    const float_tolerance = 0.00001;
    try helpers.expectApproxEqAbs(result.l, 0.576150835, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.0686165094, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.193039685, float_tolerance);
}

test "Convert Oklab to linear sRGB" {
    const lab = color.Oklab{ .l = 0.576150835, .a = 0.0686165094, .b = -0.193039685 };

    const result = color.sRGB.fromOkLab(lab, .none);

    const float_tolerance = 0.00001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
}
//
test "Convert linear sRGB with alpha to Oklab with alpha" {
    const rgba = color.Colorf32{ .r = 0.2, .g = 0.1, .b = 0.8, .a = 0.12345 };

    const result = color.sRGB.toOklabAlpha(rgba);

    const float_tolerance = 0.00001;
    try helpers.expectApproxEqAbs(result.l, 0.576150835, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.0686165094, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, -0.193039685, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.12345, float_tolerance);
}

test "Convert Oklab with alpha to linear sRGB with alpha" {
    const lab = color.OklabAlpha{ .l = 0.576150835, .a = 0.0686165094, .b = -0.193039685, .alpha = 0.12345 };

    const result = color.sRGB.fromOkLabAlpha(lab, .none);

    const float_tolerance = 0.00001;
    try helpers.expectApproxEqAbs(result.r, 0.2, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.1, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.8, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.12345, float_tolerance);
}

test "Convert a slice of sRGB RGBA colors to OklabAlpha, in-place" {
    var colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.OklabAlpha{
        .{ .l = 0.627951443, .a = 0.224827796, .b = 0.125791788, .alpha = 1.0 }, // Red
        .{ .l = 0.866444945, .a = -0.233919501, .b = 0.179420292, .alpha = 1.0 }, // Green
        .{ .l = 0.451988429, .a = -0.0324304998, .b = -0.311618537, .alpha = 1.0 }, // Blue
        .{ .l = 0.967985213, .a = -0.0714131594, .b = 0.198483586, .alpha = 1.0 }, // Yellow
        .{ .l = 0.701659441, .a = 0.274561018, .b = -0.169243395, .alpha = 1.0 }, // Magenta
        .{ .l = 0.905397713, .a = -0.149464428, .b = -0.0394904613, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_lab = color.sRGB.sliceToOklabAlphaInPlace(colors[0..]);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_lab[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of sRGB RGBA colors to OklabAlpha, copy" {
    const colors = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const expected_results = [_]color.OklabAlpha{
        .{ .l = 0.627951443, .a = 0.224827796, .b = 0.125791788, .alpha = 1.0 }, // Red
        .{ .l = 0.866444945, .a = -0.233919501, .b = 0.179420292, .alpha = 1.0 }, // Green
        .{ .l = 0.451988429, .a = -0.0324304998, .b = -0.311618537, .alpha = 1.0 }, // Blue
        .{ .l = 0.967985213, .a = -0.0714131594, .b = 0.198483586, .alpha = 1.0 }, // Yellow
        .{ .l = 0.701659441, .a = 0.274561018, .b = -0.169243395, .alpha = 1.0 }, // Magenta
        .{ .l = 0.905397713, .a = -0.149464428, .b = -0.0394904613, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const slice_lab = try color.sRGB.sliceToOklabAlphaCopy(helpers.zigimg_test_allocator, colors[0..]);
    defer helpers.zigimg_test_allocator.free(slice_lab);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_lab[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.l, expected.l, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.alpha, expected.alpha, float_tolerance);
    }
}

test "Convert a slice of Oklab with alph colors to linear sRGB, in-place" {
    var colors = [_]color.OklabAlpha{
        .{ .l = 0.627951443, .a = 0.224827796, .b = 0.125791788, .alpha = 1.0 }, // Red
        .{ .l = 0.866444945, .a = -0.233919501, .b = 0.179420292, .alpha = 1.0 }, // Green
        .{ .l = 0.451988429, .a = -0.0324304998, .b = -0.311618537, .alpha = 1.0 }, // Blue
        .{ .l = 0.967985213, .a = -0.0714131594, .b = 0.198483586, .alpha = 1.0 }, // Yellow
        .{ .l = 0.701659441, .a = 0.274561018, .b = -0.169243395, .alpha = 1.0 }, // Magenta
        .{ .l = 0.905397713, .a = -0.149464428, .b = -0.0394904613, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = color.sRGB.sliceFromOkLabAlphaInPlace(colors[0..], .none);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert a slice of Oklab with alph colors to linear sRGB, copy" {
    const colors = [_]color.OklabAlpha{
        .{ .l = 0.627951443, .a = 0.224827796, .b = 0.125791788, .alpha = 1.0 }, // Red
        .{ .l = 0.866444945, .a = -0.233919501, .b = 0.179420292, .alpha = 1.0 }, // Green
        .{ .l = 0.451988429, .a = -0.0324304998, .b = -0.311618537, .alpha = 1.0 }, // Blue
        .{ .l = 0.967985213, .a = -0.0714131594, .b = 0.198483586, .alpha = 1.0 }, // Yellow
        .{ .l = 0.701659441, .a = 0.274561018, .b = -0.169243395, .alpha = 1.0 }, // Magenta
        .{ .l = 0.905397713, .a = -0.149464428, .b = -0.0394904613, .alpha = 1.0 }, // Cyan
        .{ .l = 1.000000, .a = 0.0, .b = -0.0, .alpha = 1.0 }, // White
        .{ .l = 0.000000, .a = 0.0, .b = 0.0, .alpha = 1.0 }, // Black
    };

    const expected_results = [_]color.Colorf32{
        .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
        .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
        .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
        .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Yellow
        .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Magenta
        .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // Cyan
        .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
        .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Black
    };

    const slice_rgba = try color.sRGB.sliceFromOkLabAlphaCopy(helpers.zigimg_test_allocator, colors[0..], .none);
    defer helpers.zigimg_test_allocator.free(slice_rgba);

    const float_tolerance = 0.001;
    for (0..expected_results.len) |index| {
        const actual = slice_rgba[index];
        const expected = expected_results[index];

        try helpers.expectApproxEqAbs(actual.r, expected.r, float_tolerance);
        try helpers.expectApproxEqAbs(actual.g, expected.g, float_tolerance);
        try helpers.expectApproxEqAbs(actual.b, expected.b, float_tolerance);
        try helpers.expectApproxEqAbs(actual.a, expected.a, float_tolerance);
    }
}

test "Convert OkLCh to gamma sRGB" {
    const lch = color.OkLCh{ .l = 0.56, .c = 0.20, .h = 4.502949 };

    const linear = color.sRGB.fromOkLCh(lch, .none);

    const result = color.sRGB.toGamma(linear);

    const float_tolerance = 0.01;
    try helpers.expectApproxEqAbs(result.r, 0.0549, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.43137, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.90196, float_tolerance);
}

test "Convert gamma sRGB to OKLCh" {
    const srgb = color.Colorf32{ .r = 0.29412, .g = 0.64706, .b = 0.5098, .a = 1.0 };

    const linear = color.sRGB.toLinear(srgb);

    const result = color.sRGB.toOkLCh(linear);

    const float_tolerance = 0.01;
    try helpers.expectApproxEqAbs(result.l, 0.6573, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 0.1027, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 2.88276, float_tolerance);
}

test "Convert OkLCh with alpha to gamma sRGB with alpha" {
    const lch = color.OkLChAlpha{ .l = 0.56, .c = 0.20, .h = 4.502949, .alpha = 0.12345 };

    const linear = color.sRGB.fromOkLChAlpha(lch, .none);

    const result = color.sRGB.toGamma(linear);

    const float_tolerance = 0.01;
    try helpers.expectApproxEqAbs(result.r, 0.0549, float_tolerance);
    try helpers.expectApproxEqAbs(result.g, 0.43137, float_tolerance);
    try helpers.expectApproxEqAbs(result.b, 0.90196, float_tolerance);
    try helpers.expectApproxEqAbs(result.a, 0.12345, float_tolerance);
}

test "Convert gamma sRGB with alpha to OKLCh with alpha" {
    const srgb = color.Colorf32{ .r = 0.29412, .g = 0.64706, .b = 0.5098, .a = 0.12345 };

    const linear = color.sRGB.toLinear(srgb);

    const result = color.sRGB.toOkLChAlpha(linear);

    const float_tolerance = 0.01;
    try helpers.expectApproxEqAbs(result.l, 0.6573, float_tolerance);
    try helpers.expectApproxEqAbs(result.c, 0.1027, float_tolerance);
    try helpers.expectApproxEqAbs(result.h, 2.88276, float_tolerance);
    try helpers.expectApproxEqAbs(result.alpha, 0.12345, float_tolerance);
}
