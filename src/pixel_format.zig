pub const PixelFormatVariant = enum(u4) {
    none = 0,
    bgr = 1,
    float = 2,
    rgb565 = 3,
    _,
};

pub const PixelFormatInfo = packed struct {
    bits_per_channel: u8 = 0,
    channel_count: u4 = 0,
    variant: PixelFormatVariant = .none,
    padding: u16 = 0,
};

pub inline fn toPixelFormatInfo(pixel_format: PixelFormat) PixelFormatInfo {
    return @as(PixelFormatInfo, @bitCast(@intFromEnum(pixel_format)));
}

pub inline fn toPixelFormatValue(comptime pixel_format: PixelFormatInfo) u32 {
    return @bitCast(pixel_format);
}

/// The values for this enum are chosen so that:
/// 1. value & 0xFF gives number of bits per channel
/// 2. value & 0xF00 gives number of channels
/// 3. value & 0xF000 gives a special variant number, 1 for Bgr, 2 for Float and 3 for special Rgb 565
/// Note that palette index formats have number of channels set to 0.
pub const PixelFormat = enum(u32) {
    invalid = 0,
    indexed1 = toPixelFormatValue(.{ .bits_per_channel = 1 }),
    indexed2 = toPixelFormatValue(.{ .bits_per_channel = 2 }),
    indexed4 = toPixelFormatValue(.{ .bits_per_channel = 4 }),
    indexed8 = toPixelFormatValue(.{ .bits_per_channel = 8 }),
    indexed16 = toPixelFormatValue(.{ .bits_per_channel = 16 }),
    grayscale1 = toPixelFormatValue(.{ .channel_count = 1, .bits_per_channel = 1 }),
    grayscale2 = toPixelFormatValue(.{ .channel_count = 1, .bits_per_channel = 2 }),
    grayscale4 = toPixelFormatValue(.{ .channel_count = 1, .bits_per_channel = 4 }),
    grayscale8 = toPixelFormatValue(.{ .channel_count = 1, .bits_per_channel = 8 }),
    grayscale16 = toPixelFormatValue(.{ .channel_count = 1, .bits_per_channel = 16 }),
    grayscale8Alpha = toPixelFormatValue(.{ .channel_count = 2, .bits_per_channel = 8 }),
    grayscale16Alpha = toPixelFormatValue(.{ .channel_count = 2, .bits_per_channel = 16 }),
    rgb555 = toPixelFormatValue(.{ .channel_count = 3, .bits_per_channel = 5 }),
    rgb565 = toPixelFormatValue(.{ .variant = .rgb565, .channel_count = 3, .bits_per_channel = 5 }),
    rgb24 = toPixelFormatValue(.{ .channel_count = 3, .bits_per_channel = 8 }),
    rgba32 = toPixelFormatValue(.{ .channel_count = 4, .bits_per_channel = 8 }),
    bgr555 = toPixelFormatValue(.{ .variant = .bgr, .channel_count = 3, .bits_per_channel = 5 }),
    bgr24 = toPixelFormatValue(.{ .variant = .bgr, .channel_count = 3, .bits_per_channel = 8 }),
    bgra32 = toPixelFormatValue(.{ .variant = .bgr, .channel_count = 4, .bits_per_channel = 8 }),
    rgb48 = toPixelFormatValue(.{ .channel_count = 3, .bits_per_channel = 16 }),
    rgba64 = toPixelFormatValue(.{ .channel_count = 4, .bits_per_channel = 16 }),
    float32 = toPixelFormatValue(.{ .variant = .float, .channel_count = 4, .bits_per_channel = 32 }),

    pub fn isJustGrayscale(self: PixelFormat) bool {
        return toPixelFormatInfo(self).channel_count == 1;
    }

    pub fn isIndex(self: PixelFormat) bool {
        return toPixelFormatInfo(self).channel_count == 0;
    }

    pub fn isStandardRgb(self: PixelFormat) bool {
        return self == .rgb24 or self == .rgb48;
    }

    pub fn isRgba(self: PixelFormat) bool {
        return self == .rgba32 or self == .rgba64;
    }

    pub fn is16Bit(self: PixelFormat) bool {
        return toPixelFormatInfo(self).bits_per_channel == 16;
    }

    pub fn pixelStride(self: PixelFormat) u8 {
        // Using bit manipulations of values is not really faster than this switch
        return switch (self) {
            .invalid => 0,
            .indexed1, .indexed2, .indexed4, .indexed8, .grayscale1, .grayscale2, .grayscale4, .grayscale8 => 1,
            .indexed16, .grayscale16, .grayscale8Alpha, .rgb565, .rgb555, .bgr555 => 2,
            .rgb24, .bgr24 => 3,
            .grayscale16Alpha, .rgba32, .bgra32 => 4,
            .rgb48 => 6,
            .rgba64 => 8,
            .float32 => 16,
        };
    }

    pub fn bitsPerChannel(self: PixelFormat) u8 {
        return switch (self) {
            .invalid => 0,
            .rgb565 => unreachable, // TODO: what to do in that case?
            .indexed1, .grayscale1 => 1,
            .indexed2, .grayscale2 => 2,
            .indexed4, .grayscale4 => 4,
            .rgb555, .bgr555 => 5,
            .indexed8, .grayscale8, .grayscale8Alpha, .rgb24, .rgba32, .bgr24, .bgra32 => 8,
            .indexed16, .grayscale16, .grayscale16Alpha, .rgb48, .rgba64 => 16,
            .float32 => 32,
        };
    }

    pub fn channelCount(self: PixelFormat) u8 {
        return switch (self) {
            .invalid => 0,
            .grayscale8Alpha, .grayscale16Alpha => 2,
            .rgb565, .rgb555, .bgr555, .rgb24, .bgr24, .rgb48 => 3,
            .rgba32, .bgra32, .rgba64, .float32 => 4,
            else => 1,
        };
    }
};

comptime {
    const std = @import("std");

    std.debug.assert(@intFromEnum(PixelFormat.grayscale1) == 0x101);
    std.debug.assert(@intFromEnum(PixelFormat.grayscale16) == 0x110);
    std.debug.assert(@intFromEnum(PixelFormat.grayscale8Alpha) == 0x208);
    std.debug.assert(@intFromEnum(PixelFormat.rgb555) == 0x305);
    std.debug.assert(@intFromEnum(PixelFormat.rgb565) == 0x3305);
    std.debug.assert(@intFromEnum(PixelFormat.rgba32) == 0x408);
    std.debug.assert(@intFromEnum(PixelFormat.bgr24) == 0x1308);
    std.debug.assert(@intFromEnum(PixelFormat.bgra32) == 0x1408);
    std.debug.assert(@intFromEnum(PixelFormat.float32) == 0x2420);
}
