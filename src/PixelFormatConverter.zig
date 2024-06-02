const color = @import("color.zig");
const simd = @import("simd.zig");
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

        // Grayscale small -> large
        conversionId(.grayscale1, .grayscale2) => GreyscaleToGrayscale(.grayscale1, .grayscale2).convert(source, &destination),
        conversionId(.grayscale1, .grayscale4) => GreyscaleToGrayscale(.grayscale1, .grayscale4).convert(source, &destination),
        conversionId(.grayscale1, .grayscale8) => GreyscaleToGrayscale(.grayscale1, .grayscale8).convert(source, &destination),
        conversionId(.grayscale1, .grayscale16) => GreyscaleToGrayscale(.grayscale1, .grayscale16).convert(source, &destination),
        conversionId(.grayscale1, .grayscale8Alpha) => GreyscaleToGrayscale(.grayscale1, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale1, .grayscale16Alpha) => GreyscaleToGrayscale(.grayscale1, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale2, .grayscale4) => GreyscaleToGrayscale(.grayscale2, .grayscale4).convert(source, &destination),
        conversionId(.grayscale2, .grayscale8) => GreyscaleToGrayscale(.grayscale2, .grayscale8).convert(source, &destination),
        conversionId(.grayscale2, .grayscale16) => GreyscaleToGrayscale(.grayscale2, .grayscale16).convert(source, &destination),
        conversionId(.grayscale2, .grayscale8Alpha) => GreyscaleToGrayscale(.grayscale2, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale2, .grayscale16Alpha) => GreyscaleToGrayscale(.grayscale2, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale4, .grayscale8) => GreyscaleToGrayscale(.grayscale4, .grayscale8).convert(source, &destination),
        conversionId(.grayscale4, .grayscale16) => GreyscaleToGrayscale(.grayscale4, .grayscale16).convert(source, &destination),
        conversionId(.grayscale4, .grayscale8Alpha) => GreyscaleToGrayscale(.grayscale4, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale4, .grayscale16Alpha) => GreyscaleToGrayscale(.grayscale4, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale8, .grayscale16) => GreyscaleToGrayscale(.grayscale8, .grayscale16).convert(source, &destination),
        conversionId(.grayscale8, .grayscale8Alpha) => GreyscaleToGrayscale(.grayscale8, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale8, .grayscale16Alpha) => GreyscaleToGrayscale(.grayscale8, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale16, .grayscale16Alpha) => GreyscaleToGrayscale(.grayscale16, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale8Alpha, .grayscale16Alpha) => GreyscaleAlphaToGrayscaleAlpha(.grayscale8Alpha, .grayscale16Alpha).convert(source, &destination),

        // Greyscale large -> small
        conversionId(.grayscale16Alpha, .grayscale8Alpha) => GreyscaleAlphaToGrayscaleAlpha(.grayscale16Alpha, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale16) => GreyscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale16).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale8) => GreyscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale8).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale4) => GreyscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale4).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale2) => GreyscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale2).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale1) => GreyscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale1).convert(source, &destination),

        conversionId(.grayscale8Alpha, .grayscale16) => GreyscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale16).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale8) => GreyscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale8).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale4) => GreyscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale4).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale2) => GreyscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale2).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale1) => GreyscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale1).convert(source, &destination),

        conversionId(.grayscale16, .grayscale8Alpha) => GreyscaleToGrayscale(.grayscale16, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale16, .grayscale8) => GreyscaleToGrayscale(.grayscale16, .grayscale8).convert(source, &destination),
        conversionId(.grayscale16, .grayscale4) => GreyscaleToGrayscale(.grayscale16, .grayscale4).convert(source, &destination),
        conversionId(.grayscale16, .grayscale2) => GreyscaleToGrayscale(.grayscale16, .grayscale2).convert(source, &destination),
        conversionId(.grayscale16, .grayscale1) => GreyscaleToGrayscale(.grayscale16, .grayscale1).convert(source, &destination),

        conversionId(.grayscale8, .grayscale4) => GreyscaleToGrayscale(.grayscale8, .grayscale4).convert(source, &destination),
        conversionId(.grayscale8, .grayscale2) => GreyscaleToGrayscale(.grayscale8, .grayscale2).convert(source, &destination),
        conversionId(.grayscale8, .grayscale1) => GreyscaleToGrayscale(.grayscale8, .grayscale1).convert(source, &destination),

        conversionId(.grayscale4, .grayscale2) => GreyscaleToGrayscale(.grayscale4, .grayscale2).convert(source, &destination),
        conversionId(.grayscale4, .grayscale1) => GreyscaleToGrayscale(.grayscale4, .grayscale1).convert(source, &destination),

        conversionId(.grayscale2, .grayscale1) => GreyscaleToGrayscale(.grayscale2, .grayscale1).convert(source, &destination),

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

        // rgb555 -> RGB + Colorf32
        conversionId(.rgb555, .rgb565) => RgbColorToRgbColor(.rgb555, .rgb565).convert(source, &destination),
        conversionId(.rgb555, .rgb24) => RgbColorToRgbColor(.rgb555, .rgb24).convert(source, &destination),
        conversionId(.rgb555, .rgba32) => RgbColorToRgbaColor(.rgb555, .rgba32).convert(source, &destination),
        conversionId(.rgb555, .bgr555) => RgbColorToRgbColor(.rgb555, .bgr555).convert(source, &destination),
        conversionId(.rgb555, .bgr24) => RgbColorToRgbColor(.rgb555, .bgr24).convert(source, &destination),
        conversionId(.rgb555, .bgra32) => RgbColorToRgbaColor(.rgb555, .bgra32).convert(source, &destination),
        conversionId(.rgb555, .rgb48) => RgbColorToRgbColor(.rgb555, .rgb48).convert(source, &destination),
        conversionId(.rgb555, .rgba64) => RgbColorToRgbaColor(.rgb555, .rgba64).convert(source, &destination),
        conversionId(.rgb555, .float32) => rgbColorToColorf32(.rgb555, source, &destination),

        // rgb565 -> RGB + Colorf32
        conversionId(.rgb565, .rgb555) => RgbColorToRgbColor(.rgb565, .rgb555).convert(source, &destination),
        conversionId(.rgb565, .rgb24) => RgbColorToRgbColor(.rgb565, .rgb24).convert(source, &destination),
        conversionId(.rgb565, .rgba32) => RgbColorToRgbaColor(.rgb565, .rgba32).convert(source, &destination),
        conversionId(.rgb565, .bgr555) => RgbColorToRgbColor(.rgb565, .bgr555).convert(source, &destination),
        conversionId(.rgb565, .bgr24) => RgbColorToRgbColor(.rgb565, .bgr24).convert(source, &destination),
        conversionId(.rgb565, .bgra32) => RgbColorToRgbaColor(.rgb565, .bgra32).convert(source, &destination),
        conversionId(.rgb565, .rgb48) => RgbColorToRgbColor(.rgb565, .rgb48).convert(source, &destination),
        conversionId(.rgb565, .rgba64) => RgbColorToRgbaColor(.rgb565, .rgba64).convert(source, &destination),
        conversionId(.rgb565, .float32) => rgbColorToColorf32(.rgb565, source, &destination),

        // rgb24 -> RGB + Colorf32
        conversionId(.rgb24, .rgb555) => RgbColorToRgbColor(.rgb24, .rgb555).convert(source, &destination),
        conversionId(.rgb24, .rgb565) => RgbColorToRgbColor(.rgb24, .rgb565).convert(source, &destination),
        conversionId(.rgb24, .rgba32) => RgbColorToRgbaColor(.rgb24, .rgba32).convert(source, &destination),
        conversionId(.rgb24, .bgr555) => RgbColorToRgbColor(.rgb24, .bgr555).convert(source, &destination),
        conversionId(.rgb24, .bgr24) => RgbColorToRgbColor(.rgb24, .bgr24).convert(source, &destination),
        conversionId(.rgb24, .bgra32) => RgbColorToRgbaColor(.rgb24, .bgra32).convert(source, &destination),
        conversionId(.rgb24, .rgb48) => RgbColorToRgbColor(.rgb24, .rgb48).convert(source, &destination),
        conversionId(.rgb24, .rgba64) => RgbColorToRgbaColor(.rgb24, .rgba64).convert(source, &destination),
        conversionId(.rgb24, .float32) => rgbColorToColorf32(.rgb24, source, &destination),

        // rgba32 -> RGB + Colorf32
        conversionId(.rgba32, .rgb555) => RgbaColorToRgbColor(.rgba32, .rgb555).convert(source, &destination),
        conversionId(.rgba32, .rgb565) => RgbaColorToRgbColor(.rgba32, .rgb565).convert(source, &destination),
        conversionId(.rgba32, .rgb24) => RgbaColorToRgbColor(.rgba32, .rgb24).convert(source, &destination),
        conversionId(.rgba32, .bgr555) => RgbaColorToRgbColor(.rgba32, .bgr555).convert(source, &destination),
        conversionId(.rgba32, .bgr24) => RgbaColorToRgbColor(.rgba32, .bgr24).convert(source, &destination),
        conversionId(.rgba32, .bgra32) => FastRgba32Shuffle(.rgba32, .bgra32).convert(source, &destination),
        conversionId(.rgba32, .rgb48) => RgbaColorToRgbColor(.rgba32, .rgb48).convert(source, &destination),
        conversionId(.rgba32, .rgba64) => RgbaColorToRgbaColor(.rgba32, .rgba64).convert(source, &destination),
        conversionId(.rgba32, .float32) => rgba32ToColorf32(.rgba32, source, &destination),

        // bgra32 -> RGB + Colorf32
        conversionId(.bgra32, .rgb555) => RgbaColorToRgbColor(.bgra32, .rgb555).convert(source, &destination),
        conversionId(.bgra32, .rgb565) => RgbaColorToRgbColor(.bgra32, .rgb565).convert(source, &destination),
        conversionId(.bgra32, .rgb24) => RgbaColorToRgbColor(.bgra32, .rgb24).convert(source, &destination),
        conversionId(.bgra32, .rgba32) => FastRgba32Shuffle(.bgra32, .rgba32).convert(source, &destination),
        conversionId(.bgra32, .bgr555) => RgbaColorToRgbColor(.bgra32, .bgr555).convert(source, &destination),
        conversionId(.bgra32, .bgr24) => RgbaColorToRgbColor(.bgra32, .bgr24).convert(source, &destination),
        conversionId(.bgra32, .rgb48) => RgbaColorToRgbColor(.bgra32, .rgb48).convert(source, &destination),
        conversionId(.bgra32, .rgba64) => RgbaColorToRgbaColor(.bgra32, .rgba64).convert(source, &destination),
        conversionId(.bgra32, .float32) => bgra32ToColorf32(.bgra32, source, &destination),

        // rgb48 -> RGB + Colorf32
        conversionId(.rgb48, .rgb555) => RgbColorToRgbColor(.rgb48, .rgb555).convert(source, &destination),
        conversionId(.rgb48, .rgb565) => RgbColorToRgbColor(.rgb48, .rgb565).convert(source, &destination),
        conversionId(.rgb48, .rgb24) => RgbColorToRgbColor(.rgb48, .rgb24).convert(source, &destination),
        conversionId(.rgb48, .rgba32) => RgbColorToRgbaColor(.rgb48, .rgba32).convert(source, &destination),
        conversionId(.rgb48, .bgr555) => RgbColorToRgbColor(.rgb48, .bgr555).convert(source, &destination),
        conversionId(.rgb48, .bgr24) => RgbColorToRgbColor(.rgb48, .bgr24).convert(source, &destination),
        conversionId(.rgb48, .bgra32) => RgbColorToRgbaColor(.rgb48, .bgra32).convert(source, &destination),
        conversionId(.rgb48, .rgba64) => RgbColorToRgbaColor(.rgb48, .rgba64).convert(source, &destination),
        conversionId(.rgb48, .float32) => rgbColorToColorf32(.rgb48, source, &destination),

        // rgba64 -> RGB + Colorf32
        conversionId(.rgba64, .rgb555) => RgbaColorToRgbColor(.rgba64, .rgb555).convert(source, &destination),
        conversionId(.rgba64, .rgb565) => RgbaColorToRgbColor(.rgba64, .rgb565).convert(source, &destination),
        conversionId(.rgba64, .rgb24) => RgbaColorToRgbColor(.rgba64, .rgb24).convert(source, &destination),
        conversionId(.rgba64, .rgba32) => RgbaColorToRgbaColor(.rgba64, .rgba32).convert(source, &destination),
        conversionId(.rgba64, .bgr555) => RgbaColorToRgbColor(.rgba64, .bgr555).convert(source, &destination),
        conversionId(.rgba64, .bgr24) => RgbaColorToRgbColor(.rgba64, .bgr24).convert(source, &destination),
        conversionId(.rgba64, .bgra32) => RgbaColorToRgbColor(.rgba64, .bgra32).convert(source, &destination),
        conversionId(.rgba64, .rgb48) => RgbaColorToRgbColor(.rgba64, .rgb48).convert(source, &destination),
        conversionId(.rgba64, .float32) => rgbColorToColorf32(.rgba64, source, &destination),

        // Colorf32(float32) -> RGB
        conversionId(.float32, .rgb555) => colorf32ToRgbColor(.rgb555, source, &destination),
        conversionId(.float32, .rgb565) => colorf32ToRgbColor(.rgb565, source, &destination),
        conversionId(.float32, .rgb24) => colorf32ToRgbColor(.rgb24, source, &destination),
        conversionId(.float32, .rgba32) => colorf32ToRgba32(.rgba32, source, &destination),
        conversionId(.float32, .bgr555) => colorf32ToRgbColor(.bgr555, source, &destination),
        conversionId(.float32, .bgr24) => colorf32ToRgbColor(.bgr24, source, &destination),
        conversionId(.float32, .bgra32) => colorf32ToBgra32(.bgra32, source, &destination),
        conversionId(.float32, .rgb48) => colorf32ToRgbColor(.rgb48, source, &destination),
        conversionId(.float32, .rgba64) => colorf32ToRgbaColor(.rgba64, source, &destination),

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

fn grayscaleToGrayscale(comptime T: type, grey: anytype) T {
    return T{
        .value = color.scaleToIntColor(std.meta.fieldInfo(T, .value).type, grey.value),
    };
}

fn grayscaleAlphaToGrayscale(comptime T: type, grey: anytype) T {
    const alpha = color.toF32Color(grey.alpha);
    return T{
        .value = color.toIntColor(std.meta.fieldInfo(T, .value).type, color.toF32Color(grey.value) * alpha),
    };
}

fn grayscaleAlphaToGrayscaleAlpha(comptime T: type, grey: anytype) T {
    return T{
        .value = color.scaleToIntColor(std.meta.fieldInfo(T, .value).type, grey.value),
        .alpha = color.scaleToIntColor(std.meta.fieldInfo(T, .alpha).type, grey.alpha),
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

fn GreyscaleToGrayscale(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleToGrayscale(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn GreyscaleAlphaToGrayscale(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToGrayscale(destination_type, source_greyscale[index]);
            }
        }
    };
}

fn GreyscaleAlphaToGrayscaleAlpha(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_greyscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_greyscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToGrayscaleAlpha(destination_type, source_greyscale[index]);
            }
        }
    };
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

fn RgbColorToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_rgb.len) |index| {
                destination_pixels[index] = rgbToRgb(destination_type, source_rgb[index]);
            }
        }
    };
}

fn RgbColorToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_rgb.len) |index| {
                destination_pixels[index] = rgbToRgba(destination_type, source_rgb[index]);
            }
        }
    };
}

fn RgbaColorToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_rgb.len) |index| {
                destination_pixels[index] = rgbaToRgb(destination_type, source_rgb[index]);
            }
        }
    };
}

fn RgbaColorToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_rgb.len) |index| {
                destination_pixels[index] = rgbaToRgba(destination_type, source_rgb[index]);
            }
        }
    };
}

fn rgbColorToColorf32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));

    for (0..source_rgb.len) |index| {
        destination.float32[index] = source_rgb[index].toColorf32();
    }
}

fn FastRgba32Shuffle(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_pixels = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            const vector_length = std.simd.suggestVectorLength(u8) orelse 4;
            const color_count = vector_length / 4;
            const VectorType = @Vector(vector_length, u8);

            var index: usize = 0;

            const shuffle_mask: @Vector(vector_length, i32) = comptime blk: {
                var result: @Vector(vector_length, i32) = @splat(0);

                for (0..color_count) |i| {
                    const stride = i * 4;
                    result[stride + 0] = stride + 2;
                    result[stride + 1] = stride + 1;
                    result[stride + 2] = stride + 0;
                    result[stride + 3] = stride + 3;
                }

                break :blk result;
            };

            // Process with SIMD as much as possible
            while (index < source_pixels.len and ((index + color_count) <= source_pixels.len)) {
                const vector_source = simd.loadBytes(std.mem.sliceAsBytes(source_pixels[index..]), VectorType, vector_length);

                const shuffled = @shuffle(u8, vector_source, undefined, shuffle_mask);

                simd.store(u8, std.mem.sliceAsBytes(destination_pixels[index..]), shuffled, vector_length);

                index += color_count;
            }

            // Process the rest sequentially
            while (index < source_pixels.len) {
                destination_pixels[index] = rgbaToRgba(destination_type, source_pixels[index]);
            }
        }
    };
}

fn rgba32ToColorf32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = @field(source, getFieldNameFromPixelFormat(source_format));
    var destination_pixels = destination.float32;
    var destination_f32: [*]f32 = @alignCast(@ptrCast(destination_pixels.ptr));

    const vector_length = std.simd.suggestVectorLength(u8) orelse 4;
    const color_count = vector_length / 4;
    const ByteVectorType = @Vector(vector_length, u8);
    const FloatVectorType = @Vector(vector_length, f32);

    var index: usize = 0;
    // Process with SIMD as much as possible
    while (index < source_pixels.len and ((index + color_count) <= source_pixels.len)) {
        const source_vector = simd.loadBytes(std.mem.sliceAsBytes(source_pixels[index..]), ByteVectorType, vector_length);

        const float_vector = simd.intToFloat(f32, source_vector, vector_length);
        const conversion_vector: FloatVectorType = @splat(255.0);

        const destination_vector = float_vector / conversion_vector;

        simd.store(f32, destination_f32[(index * 4)..(index * 4 + color_count * 4)], destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) {
        destination_pixels[index] = source_pixels[index].toColorf32();
    }
}

fn bgra32ToColorf32(comptime source_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = @field(source, getFieldNameFromPixelFormat(source_format));
    var destination_pixels = destination.float32;
    var destination_f32: [*]f32 = @alignCast(@ptrCast(destination_pixels.ptr));

    const vector_length = std.simd.suggestVectorLength(u8) orelse 4;
    const color_count = vector_length / 4;
    const ByteVectorType = @Vector(vector_length, u8);
    const FloatVectorType = @Vector(vector_length, f32);

    const shuffle_mask: @Vector(vector_length, i32) = comptime blk: {
        var result: @Vector(vector_length, i32) = @splat(0);

        for (0..color_count) |i| {
            const stride = i * 4;
            result[stride + 0] = stride + 2;
            result[stride + 1] = stride + 1;
            result[stride + 2] = stride + 0;
            result[stride + 3] = stride + 3;
        }

        break :blk result;
    };

    var index: usize = 0;
    // Process with SIMD as much as possible
    while (index < source_pixels.len and ((index + color_count) <= source_pixels.len)) {
        const source_vector = simd.loadBytes(std.mem.sliceAsBytes(source_pixels[index..]), ByteVectorType, vector_length);

        const shuffled = @shuffle(u8, source_vector, undefined, shuffle_mask);

        const float_vector = simd.intToFloat(f32, shuffled, vector_length);
        const conversion_vector: FloatVectorType = @splat(255.0);

        const destination_vector = float_vector / conversion_vector;

        simd.store(f32, destination_f32[(index * 4)..(index * 4 + color_count * 4)], destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) {
        destination_pixels[index] = source_pixels[index].toColorf32();
    }
}

fn colorf32ToRgb(comptime T: type, source: color.Colorf32) T {
    return T{
        .r = color.toIntColor(std.meta.fieldInfo(T, .r).type, source.r),
        .g = color.toIntColor(std.meta.fieldInfo(T, .g).type, source.g),
        .b = color.toIntColor(std.meta.fieldInfo(T, .b).type, source.b),
    };
}

fn colorf32ToRgba(comptime T: type, source: color.Colorf32) T {
    return T{
        .r = color.toIntColor(std.meta.fieldInfo(T, .r).type, source.r),
        .g = color.toIntColor(std.meta.fieldInfo(T, .g).type, source.g),
        .b = color.toIntColor(std.meta.fieldInfo(T, .b).type, source.b),
        .a = color.toIntColor(std.meta.fieldInfo(T, .a).type, source.a),
    };
}

fn colorf32ToRgbColor(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const destination_type = @TypeOf(destination_pixels[0]);

    for (0..source_pixels.len) |index| {
        destination_pixels[index] = colorf32ToRgb(destination_type, source_pixels[index]);
    }
}

fn colorf32ToRgbaColor(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const destination_type = @TypeOf(destination_pixels[0]);

    for (0..source_pixels.len) |index| {
        destination_pixels[index] = colorf32ToRgba(destination_type, source_pixels[index]);
    }
}

fn colorf32ToRgba32(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;
    var source_f32: [*]f32 = @alignCast(@ptrCast(source_pixels.ptr));

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const destination_type = @TypeOf(destination_pixels[0]);

    const vector_length = std.simd.suggestVectorLength(u8) orelse 4;
    const color_count = vector_length / 4;
    const FloatVectorType = @Vector(vector_length, f32);

    var index: usize = 0;
    // Process with SIMD as much as possible
    while (index < source_pixels.len and ((index + color_count) <= source_pixels.len)) {
        const source_vector = simd.load(f32, source_f32[(index * 4)..(index * 4 + color_count * 4)], FloatVectorType, vector_length);

        const conversion_vector: FloatVectorType = @splat(255.0);
        const converted_vector = source_vector * conversion_vector;

        const destination_vector = simd.floatToInt(u8, converted_vector, vector_length);

        simd.store(u8, std.mem.sliceAsBytes(destination_pixels[index..]), destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) {
        destination_pixels[index] = colorf32ToRgba(destination_type, source_pixels[index]);
    }
}

fn colorf32ToBgra32(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;
    var source_f32: [*]f32 = @alignCast(@ptrCast(source_pixels.ptr));

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const destination_type = @TypeOf(destination_pixels[0]);

    const vector_length = std.simd.suggestVectorLength(u8) orelse 4;
    const color_count = vector_length / 4;
    const FloatVectorType = @Vector(vector_length, f32);

    const shuffle_mask: @Vector(vector_length, i32) = comptime blk: {
        var result: @Vector(vector_length, i32) = @splat(0);

        for (0..color_count) |i| {
            const stride = i * 4;
            result[stride + 0] = stride + 2;
            result[stride + 1] = stride + 1;
            result[stride + 2] = stride + 0;
            result[stride + 3] = stride + 3;
        }

        break :blk result;
    };

    var index: usize = 0;
    // Process with SIMD as much as possible
    while (index < source_pixels.len and ((index + color_count) <= source_pixels.len)) {
        const source_vector = simd.load(f32, source_f32[(index * 4)..(index * 4 + color_count * 4)], FloatVectorType, vector_length);

        const shuffled = @shuffle(f32, source_vector, undefined, shuffle_mask);

        const conversion_vector: FloatVectorType = @splat(255.0);
        const converted_vector = shuffled * conversion_vector;

        const destination_vector = simd.floatToInt(u8, converted_vector, vector_length);

        simd.store(u8, std.mem.sliceAsBytes(destination_pixels[index..]), destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) {
        destination_pixels[index] = colorf32ToRgba(destination_type, source_pixels[index]);
    }
}
