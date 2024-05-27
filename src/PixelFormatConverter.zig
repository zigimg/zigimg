const color = @import("color.zig");
const std = @import("std");

const PixelFormat = @import("pixel_format.zig").PixelFormat;

pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination_format: PixelFormat) !color.PixelStorage {
    const pixel_count = source.len();

    var destination = try color.PixelStorage.init(allocator, destination_format, pixel_count);
    errdefer destination.deinit(allocator);

    const conversion_id = conversionId(std.meta.activeTag(source.*), destination_format);

    switch (conversion_id) {
        // Indexed small -> large
        conversionId(.indexed1, .indexed2) => IndexedSmallToLarge(.indexed1, .indexed2).convert(source, &destination),
        conversionId(.indexed1, .indexed4) => IndexedSmallToLarge(.indexed1, .indexed4).convert(source, &destination),
        conversionId(.indexed1, .indexed8) => IndexedSmallToLarge(.indexed1, .indexed8).convert(source, &destination),
        conversionId(.indexed1, .indexed16) => IndexedSmallToLarge(.indexed1, .indexed16).convert(source, &destination),

        conversionId(.indexed2, .indexed4) => IndexedSmallToLarge(.indexed2, .indexed4).convert(source, &destination),
        conversionId(.indexed2, .indexed8) => IndexedSmallToLarge(.indexed2, .indexed8).convert(source, &destination),
        conversionId(.indexed2, .indexed16) => IndexedSmallToLarge(.indexed2, .indexed16).convert(source, &destination),

        conversionId(.indexed4, .indexed8) => IndexedSmallToLarge(.indexed4, .indexed8).convert(source, &destination),
        conversionId(.indexed4, .indexed16) => IndexedSmallToLarge(.indexed4, .indexed16).convert(source, &destination),

        conversionId(.indexed8, .indexed16) => IndexedSmallToLarge(.indexed8, .indexed16).convert(source, &destination),

        // Indexed -> RGB555
        conversionId(.indexed1, .rgb555) => IndexedToRgbColor(.indexed1, .rgb555).convert(source, &destination),
        conversionId(.indexed2, .rgb555) => IndexedToRgbColor(.indexed2, .rgb555).convert(source, &destination),
        conversionId(.indexed4, .rgb555) => IndexedToRgbColor(.indexed4, .rgb555).convert(source, &destination),
        conversionId(.indexed8, .rgb555) => IndexedToRgbColor(.indexed8, .rgb555).convert(source, &destination),
        conversionId(.indexed16, .rgb555) => IndexedToRgbColor(.indexed16, .rgb555).convert(source, &destination),

        // Indexed -> RGB565
        conversionId(.indexed1, .rgb565) => IndexedToRgbColor(.indexed1, .rgb565).convert(source, &destination),
        conversionId(.indexed2, .rgb565) => IndexedToRgbColor(.indexed2, .rgb565).convert(source, &destination),
        conversionId(.indexed4, .rgb565) => IndexedToRgbColor(.indexed4, .rgb565).convert(source, &destination),
        conversionId(.indexed8, .rgb565) => IndexedToRgbColor(.indexed8, .rgb565).convert(source, &destination),
        conversionId(.indexed16, .rgb565) => IndexedToRgbColor(.indexed16, .rgb565).convert(source, &destination),

        // Indexed -> RGB24
        conversionId(.indexed1, .rgb24) => IndexedToRgbColor(.indexed1, .rgb24).convert(source, &destination),
        conversionId(.indexed2, .rgb24) => IndexedToRgbColor(.indexed2, .rgb24).convert(source, &destination),
        conversionId(.indexed4, .rgb24) => IndexedToRgbColor(.indexed4, .rgb24).convert(source, &destination),
        conversionId(.indexed8, .rgb24) => IndexedToRgbColor(.indexed8, .rgb24).convert(source, &destination),
        conversionId(.indexed16, .rgb24) => IndexedToRgbColor(.indexed16, .rgb24).convert(source, &destination),

        // Indexed -> RGBA32
        conversionId(.indexed1, .rgba32) => indexedToRgba32(.indexed1, source, &destination),
        conversionId(.indexed2, .rgba32) => indexedToRgba32(.indexed2, source, &destination),
        conversionId(.indexed4, .rgba32) => indexedToRgba32(.indexed4, source, &destination),
        conversionId(.indexed8, .rgba32) => indexedToRgba32(.indexed8, source, &destination),
        conversionId(.indexed16, .rgba32) => indexedToRgba32(.indexed16, source, &destination),

        // Indexed -> BGR555
        conversionId(.indexed1, .bgr555) => IndexedToRgbColor(.indexed1, .bgr555).convert(source, &destination),
        conversionId(.indexed2, .bgr555) => IndexedToRgbColor(.indexed2, .bgr555).convert(source, &destination),
        conversionId(.indexed4, .bgr555) => IndexedToRgbColor(.indexed4, .bgr555).convert(source, &destination),
        conversionId(.indexed8, .bgr555) => IndexedToRgbColor(.indexed8, .bgr555).convert(source, &destination),
        conversionId(.indexed16, .bgr555) => IndexedToRgbColor(.indexed16, .bgr555).convert(source, &destination),

        // Indexed -> BGR24
        conversionId(.indexed1, .bgr24) => IndexedToRgbColor(.indexed1, .bgr24).convert(source, &destination),
        conversionId(.indexed2, .bgr24) => IndexedToRgbColor(.indexed2, .bgr24).convert(source, &destination),
        conversionId(.indexed4, .bgr24) => IndexedToRgbColor(.indexed4, .bgr24).convert(source, &destination),
        conversionId(.indexed8, .bgr24) => IndexedToRgbColor(.indexed8, .bgr24).convert(source, &destination),
        conversionId(.indexed16, .bgr24) => IndexedToRgbColor(.indexed16, .bgr24).convert(source, &destination),

        // Indexed -> BGRA32
        conversionId(.indexed1, .bgra32) => IndexedToRgbaColor(.indexed1, .bgra32).convert(source, &destination),
        conversionId(.indexed2, .bgra32) => IndexedToRgbaColor(.indexed2, .bgra32).convert(source, &destination),
        conversionId(.indexed4, .bgra32) => IndexedToRgbaColor(.indexed4, .bgra32).convert(source, &destination),
        conversionId(.indexed8, .bgra32) => IndexedToRgbaColor(.indexed8, .bgra32).convert(source, &destination),
        conversionId(.indexed16, .bgra32) => IndexedToRgbaColor(.indexed16, .bgra32).convert(source, &destination),

        // Indexed -> RGB48
        conversionId(.indexed1, .rgb48) => IndexedToRgbColor(.indexed1, .rgb48).convert(source, &destination),
        conversionId(.indexed2, .rgb48) => IndexedToRgbColor(.indexed2, .rgb48).convert(source, &destination),
        conversionId(.indexed4, .rgb48) => IndexedToRgbColor(.indexed4, .rgb48).convert(source, &destination),
        conversionId(.indexed8, .rgb48) => IndexedToRgbColor(.indexed8, .rgb48).convert(source, &destination),
        conversionId(.indexed16, .rgb48) => IndexedToRgbColor(.indexed16, .rgb48).convert(source, &destination),

        // Indexed -> RGBA64
        conversionId(.indexed1, .rgba64) => IndexedToRgbaColor(.indexed1, .rgba64).convert(source, &destination),
        conversionId(.indexed2, .rgba64) => IndexedToRgbaColor(.indexed2, .rgba64).convert(source, &destination),
        conversionId(.indexed4, .rgba64) => IndexedToRgbaColor(.indexed4, .rgba64).convert(source, &destination),
        conversionId(.indexed8, .rgba64) => IndexedToRgbaColor(.indexed8, .rgba64).convert(source, &destination),
        conversionId(.indexed16, .rgba64) => IndexedToRgbaColor(.indexed16, .rgba64).convert(source, &destination),

        // Indexed -> Colorf32
        conversionId(.indexed1, .float32) => indexedToColorf32(.indexed1, source, &destination),
        conversionId(.indexed2, .float32) => indexedToColorf32(.indexed2, source, &destination),
        conversionId(.indexed4, .float32) => indexedToColorf32(.indexed4, source, &destination),
        conversionId(.indexed8, .float32) => indexedToColorf32(.indexed8, source, &destination),
        conversionId(.indexed16, .float32) => indexedToColorf32(.indexed16, source, &destination),

        // Grayscale -> RGB555
        conversionId(.grayscale1, .rgb555) => GreyscaleToRgbColor(.grayscale1, .rgb555).convert(source, &destination),
        conversionId(.grayscale2, .rgb555) => GreyscaleToRgbColor(.grayscale2, .rgb555).convert(source, &destination),
        conversionId(.grayscale4, .rgb555) => GreyscaleToRgbColor(.grayscale4, .rgb555).convert(source, &destination),
        conversionId(.grayscale8, .rgb555) => GreyscaleToRgbColor(.grayscale8, .rgb555).convert(source, &destination),
        conversionId(.grayscale16, .rgb555) => GreyscaleToRgbColor(.grayscale16, .rgb555).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb555) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .rgb555).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb555) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .rgb555).convert(source, &destination),

        // Grayscale -> RGB565
        conversionId(.grayscale1, .rgb565) => GreyscaleToRgbColor(.grayscale1, .rgb565).convert(source, &destination),
        conversionId(.grayscale2, .rgb565) => GreyscaleToRgbColor(.grayscale2, .rgb565).convert(source, &destination),
        conversionId(.grayscale4, .rgb565) => GreyscaleToRgbColor(.grayscale4, .rgb565).convert(source, &destination),
        conversionId(.grayscale8, .rgb565) => GreyscaleToRgbColor(.grayscale8, .rgb565).convert(source, &destination),
        conversionId(.grayscale16, .rgb565) => GreyscaleToRgbColor(.grayscale16, .rgb565).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb565) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .rgb565).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb565) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .rgb565).convert(source, &destination),

        // Grayscale -> RGB24
        conversionId(.grayscale1, .rgb24) => GreyscaleToRgbColor(.grayscale1, .rgb24).convert(source, &destination),
        conversionId(.grayscale2, .rgb24) => GreyscaleToRgbColor(.grayscale2, .rgb24).convert(source, &destination),
        conversionId(.grayscale4, .rgb24) => GreyscaleToRgbColor(.grayscale4, .rgb24).convert(source, &destination),
        conversionId(.grayscale8, .rgb24) => GreyscaleToRgbColor(.grayscale8, .rgb24).convert(source, &destination),
        conversionId(.grayscale16, .rgb24) => GreyscaleToRgbColor(.grayscale16, .rgb24).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb24) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .rgb24).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb24) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .rgb24).convert(source, &destination),

        // Grayscale -> RGBA32
        conversionId(.grayscale1, .rgba32) => GreyscaleToRgbaColor(.grayscale1, .rgba32).convert(source, &destination),
        conversionId(.grayscale2, .rgba32) => GreyscaleToRgbaColor(.grayscale2, .rgba32).convert(source, &destination),
        conversionId(.grayscale4, .rgba32) => GreyscaleToRgbaColor(.grayscale4, .rgba32).convert(source, &destination),
        conversionId(.grayscale8, .rgba32) => GreyscaleToRgbaColor(.grayscale8, .rgba32).convert(source, &destination),
        conversionId(.grayscale16, .rgba32) => GreyscaleToRgbaColor(.grayscale16, .rgba32).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgba32) => GreyscaleAlphaToRgbaColor(.grayscale8Alpha, .rgba32).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgba32) => GreyscaleAlphaToRgbaColor(.grayscale16Alpha, .rgba32).convert(source, &destination),

        // Grayscale -> BGR555
        conversionId(.grayscale1, .bgr555) => GreyscaleToRgbColor(.grayscale1, .bgr555).convert(source, &destination),
        conversionId(.grayscale2, .bgr555) => GreyscaleToRgbColor(.grayscale2, .bgr555).convert(source, &destination),
        conversionId(.grayscale4, .bgr555) => GreyscaleToRgbColor(.grayscale4, .bgr555).convert(source, &destination),
        conversionId(.grayscale8, .bgr555) => GreyscaleToRgbColor(.grayscale8, .bgr555).convert(source, &destination),
        conversionId(.grayscale16, .bgr555) => GreyscaleToRgbColor(.grayscale16, .bgr555).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgr555) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .bgr555).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgr555) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .bgr555).convert(source, &destination),

        // Grayscale -> BGR24
        conversionId(.grayscale1, .bgr24) => GreyscaleToRgbColor(.grayscale1, .bgr24).convert(source, &destination),
        conversionId(.grayscale2, .bgr24) => GreyscaleToRgbColor(.grayscale2, .bgr24).convert(source, &destination),
        conversionId(.grayscale4, .bgr24) => GreyscaleToRgbColor(.grayscale4, .bgr24).convert(source, &destination),
        conversionId(.grayscale8, .bgr24) => GreyscaleToRgbColor(.grayscale8, .bgr24).convert(source, &destination),
        conversionId(.grayscale16, .bgr24) => GreyscaleToRgbColor(.grayscale16, .bgr24).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgr24) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .bgr24).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgr24) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .bgr24).convert(source, &destination),

        // Grayscale -> BGRA32
        conversionId(.grayscale1, .bgra32) => GreyscaleToRgbaColor(.grayscale1, .bgra32).convert(source, &destination),
        conversionId(.grayscale2, .bgra32) => GreyscaleToRgbaColor(.grayscale2, .bgra32).convert(source, &destination),
        conversionId(.grayscale4, .bgra32) => GreyscaleToRgbaColor(.grayscale4, .bgra32).convert(source, &destination),
        conversionId(.grayscale8, .bgra32) => GreyscaleToRgbaColor(.grayscale8, .bgra32).convert(source, &destination),
        conversionId(.grayscale16, .bgra32) => GreyscaleToRgbaColor(.grayscale16, .bgra32).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgra32) => GreyscaleAlphaToRgbaColor(.grayscale8Alpha, .bgra32).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgra32) => GreyscaleAlphaToRgbaColor(.grayscale16Alpha, .bgra32).convert(source, &destination),

        // Grayscale -> RGB48
        conversionId(.grayscale1, .rgb48) => GreyscaleToRgbColor(.grayscale1, .rgb48).convert(source, &destination),
        conversionId(.grayscale2, .rgb48) => GreyscaleToRgbColor(.grayscale2, .rgb48).convert(source, &destination),
        conversionId(.grayscale4, .rgb48) => GreyscaleToRgbColor(.grayscale4, .rgb48).convert(source, &destination),
        conversionId(.grayscale8, .rgb48) => GreyscaleToRgbColor(.grayscale8, .rgb48).convert(source, &destination),
        conversionId(.grayscale16, .rgb48) => GreyscaleToRgbColor(.grayscale16, .rgb48).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb48) => GreyscaleAlphaToRgbColor(.grayscale8Alpha, .rgb48).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb48) => GreyscaleAlphaToRgbColor(.grayscale16Alpha, .rgb48).convert(source, &destination),

        // Grayscale -> RGBA64
        conversionId(.grayscale1, .rgba64) => GreyscaleToRgbaColor(.grayscale1, .rgba64).convert(source, &destination),
        conversionId(.grayscale2, .rgba64) => GreyscaleToRgbaColor(.grayscale2, .rgba64).convert(source, &destination),
        conversionId(.grayscale4, .rgba64) => GreyscaleToRgbaColor(.grayscale4, .rgba64).convert(source, &destination),
        conversionId(.grayscale8, .rgba64) => GreyscaleToRgbaColor(.grayscale8, .rgba64).convert(source, &destination),
        conversionId(.grayscale16, .rgba64) => GreyscaleToRgbaColor(.grayscale16, .rgba64).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgba64) => GreyscaleAlphaToRgbaColor(.grayscale8Alpha, .rgba64).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgba64) => GreyscaleAlphaToRgbaColor(.grayscale16Alpha, .rgba64).convert(source, &destination),

        // Grayscale -> Colorf32
        conversionId(.grayscale1, .float32) => grayscaleToColorf32(.grayscale1, source, &destination),
        conversionId(.grayscale2, .float32) => grayscaleToColorf32(.grayscale2, source, &destination),
        conversionId(.grayscale4, .float32) => grayscaleToColorf32(.grayscale4, source, &destination),
        conversionId(.grayscale8, .float32) => grayscaleToColorf32(.grayscale8, source, &destination),
        conversionId(.grayscale16, .float32) => grayscaleToColorf32(.grayscale16, source, &destination),
        conversionId(.grayscale8Alpha, .float32) => grayscaleToColorf32(.grayscale8Alpha, source, &destination),
        conversionId(.grayscale16Alpha, .float32) => grayscaleToColorf32(.grayscale16Alpha, source, &destination),

        else => return error.NoConversionAvailable,
    }

    return destination;
}

fn conversionId(source_format: PixelFormat, destination_format: PixelFormat) u64 {
    return @as(u64, @intFromEnum(source_format)) | @as(u64, @intFromEnum(destination_format)) << 32;
}

fn getFieldNameFromPixelFormat(comptime source_format: PixelFormat) []const u8 {
    const enum_fields = std.meta.fields(PixelFormat);
    inline for (enum_fields) |field| {
        if (field.value == @intFromEnum(source_format)) {
            return field.name;
        }
    }

    return "";
}

fn IndexedSmallToLarge(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_indexed = @field(destination, getFieldNameFromPixelFormat(destination_format));

            for (0..source_indexed.palette.len) |index| {
                destination_indexed.palette[index] = source_indexed.palette[index];
            }

            for (0..source_indexed.indices.len) |index| {
                destination_indexed.indices[index] = source_indexed.indices[index];
            }
        }
    };
}

fn rgbToRgb(comptime T: type, rgb: anytype) T {
    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, rgb.r),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, rgb.g),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, rgb.b),
    };
}

fn rgbToRgba(comptime T: type, rgb: anytype) T {
    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, rgb.r),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, rgb.g),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, rgb.b),
        .a = 255,
    };
}

fn rgbaToRgb(comptime T: type, rgba: anytype) T {
    const alpha = color.toF32Color(rgba.a);

    return T{
        .r = color.toIntColor(std.meta.fieldInfo(T, .r).type, color.toF32Color(rgba.r) * alpha),
        .g = color.toIntColor(std.meta.fieldInfo(T, .g).type, color.toF32Color(rgba.g) * alpha),
        .b = color.toIntColor(std.meta.fieldInfo(T, .b).type, color.toF32Color(rgba.b) * alpha),
    };
}

fn rgbaToRgba(comptime T: type, rgba: anytype) T {
    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, rgba.r),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, rgba.g),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, rgba.b),
        .a = color.scaleToIntColor(std.meta.fieldInfo(T, .a).type, rgba.a),
    };
}

fn grayscaleToRgb(comptime T: type, grey: anytype) T {
    const grey_value = grey.value;

    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, grey_value),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, grey_value),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, grey_value),
    };
}

fn grayscaleToRgba(comptime T: type, grey: anytype) T {
    const grey_value = grey.value;

    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, grey_value),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, grey_value),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, grey_value),
        .a = 255,
    };
}

fn grayscaleAlphaToRgb(comptime T: type, grey: anytype) T {
    const alpha = color.toF32Color(grey.alpha);
    const grey_f32 = color.toF32Color(grey.value);

    return T{
        .r = color.toIntColor(std.meta.fieldInfo(T, .r).type, grey_f32 * alpha),
        .g = color.toIntColor(std.meta.fieldInfo(T, .g).type, grey_f32 * alpha),
        .b = color.toIntColor(std.meta.fieldInfo(T, .b).type, grey_f32 * alpha),
    };
}

fn grayscaleAlphaToRgba(comptime T: type, grey: anytype) T {
    const grey_value = grey.value;

    return T{
        .r = color.scaleToIntColor(std.meta.fieldInfo(T, .r).type, grey_value),
        .g = color.scaleToIntColor(std.meta.fieldInfo(T, .g).type, grey_value),
        .b = color.scaleToIntColor(std.meta.fieldInfo(T, .b).type, grey_value),
        .a = color.scaleToIntColor(std.meta.fieldInfo(T, .a).type, grey.alpha),
    };
}

fn IndexedToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_indexed.indices.len) |index| {
                destination_pixels[index] = rgbaToRgb(destination_type, source_indexed.palette[source_indexed.indices[index]]);
            }
        }
    };
}

fn IndexedToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_indexed.indices.len) |index| {
                destination_pixels[index] = rgbaToRgba(destination_type, source_indexed.palette[source_indexed.indices[index]]);
            }
        }
    };
}

fn indexedToRgba32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));

    for (0..source_indexed.indices.len) |index| {
        destination.rgba32[index] = source_indexed.palette[source_indexed.indices[index]];
    }
}

fn indexedToColorf32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));

    for (0..source_indexed.indices.len) |index| {
        destination.float32[index] = source_indexed.palette[source_indexed.indices[index]].toColorf32();
    }
}

fn GreyscaleToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleToRgb(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn GreyscaleToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleToRgba(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn GreyscaleAlphaToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToRgb(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn GreyscaleAlphaToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToRgba(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn grayscaleToColorf32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));

    for (0..source_grayscale.len) |index| {
        destination.float32[index] = source_grayscale[index].toColorf32();
    }
}
