const color = @import("color.zig");
const math = @import("math.zig");
const simd = @import("simd.zig");
const std = @import("std");

const Image = @import("Image.zig");
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const OctTreeQuantizer = @import("OctTreeQuantizer.zig");

// The RGB to Grayscale factors are those for Rec. 709/sRGB assuming linear RGB
const GrayscaleFactors: math.float4 = .{ 0.2125, 0.7154, 0.0721, 1.0 };

/// Convert a pixel storage into another format.
/// For the conversion to the indexed formats, no dithering is done.
pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination_format: PixelFormat) Image.ConvertError!color.PixelStorage {
    if (std.meta.activeTag(source.*) == destination_format) {
        return Image.ConvertError.NoConversionNeeded;
    }

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

        // Indexed large -> small
        conversionId(.indexed2, .indexed1) => try IndexedLargeToSmall(.indexed2, .indexed1).convert(allocator, source, &destination),

        conversionId(.indexed4, .indexed1) => try IndexedLargeToSmall(.indexed4, .indexed1).convert(allocator, source, &destination),
        conversionId(.indexed4, .indexed2) => try IndexedLargeToSmall(.indexed4, .indexed2).convert(allocator, source, &destination),

        conversionId(.indexed8, .indexed1) => try IndexedLargeToSmall(.indexed8, .indexed1).convert(allocator, source, &destination),
        conversionId(.indexed8, .indexed2) => try IndexedLargeToSmall(.indexed8, .indexed2).convert(allocator, source, &destination),
        conversionId(.indexed8, .indexed4) => try IndexedLargeToSmall(.indexed8, .indexed4).convert(allocator, source, &destination),

        conversionId(.indexed16, .indexed1) => try IndexedLargeToSmall(.indexed16, .indexed1).convert(allocator, source, &destination),
        conversionId(.indexed16, .indexed2) => try IndexedLargeToSmall(.indexed16, .indexed2).convert(allocator, source, &destination),
        conversionId(.indexed16, .indexed4) => try IndexedLargeToSmall(.indexed16, .indexed4).convert(allocator, source, &destination),
        conversionId(.indexed16, .indexed8) => try IndexedLargeToSmall(.indexed16, .indexed8).convert(allocator, source, &destination),

        // Indexed -> RGB332
        conversionId(.indexed1, .rgb332) => IndexedToRgbColor(.indexed1, .rgb332).convert(source, &destination),
        conversionId(.indexed2, .rgb332) => IndexedToRgbColor(.indexed2, .rgb332).convert(source, &destination),
        conversionId(.indexed4, .rgb332) => IndexedToRgbColor(.indexed4, .rgb332).convert(source, &destination),
        conversionId(.indexed8, .rgb332) => IndexedToRgbColor(.indexed8, .rgb332).convert(source, &destination),
        conversionId(.indexed16, .rgb332) => IndexedToRgbColor(.indexed16, .rgb332).convert(source, &destination),

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

        // Grayscale -> indexed
        conversionId(.grayscale1, .indexed1) => try GrayscaleToIndexed(.grayscale1, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale1, .indexed2) => try GrayscaleToIndexed(.grayscale1, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale1, .indexed4) => try GrayscaleToIndexed(.grayscale1, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale1, .indexed8) => try GrayscaleToIndexed(.grayscale1, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale1, .indexed16) => try GrayscaleToIndexed(.grayscale1, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale2, .indexed1) => try GrayscaleToIndexed(.grayscale2, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale2, .indexed2) => try GrayscaleToIndexed(.grayscale2, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale2, .indexed4) => try GrayscaleToIndexed(.grayscale2, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale2, .indexed8) => try GrayscaleToIndexed(.grayscale2, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale2, .indexed16) => try GrayscaleToIndexed(.grayscale2, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale4, .indexed1) => try GrayscaleToIndexed(.grayscale4, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale4, .indexed2) => try GrayscaleToIndexed(.grayscale4, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale4, .indexed4) => try GrayscaleToIndexed(.grayscale4, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale4, .indexed8) => try GrayscaleToIndexed(.grayscale4, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale4, .indexed16) => try GrayscaleToIndexed(.grayscale4, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale8, .indexed1) => try GrayscaleToIndexed(.grayscale8, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale8, .indexed2) => try GrayscaleToIndexed(.grayscale8, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale8, .indexed4) => try GrayscaleToIndexed(.grayscale8, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale8, .indexed8) => try GrayscaleToIndexed(.grayscale8, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale8, .indexed16) => try GrayscaleToIndexed(.grayscale8, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale16, .indexed1) => try GrayscaleToIndexed(.grayscale16, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale16, .indexed2) => try GrayscaleToIndexed(.grayscale16, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale16, .indexed4) => try GrayscaleToIndexed(.grayscale16, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale16, .indexed8) => try GrayscaleToIndexed(.grayscale16, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale16, .indexed16) => try GrayscaleToIndexed(.grayscale16, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale8Alpha, .indexed1) => try GrayscaleAlphaToIndexed(.grayscale8Alpha, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale8Alpha, .indexed2) => try GrayscaleAlphaToIndexed(.grayscale8Alpha, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale8Alpha, .indexed4) => try GrayscaleAlphaToIndexed(.grayscale8Alpha, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale8Alpha, .indexed8) => try GrayscaleAlphaToIndexed(.grayscale8Alpha, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale8Alpha, .indexed16) => try GrayscaleAlphaToIndexed(.grayscale8Alpha, .indexed16).convert(allocator, source, &destination),

        conversionId(.grayscale16Alpha, .indexed1) => try GrayscaleAlphaToIndexed(.grayscale16Alpha, .indexed1).convert(allocator, source, &destination),
        conversionId(.grayscale16Alpha, .indexed2) => try GrayscaleAlphaToIndexed(.grayscale16Alpha, .indexed2).convert(allocator, source, &destination),
        conversionId(.grayscale16Alpha, .indexed4) => try GrayscaleAlphaToIndexed(.grayscale16Alpha, .indexed4).convert(allocator, source, &destination),
        conversionId(.grayscale16Alpha, .indexed8) => try GrayscaleAlphaToIndexed(.grayscale16Alpha, .indexed8).convert(allocator, source, &destination),
        conversionId(.grayscale16Alpha, .indexed16) => try GrayscaleAlphaToIndexed(.grayscale16Alpha, .indexed16).convert(allocator, source, &destination),

        // Grayscale small -> large
        conversionId(.grayscale1, .grayscale2) => GrayscaleToGrayscale(.grayscale1, .grayscale2).convert(source, &destination),
        conversionId(.grayscale1, .grayscale4) => GrayscaleToGrayscale(.grayscale1, .grayscale4).convert(source, &destination),
        conversionId(.grayscale1, .grayscale8) => GrayscaleToGrayscale(.grayscale1, .grayscale8).convert(source, &destination),
        conversionId(.grayscale1, .grayscale16) => GrayscaleToGrayscale(.grayscale1, .grayscale16).convert(source, &destination),
        conversionId(.grayscale1, .grayscale8Alpha) => GrayscaleToGrayscale(.grayscale1, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale1, .grayscale16Alpha) => GrayscaleToGrayscale(.grayscale1, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale2, .grayscale4) => GrayscaleToGrayscale(.grayscale2, .grayscale4).convert(source, &destination),
        conversionId(.grayscale2, .grayscale8) => GrayscaleToGrayscale(.grayscale2, .grayscale8).convert(source, &destination),
        conversionId(.grayscale2, .grayscale16) => GrayscaleToGrayscale(.grayscale2, .grayscale16).convert(source, &destination),
        conversionId(.grayscale2, .grayscale8Alpha) => GrayscaleToGrayscale(.grayscale2, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale2, .grayscale16Alpha) => GrayscaleToGrayscale(.grayscale2, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale4, .grayscale8) => GrayscaleToGrayscale(.grayscale4, .grayscale8).convert(source, &destination),
        conversionId(.grayscale4, .grayscale16) => GrayscaleToGrayscale(.grayscale4, .grayscale16).convert(source, &destination),
        conversionId(.grayscale4, .grayscale8Alpha) => GrayscaleToGrayscale(.grayscale4, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale4, .grayscale16Alpha) => GrayscaleToGrayscale(.grayscale4, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale8, .grayscale16) => GrayscaleToGrayscale(.grayscale8, .grayscale16).convert(source, &destination),
        conversionId(.grayscale8, .grayscale8Alpha) => GrayscaleToGrayscale(.grayscale8, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale8, .grayscale16Alpha) => GrayscaleToGrayscale(.grayscale8, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale16, .grayscale16Alpha) => GrayscaleToGrayscale(.grayscale16, .grayscale16Alpha).convert(source, &destination),

        conversionId(.grayscale8Alpha, .grayscale16Alpha) => GrayscaleAlphaToGrayscaleAlpha(.grayscale8Alpha, .grayscale16Alpha).convert(source, &destination),

        // Grayscale large -> small
        conversionId(.grayscale16Alpha, .grayscale8Alpha) => GrayscaleAlphaToGrayscaleAlpha(.grayscale16Alpha, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale16) => GrayscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale16).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale8) => GrayscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale8).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale4) => GrayscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale4).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale2) => GrayscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale2).convert(source, &destination),
        conversionId(.grayscale16Alpha, .grayscale1) => GrayscaleAlphaToGrayscale(.grayscale16Alpha, .grayscale1).convert(source, &destination),

        conversionId(.grayscale8Alpha, .grayscale16) => GrayscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale16).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale8) => GrayscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale8).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale4) => GrayscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale4).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale2) => GrayscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale2).convert(source, &destination),
        conversionId(.grayscale8Alpha, .grayscale1) => GrayscaleAlphaToGrayscale(.grayscale8Alpha, .grayscale1).convert(source, &destination),

        conversionId(.grayscale16, .grayscale8Alpha) => GrayscaleToGrayscale(.grayscale16, .grayscale8Alpha).convert(source, &destination),
        conversionId(.grayscale16, .grayscale8) => GrayscaleToGrayscale(.grayscale16, .grayscale8).convert(source, &destination),
        conversionId(.grayscale16, .grayscale4) => GrayscaleToGrayscale(.grayscale16, .grayscale4).convert(source, &destination),
        conversionId(.grayscale16, .grayscale2) => GrayscaleToGrayscale(.grayscale16, .grayscale2).convert(source, &destination),
        conversionId(.grayscale16, .grayscale1) => GrayscaleToGrayscale(.grayscale16, .grayscale1).convert(source, &destination),

        conversionId(.grayscale8, .grayscale4) => GrayscaleToGrayscale(.grayscale8, .grayscale4).convert(source, &destination),
        conversionId(.grayscale8, .grayscale2) => GrayscaleToGrayscale(.grayscale8, .grayscale2).convert(source, &destination),
        conversionId(.grayscale8, .grayscale1) => GrayscaleToGrayscale(.grayscale8, .grayscale1).convert(source, &destination),

        conversionId(.grayscale4, .grayscale2) => GrayscaleToGrayscale(.grayscale4, .grayscale2).convert(source, &destination),
        conversionId(.grayscale4, .grayscale1) => GrayscaleToGrayscale(.grayscale4, .grayscale1).convert(source, &destination),

        conversionId(.grayscale2, .grayscale1) => GrayscaleToGrayscale(.grayscale2, .grayscale1).convert(source, &destination),

        // Grayscale -> RGB332
        conversionId(.grayscale1, .rgb332) => GrayscaleToRgbColor(.grayscale1, .rgb332).convert(source, &destination),
        conversionId(.grayscale2, .rgb332) => GrayscaleToRgbColor(.grayscale2, .rgb332).convert(source, &destination),
        conversionId(.grayscale4, .rgb332) => GrayscaleToRgbColor(.grayscale4, .rgb332).convert(source, &destination),
        conversionId(.grayscale8, .rgb332) => GrayscaleToRgbColor(.grayscale8, .rgb332).convert(source, &destination),
        conversionId(.grayscale16, .rgb332) => GrayscaleToRgbColor(.grayscale16, .rgb332).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb332) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .rgb332).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb332) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .rgb332).convert(source, &destination),

        // Grayscale -> RGB555
        conversionId(.grayscale1, .rgb555) => GrayscaleToRgbColor(.grayscale1, .rgb555).convert(source, &destination),
        conversionId(.grayscale2, .rgb555) => GrayscaleToRgbColor(.grayscale2, .rgb555).convert(source, &destination),
        conversionId(.grayscale4, .rgb555) => GrayscaleToRgbColor(.grayscale4, .rgb555).convert(source, &destination),
        conversionId(.grayscale8, .rgb555) => GrayscaleToRgbColor(.grayscale8, .rgb555).convert(source, &destination),
        conversionId(.grayscale16, .rgb555) => GrayscaleToRgbColor(.grayscale16, .rgb555).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb555) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .rgb555).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb555) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .rgb555).convert(source, &destination),

        // Grayscale -> RGB565
        conversionId(.grayscale1, .rgb565) => GrayscaleToRgbColor(.grayscale1, .rgb565).convert(source, &destination),
        conversionId(.grayscale2, .rgb565) => GrayscaleToRgbColor(.grayscale2, .rgb565).convert(source, &destination),
        conversionId(.grayscale4, .rgb565) => GrayscaleToRgbColor(.grayscale4, .rgb565).convert(source, &destination),
        conversionId(.grayscale8, .rgb565) => GrayscaleToRgbColor(.grayscale8, .rgb565).convert(source, &destination),
        conversionId(.grayscale16, .rgb565) => GrayscaleToRgbColor(.grayscale16, .rgb565).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb565) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .rgb565).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb565) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .rgb565).convert(source, &destination),

        // Grayscale -> RGB24
        conversionId(.grayscale1, .rgb24) => GrayscaleToRgbColor(.grayscale1, .rgb24).convert(source, &destination),
        conversionId(.grayscale2, .rgb24) => GrayscaleToRgbColor(.grayscale2, .rgb24).convert(source, &destination),
        conversionId(.grayscale4, .rgb24) => GrayscaleToRgbColor(.grayscale4, .rgb24).convert(source, &destination),
        conversionId(.grayscale8, .rgb24) => GrayscaleToRgbColor(.grayscale8, .rgb24).convert(source, &destination),
        conversionId(.grayscale16, .rgb24) => GrayscaleToRgbColor(.grayscale16, .rgb24).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb24) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .rgb24).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb24) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .rgb24).convert(source, &destination),

        // Grayscale -> RGBA32
        conversionId(.grayscale1, .rgba32) => GrayscaleToRgbaColor(.grayscale1, .rgba32).convert(source, &destination),
        conversionId(.grayscale2, .rgba32) => GrayscaleToRgbaColor(.grayscale2, .rgba32).convert(source, &destination),
        conversionId(.grayscale4, .rgba32) => GrayscaleToRgbaColor(.grayscale4, .rgba32).convert(source, &destination),
        conversionId(.grayscale8, .rgba32) => GrayscaleToRgbaColor(.grayscale8, .rgba32).convert(source, &destination),
        conversionId(.grayscale16, .rgba32) => GrayscaleToRgbaColor(.grayscale16, .rgba32).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgba32) => GrayscaleAlphaToRgbaColor(.grayscale8Alpha, .rgba32).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgba32) => GrayscaleAlphaToRgbaColor(.grayscale16Alpha, .rgba32).convert(source, &destination),

        // Grayscale -> BGR555
        conversionId(.grayscale1, .bgr555) => GrayscaleToRgbColor(.grayscale1, .bgr555).convert(source, &destination),
        conversionId(.grayscale2, .bgr555) => GrayscaleToRgbColor(.grayscale2, .bgr555).convert(source, &destination),
        conversionId(.grayscale4, .bgr555) => GrayscaleToRgbColor(.grayscale4, .bgr555).convert(source, &destination),
        conversionId(.grayscale8, .bgr555) => GrayscaleToRgbColor(.grayscale8, .bgr555).convert(source, &destination),
        conversionId(.grayscale16, .bgr555) => GrayscaleToRgbColor(.grayscale16, .bgr555).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgr555) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .bgr555).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgr555) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .bgr555).convert(source, &destination),

        // Grayscale -> BGR24
        conversionId(.grayscale1, .bgr24) => GrayscaleToRgbColor(.grayscale1, .bgr24).convert(source, &destination),
        conversionId(.grayscale2, .bgr24) => GrayscaleToRgbColor(.grayscale2, .bgr24).convert(source, &destination),
        conversionId(.grayscale4, .bgr24) => GrayscaleToRgbColor(.grayscale4, .bgr24).convert(source, &destination),
        conversionId(.grayscale8, .bgr24) => GrayscaleToRgbColor(.grayscale8, .bgr24).convert(source, &destination),
        conversionId(.grayscale16, .bgr24) => GrayscaleToRgbColor(.grayscale16, .bgr24).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgr24) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .bgr24).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgr24) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .bgr24).convert(source, &destination),

        // Grayscale -> BGRA32
        conversionId(.grayscale1, .bgra32) => GrayscaleToRgbaColor(.grayscale1, .bgra32).convert(source, &destination),
        conversionId(.grayscale2, .bgra32) => GrayscaleToRgbaColor(.grayscale2, .bgra32).convert(source, &destination),
        conversionId(.grayscale4, .bgra32) => GrayscaleToRgbaColor(.grayscale4, .bgra32).convert(source, &destination),
        conversionId(.grayscale8, .bgra32) => GrayscaleToRgbaColor(.grayscale8, .bgra32).convert(source, &destination),
        conversionId(.grayscale16, .bgra32) => GrayscaleToRgbaColor(.grayscale16, .bgra32).convert(source, &destination),
        conversionId(.grayscale8Alpha, .bgra32) => GrayscaleAlphaToRgbaColor(.grayscale8Alpha, .bgra32).convert(source, &destination),
        conversionId(.grayscale16Alpha, .bgra32) => GrayscaleAlphaToRgbaColor(.grayscale16Alpha, .bgra32).convert(source, &destination),

        // Grayscale -> RGB48
        conversionId(.grayscale1, .rgb48) => GrayscaleToRgbColor(.grayscale1, .rgb48).convert(source, &destination),
        conversionId(.grayscale2, .rgb48) => GrayscaleToRgbColor(.grayscale2, .rgb48).convert(source, &destination),
        conversionId(.grayscale4, .rgb48) => GrayscaleToRgbColor(.grayscale4, .rgb48).convert(source, &destination),
        conversionId(.grayscale8, .rgb48) => GrayscaleToRgbColor(.grayscale8, .rgb48).convert(source, &destination),
        conversionId(.grayscale16, .rgb48) => GrayscaleToRgbColor(.grayscale16, .rgb48).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgb48) => GrayscaleAlphaToRgbColor(.grayscale8Alpha, .rgb48).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgb48) => GrayscaleAlphaToRgbColor(.grayscale16Alpha, .rgb48).convert(source, &destination),

        // Grayscale -> RGBA64
        conversionId(.grayscale1, .rgba64) => GrayscaleToRgbaColor(.grayscale1, .rgba64).convert(source, &destination),
        conversionId(.grayscale2, .rgba64) => GrayscaleToRgbaColor(.grayscale2, .rgba64).convert(source, &destination),
        conversionId(.grayscale4, .rgba64) => GrayscaleToRgbaColor(.grayscale4, .rgba64).convert(source, &destination),
        conversionId(.grayscale8, .rgba64) => GrayscaleToRgbaColor(.grayscale8, .rgba64).convert(source, &destination),
        conversionId(.grayscale16, .rgba64) => GrayscaleToRgbaColor(.grayscale16, .rgba64).convert(source, &destination),
        conversionId(.grayscale8Alpha, .rgba64) => GrayscaleAlphaToRgbaColor(.grayscale8Alpha, .rgba64).convert(source, &destination),
        conversionId(.grayscale16Alpha, .rgba64) => GrayscaleAlphaToRgbaColor(.grayscale16Alpha, .rgba64).convert(source, &destination),

        // Grayscale -> Colorf32
        conversionId(.grayscale1, .float32) => grayscaleToColorf32(.grayscale1, source, &destination),
        conversionId(.grayscale2, .float32) => grayscaleToColorf32(.grayscale2, source, &destination),
        conversionId(.grayscale4, .float32) => grayscaleToColorf32(.grayscale4, source, &destination),
        conversionId(.grayscale8, .float32) => grayscaleToColorf32(.grayscale8, source, &destination),
        conversionId(.grayscale16, .float32) => grayscaleToColorf32(.grayscale16, source, &destination),
        conversionId(.grayscale8Alpha, .float32) => grayscaleToColorf32(.grayscale8Alpha, source, &destination),
        conversionId(.grayscale16Alpha, .float32) => grayscaleToColorf32(.grayscale16Alpha, source, &destination),

        // rgb332 -> Indexed
        conversionId(.rgb332, .indexed1) => try RgbColorToIndexed(.rgb332, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgb332, .indexed2) => try RgbColorToIndexed(.rgb332, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgb332, .indexed4) => try RgbColorToIndexed(.rgb332, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgb332, .indexed8) => try RgbColorToIndexed(.rgb332, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgb332, .indexed16) => try RgbColorToIndexed(.rgb332, .indexed16).convert(allocator, source, &destination),

        // rgb332 -> Grayscale
        conversionId(.rgb332, .grayscale1) => RgbColorToGrayscale(.rgb332, .grayscale1).convert(source, &destination),
        conversionId(.rgb332, .grayscale2) => RgbColorToGrayscale(.rgb332, .grayscale2).convert(source, &destination),
        conversionId(.rgb332, .grayscale4) => RgbColorToGrayscale(.rgb332, .grayscale4).convert(source, &destination),
        conversionId(.rgb332, .grayscale8) => RgbColorToGrayscale(.rgb332, .grayscale8).convert(source, &destination),
        conversionId(.rgb332, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgb332, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgb332, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgb332, .grayscale16Alpha).convert(source, &destination),

        // rgb332 -> RGB + Colorf32
        conversionId(.rgb332, .rgb555) => RgbColorToRgbColor(.rgb332, .rgb555).convert(source, &destination),
        conversionId(.rgb332, .rgb565) => RgbColorToRgbColor(.rgb332, .rgb565).convert(source, &destination),
        conversionId(.rgb332, .rgb24) => RgbColorToRgbColor(.rgb332, .rgb24).convert(source, &destination),
        conversionId(.rgb332, .rgba32) => RgbColorToRgbaColor(.rgb332, .rgba32).convert(source, &destination),
        conversionId(.rgb332, .bgr555) => RgbColorToRgbColor(.rgb332, .bgr555).convert(source, &destination),
        conversionId(.rgb332, .bgr24) => RgbColorToRgbColor(.rgb332, .bgr24).convert(source, &destination),
        conversionId(.rgb332, .bgra32) => RgbColorToRgbaColor(.rgb332, .bgra32).convert(source, &destination),
        conversionId(.rgb332, .rgb48) => RgbColorToRgbColor(.rgb332, .rgb48).convert(source, &destination),
        conversionId(.rgb332, .rgba64) => RgbColorToRgbaColor(.rgb332, .rgba64).convert(source, &destination),
        conversionId(.rgb332, .float32) => rgbColorToColorf32(.rgb332, source, &destination),

        // rgb555 -> Indexed
        conversionId(.rgb555, .indexed1) => try RgbColorToIndexed(.rgb555, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgb555, .indexed2) => try RgbColorToIndexed(.rgb555, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgb555, .indexed4) => try RgbColorToIndexed(.rgb555, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgb555, .indexed8) => try RgbColorToIndexed(.rgb555, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgb555, .indexed16) => try RgbColorToIndexed(.rgb555, .indexed16).convert(allocator, source, &destination),

        // rgb555 -> Grayscale
        conversionId(.rgb555, .grayscale1) => RgbColorToGrayscale(.rgb555, .grayscale1).convert(source, &destination),
        conversionId(.rgb555, .grayscale2) => RgbColorToGrayscale(.rgb555, .grayscale2).convert(source, &destination),
        conversionId(.rgb555, .grayscale4) => RgbColorToGrayscale(.rgb555, .grayscale4).convert(source, &destination),
        conversionId(.rgb555, .grayscale8) => RgbColorToGrayscale(.rgb555, .grayscale8).convert(source, &destination),
        conversionId(.rgb555, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgb555, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgb555, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgb555, .grayscale16Alpha).convert(source, &destination),

        // rgb555 -> RGB + Colorf32
        conversionId(.rgb555, .rgb332) => RgbColorToRgbColor(.rgb555, .rgb332).convert(source, &destination),
        conversionId(.rgb555, .rgb565) => RgbColorToRgbColor(.rgb555, .rgb565).convert(source, &destination),
        conversionId(.rgb555, .rgb24) => RgbColorToRgbColor(.rgb555, .rgb24).convert(source, &destination),
        conversionId(.rgb555, .rgba32) => RgbColorToRgbaColor(.rgb555, .rgba32).convert(source, &destination),
        conversionId(.rgb555, .bgr555) => RgbColorToRgbColor(.rgb555, .bgr555).convert(source, &destination),
        conversionId(.rgb555, .bgr24) => RgbColorToRgbColor(.rgb555, .bgr24).convert(source, &destination),
        conversionId(.rgb555, .bgra32) => RgbColorToRgbaColor(.rgb555, .bgra32).convert(source, &destination),
        conversionId(.rgb555, .rgb48) => RgbColorToRgbColor(.rgb555, .rgb48).convert(source, &destination),
        conversionId(.rgb555, .rgba64) => RgbColorToRgbaColor(.rgb555, .rgba64).convert(source, &destination),
        conversionId(.rgb555, .float32) => rgbColorToColorf32(.rgb555, source, &destination),

        // rgb565 -> Indexed
        conversionId(.rgb565, .indexed1) => try RgbColorToIndexed(.rgb565, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgb565, .indexed2) => try RgbColorToIndexed(.rgb565, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgb565, .indexed4) => try RgbColorToIndexed(.rgb565, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgb565, .indexed8) => try RgbColorToIndexed(.rgb565, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgb565, .indexed16) => try RgbColorToIndexed(.rgb565, .indexed16).convert(allocator, source, &destination),

        // rgb565 -> Grayscale
        conversionId(.rgb565, .grayscale1) => RgbColorToGrayscale(.rgb565, .grayscale1).convert(source, &destination),
        conversionId(.rgb565, .grayscale2) => RgbColorToGrayscale(.rgb565, .grayscale2).convert(source, &destination),
        conversionId(.rgb565, .grayscale4) => RgbColorToGrayscale(.rgb565, .grayscale4).convert(source, &destination),
        conversionId(.rgb565, .grayscale8) => RgbColorToGrayscale(.rgb565, .grayscale8).convert(source, &destination),
        conversionId(.rgb565, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgb565, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgb565, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgb565, .grayscale16Alpha).convert(source, &destination),

        // rgb565 -> RGB + Colorf32
        conversionId(.rgb565, .rgb332) => RgbColorToRgbColor(.rgb565, .rgb332).convert(source, &destination),
        conversionId(.rgb565, .rgb555) => RgbColorToRgbColor(.rgb565, .rgb555).convert(source, &destination),
        conversionId(.rgb565, .rgb24) => RgbColorToRgbColor(.rgb565, .rgb24).convert(source, &destination),
        conversionId(.rgb565, .rgba32) => RgbColorToRgbaColor(.rgb565, .rgba32).convert(source, &destination),
        conversionId(.rgb565, .bgr555) => RgbColorToRgbColor(.rgb565, .bgr555).convert(source, &destination),
        conversionId(.rgb565, .bgr24) => RgbColorToRgbColor(.rgb565, .bgr24).convert(source, &destination),
        conversionId(.rgb565, .bgra32) => RgbColorToRgbaColor(.rgb565, .bgra32).convert(source, &destination),
        conversionId(.rgb565, .rgb48) => RgbColorToRgbColor(.rgb565, .rgb48).convert(source, &destination),
        conversionId(.rgb565, .rgba64) => RgbColorToRgbaColor(.rgb565, .rgba64).convert(source, &destination),
        conversionId(.rgb565, .float32) => rgbColorToColorf32(.rgb565, source, &destination),

        // rgb24 -> Indexed
        conversionId(.rgb24, .indexed1) => try RgbColorToIndexed(.rgb24, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgb24, .indexed2) => try RgbColorToIndexed(.rgb24, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgb24, .indexed4) => try RgbColorToIndexed(.rgb24, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgb24, .indexed8) => try RgbColorToIndexed(.rgb24, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgb24, .indexed16) => try RgbColorToIndexed(.rgb24, .indexed16).convert(allocator, source, &destination),

        // rgb24 -> Grayscale
        conversionId(.rgb24, .grayscale1) => RgbColorToGrayscale(.rgb24, .grayscale1).convert(source, &destination),
        conversionId(.rgb24, .grayscale2) => RgbColorToGrayscale(.rgb24, .grayscale2).convert(source, &destination),
        conversionId(.rgb24, .grayscale4) => RgbColorToGrayscale(.rgb24, .grayscale4).convert(source, &destination),
        conversionId(.rgb24, .grayscale8) => RgbColorToGrayscale(.rgb24, .grayscale8).convert(source, &destination),
        conversionId(.rgb24, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgb24, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgb24, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgb24, .grayscale16Alpha).convert(source, &destination),

        // rgb24 -> RGB + Colorf32
        conversionId(.rgb24, .rgb332) => RgbColorToRgbColor(.rgb24, .rgb332).convert(source, &destination),
        conversionId(.rgb24, .rgb555) => RgbColorToRgbColor(.rgb24, .rgb555).convert(source, &destination),
        conversionId(.rgb24, .rgb565) => RgbColorToRgbColor(.rgb24, .rgb565).convert(source, &destination),
        conversionId(.rgb24, .rgba32) => RgbColorToRgbaColor(.rgb24, .rgba32).convert(source, &destination),
        conversionId(.rgb24, .bgr555) => RgbColorToRgbColor(.rgb24, .bgr555).convert(source, &destination),
        conversionId(.rgb24, .bgr24) => RgbColorToRgbColor(.rgb24, .bgr24).convert(source, &destination),
        conversionId(.rgb24, .bgra32) => RgbColorToRgbaColor(.rgb24, .bgra32).convert(source, &destination),
        conversionId(.rgb24, .rgb48) => RgbColorToRgbColor(.rgb24, .rgb48).convert(source, &destination),
        conversionId(.rgb24, .rgba64) => RgbColorToRgbaColor(.rgb24, .rgba64).convert(source, &destination),
        conversionId(.rgb24, .float32) => rgbColorToColorf32(.rgb24, source, &destination),

        // rgba32 -> Indexed
        conversionId(.rgba32, .indexed1) => try RgbColorToIndexed(.rgba32, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgba32, .indexed2) => try RgbColorToIndexed(.rgba32, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgba32, .indexed4) => try RgbColorToIndexed(.rgba32, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgba32, .indexed8) => try RgbColorToIndexed(.rgba32, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgba32, .indexed16) => try RgbColorToIndexed(.rgba32, .indexed16).convert(allocator, source, &destination),

        // rgba32 -> Grayscale
        conversionId(.rgba32, .grayscale1) => RgbColorToGrayscale(.rgba32, .grayscale1).convert(source, &destination),
        conversionId(.rgba32, .grayscale2) => RgbColorToGrayscale(.rgba32, .grayscale2).convert(source, &destination),
        conversionId(.rgba32, .grayscale4) => RgbColorToGrayscale(.rgba32, .grayscale4).convert(source, &destination),
        conversionId(.rgba32, .grayscale8) => RgbColorToGrayscale(.rgba32, .grayscale8).convert(source, &destination),
        conversionId(.rgba32, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgba32, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgba32, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgba32, .grayscale16Alpha).convert(source, &destination),

        // rgba32 -> RGB + Colorf32
        conversionId(.rgba32, .rgb332) => RgbColorToRgbColor(.rgba32, .rgb332).convert(source, &destination),
        conversionId(.rgba32, .rgb555) => RgbaColorToRgbColor(.rgba32, .rgb555).convert(source, &destination),
        conversionId(.rgba32, .rgb565) => RgbaColorToRgbColor(.rgba32, .rgb565).convert(source, &destination),
        conversionId(.rgba32, .rgb24) => RgbaColorToRgbColor(.rgba32, .rgb24).convert(source, &destination),
        conversionId(.rgba32, .bgr555) => RgbaColorToRgbColor(.rgba32, .bgr555).convert(source, &destination),
        conversionId(.rgba32, .bgr24) => RgbaColorToRgbColor(.rgba32, .bgr24).convert(source, &destination),
        conversionId(.rgba32, .bgra32) => FastRgba32Shuffle(.rgba32, .bgra32).convert(source, &destination),
        conversionId(.rgba32, .rgb48) => RgbaColorToRgbColor(.rgba32, .rgb48).convert(source, &destination),
        conversionId(.rgba32, .rgba64) => RgbaColorToRgbaColor(.rgba32, .rgba64).convert(source, &destination),
        conversionId(.rgba32, .float32) => rgba32ToColorf32(.rgba32, source, &destination),

        // bgr555 -> Indexed
        conversionId(.bgr555, .indexed1) => try RgbColorToIndexed(.bgr555, .indexed1).convert(allocator, source, &destination),
        conversionId(.bgr555, .indexed2) => try RgbColorToIndexed(.bgr555, .indexed2).convert(allocator, source, &destination),
        conversionId(.bgr555, .indexed4) => try RgbColorToIndexed(.bgr555, .indexed4).convert(allocator, source, &destination),
        conversionId(.bgr555, .indexed8) => try RgbColorToIndexed(.bgr555, .indexed8).convert(allocator, source, &destination),
        conversionId(.bgr555, .indexed16) => try RgbColorToIndexed(.bgr555, .indexed16).convert(allocator, source, &destination),

        // bgr555 -> Grayscale
        conversionId(.bgr555, .grayscale1) => RgbColorToGrayscale(.bgr555, .grayscale1).convert(source, &destination),
        conversionId(.bgr555, .grayscale2) => RgbColorToGrayscale(.bgr555, .grayscale2).convert(source, &destination),
        conversionId(.bgr555, .grayscale4) => RgbColorToGrayscale(.bgr555, .grayscale4).convert(source, &destination),
        conversionId(.bgr555, .grayscale8) => RgbColorToGrayscale(.bgr555, .grayscale8).convert(source, &destination),
        conversionId(.bgr555, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.bgr555, .grayscale8Alpha).convert(source, &destination),
        conversionId(.bgr555, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.bgr555, .grayscale16Alpha).convert(source, &destination),

        // bgr555 -> RGB + Colorf32
        // TODO(ntr0): check if the conversions are correct
        conversionId(.bgr555, .rgb332) => RgbColorToRgbColor(.bgr555, .rgb332).convert(source, &destination),
        conversionId(.bgr555, .rgb555) => RgbColorToRgbColor(.rgb555, .rgb555).convert(source, &destination),
        conversionId(.bgr555, .rgb565) => RgbColorToRgbColor(.rgb555, .rgb565).convert(source, &destination),
        conversionId(.bgr555, .rgb24) => RgbColorToRgbColor(.rgb555, .rgb24).convert(source, &destination),
        conversionId(.bgr555, .rgba32) => RgbColorToRgbaColor(.rgb555, .rgba32).convert(source, &destination),
        conversionId(.bgr555, .bgr24) => RgbColorToRgbColor(.rgb555, .bgr24).convert(source, &destination),
        conversionId(.bgr555, .bgra32) => RgbColorToRgbaColor(.rgb555, .bgra32).convert(source, &destination),
        conversionId(.bgr555, .rgb48) => RgbColorToRgbColor(.rgb555, .rgb48).convert(source, &destination),
        conversionId(.bgr555, .rgba64) => RgbColorToRgbaColor(.rgb555, .rgba64).convert(source, &destination),
        conversionId(.bgr555, .float32) => rgbColorToColorf32(.rgb555, source, &destination),

        // bgr24 -> Indexed
        conversionId(.bgr24, .indexed1) => try RgbColorToIndexed(.bgr24, .indexed1).convert(allocator, source, &destination),
        conversionId(.bgr24, .indexed2) => try RgbColorToIndexed(.bgr24, .indexed2).convert(allocator, source, &destination),
        conversionId(.bgr24, .indexed4) => try RgbColorToIndexed(.bgr24, .indexed4).convert(allocator, source, &destination),
        conversionId(.bgr24, .indexed8) => try RgbColorToIndexed(.bgr24, .indexed8).convert(allocator, source, &destination),
        conversionId(.bgr24, .indexed16) => try RgbColorToIndexed(.bgr24, .indexed16).convert(allocator, source, &destination),

        // bgr24 -> Grayscale
        conversionId(.bgr24, .grayscale1) => RgbColorToGrayscale(.bgr24, .grayscale1).convert(source, &destination),
        conversionId(.bgr24, .grayscale2) => RgbColorToGrayscale(.bgr24, .grayscale2).convert(source, &destination),
        conversionId(.bgr24, .grayscale4) => RgbColorToGrayscale(.bgr24, .grayscale4).convert(source, &destination),
        conversionId(.bgr24, .grayscale8) => RgbColorToGrayscale(.bgr24, .grayscale8).convert(source, &destination),
        conversionId(.bgr24, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.bgr24, .grayscale8Alpha).convert(source, &destination),
        conversionId(.bgr24, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.bgr24, .grayscale16Alpha).convert(source, &destination),

        // bgr24 -> RGB + Colorf32
        conversionId(.bgr24, .rgb332) => RgbColorToRgbColor(.bgr24, .rgb332).convert(source, &destination),
        conversionId(.bgr24, .rgb555) => RgbColorToRgbColor(.bgr24, .rgb555).convert(source, &destination),
        conversionId(.bgr24, .rgb565) => RgbColorToRgbColor(.bgr24, .rgb565).convert(source, &destination),
        conversionId(.bgr24, .rgb24) => RgbColorToRgbColor(.bgr24, .rgb24).convert(source, &destination),
        conversionId(.bgr24, .rgba32) => RgbColorToRgbaColor(.bgr24, .rgba32).convert(source, &destination),
        conversionId(.bgr24, .bgr555) => RgbColorToRgbColor(.bgr24, .bgr555).convert(source, &destination),
        conversionId(.bgr24, .bgra32) => RgbColorToRgbaColor(.bgr24, .bgra32).convert(source, &destination),
        conversionId(.bgr24, .rgb48) => RgbColorToRgbColor(.bgr24, .rgb48).convert(source, &destination),
        conversionId(.bgr24, .rgba64) => RgbColorToRgbaColor(.bgr24, .rgba64).convert(source, &destination),
        conversionId(.bgr24, .float32) => rgbColorToColorf32(.bgr24, source, &destination),

        // bgra32 -> Indexed
        conversionId(.bgra32, .indexed1) => try RgbColorToIndexed(.bgra32, .indexed1).convert(allocator, source, &destination),
        conversionId(.bgra32, .indexed2) => try RgbColorToIndexed(.bgra32, .indexed2).convert(allocator, source, &destination),
        conversionId(.bgra32, .indexed4) => try RgbColorToIndexed(.bgra32, .indexed4).convert(allocator, source, &destination),
        conversionId(.bgra32, .indexed8) => try RgbColorToIndexed(.bgra32, .indexed8).convert(allocator, source, &destination),
        conversionId(.bgra32, .indexed16) => try RgbColorToIndexed(.bgra32, .indexed16).convert(allocator, source, &destination),

        // bgra32 -> Grayscale
        conversionId(.bgra32, .grayscale1) => RgbColorToGrayscale(.bgra32, .grayscale1).convert(source, &destination),
        conversionId(.bgra32, .grayscale2) => RgbColorToGrayscale(.bgra32, .grayscale2).convert(source, &destination),
        conversionId(.bgra32, .grayscale4) => RgbColorToGrayscale(.bgra32, .grayscale4).convert(source, &destination),
        conversionId(.bgra32, .grayscale8) => RgbColorToGrayscale(.bgra32, .grayscale8).convert(source, &destination),
        conversionId(.bgra32, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.bgra32, .grayscale8Alpha).convert(source, &destination),
        conversionId(.bgra32, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.bgra32, .grayscale16Alpha).convert(source, &destination),

        // bgra32 -> RGB + Colorf32
        conversionId(.bgra32, .rgb332) => RgbColorToRgbColor(.bgra32, .rgb332).convert(source, &destination),
        conversionId(.bgra32, .rgb555) => RgbaColorToRgbColor(.bgra32, .rgb555).convert(source, &destination),
        conversionId(.bgra32, .rgb565) => RgbaColorToRgbColor(.bgra32, .rgb565).convert(source, &destination),
        conversionId(.bgra32, .rgb24) => RgbaColorToRgbColor(.bgra32, .rgb24).convert(source, &destination),
        conversionId(.bgra32, .rgba32) => FastRgba32Shuffle(.bgra32, .rgba32).convert(source, &destination),
        conversionId(.bgra32, .bgr555) => RgbaColorToRgbColor(.bgra32, .bgr555).convert(source, &destination),
        conversionId(.bgra32, .bgr24) => RgbaColorToRgbColor(.bgra32, .bgr24).convert(source, &destination),
        conversionId(.bgra32, .rgb48) => RgbaColorToRgbColor(.bgra32, .rgb48).convert(source, &destination),
        conversionId(.bgra32, .rgba64) => RgbaColorToRgbaColor(.bgra32, .rgba64).convert(source, &destination),
        conversionId(.bgra32, .float32) => bgra32ToColorf32(.bgra32, source, &destination),

        // rgb48 -> Indexed
        conversionId(.rgb48, .indexed1) => try RgbColorToIndexed(.rgb48, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgb48, .indexed2) => try RgbColorToIndexed(.rgb48, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgb48, .indexed4) => try RgbColorToIndexed(.rgb48, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgb48, .indexed8) => try RgbColorToIndexed(.rgb48, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgb48, .indexed16) => try RgbColorToIndexed(.rgb48, .indexed16).convert(allocator, source, &destination),

        // rgb48 -> Grayscale
        conversionId(.rgb48, .grayscale1) => RgbColorToGrayscale(.rgb48, .grayscale1).convert(source, &destination),
        conversionId(.rgb48, .grayscale2) => RgbColorToGrayscale(.rgb48, .grayscale2).convert(source, &destination),
        conversionId(.rgb48, .grayscale4) => RgbColorToGrayscale(.rgb48, .grayscale4).convert(source, &destination),
        conversionId(.rgb48, .grayscale8) => RgbColorToGrayscale(.rgb48, .grayscale8).convert(source, &destination),
        conversionId(.rgb48, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgb48, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgb48, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgb48, .grayscale16Alpha).convert(source, &destination),

        // rgb48 -> RGB + Colorf32
        conversionId(.rgb48, .rgb332) => RgbColorToRgbColor(.rgb48, .rgb332).convert(source, &destination),
        conversionId(.rgb48, .rgb555) => RgbColorToRgbColor(.rgb48, .rgb555).convert(source, &destination),
        conversionId(.rgb48, .rgb565) => RgbColorToRgbColor(.rgb48, .rgb565).convert(source, &destination),
        conversionId(.rgb48, .rgb24) => RgbColorToRgbColor(.rgb48, .rgb24).convert(source, &destination),
        conversionId(.rgb48, .rgba32) => RgbColorToRgbaColor(.rgb48, .rgba32).convert(source, &destination),
        conversionId(.rgb48, .bgr555) => RgbColorToRgbColor(.rgb48, .bgr555).convert(source, &destination),
        conversionId(.rgb48, .bgr24) => RgbColorToRgbColor(.rgb48, .bgr24).convert(source, &destination),
        conversionId(.rgb48, .bgra32) => RgbColorToRgbaColor(.rgb48, .bgra32).convert(source, &destination),
        conversionId(.rgb48, .rgba64) => RgbColorToRgbaColor(.rgb48, .rgba64).convert(source, &destination),
        conversionId(.rgb48, .float32) => rgbColorToColorf32(.rgb48, source, &destination),

        // rgba64 -> Indexed
        conversionId(.rgba64, .indexed1) => try RgbColorToIndexed(.rgba64, .indexed1).convert(allocator, source, &destination),
        conversionId(.rgba64, .indexed2) => try RgbColorToIndexed(.rgba64, .indexed2).convert(allocator, source, &destination),
        conversionId(.rgba64, .indexed4) => try RgbColorToIndexed(.rgba64, .indexed4).convert(allocator, source, &destination),
        conversionId(.rgba64, .indexed8) => try RgbColorToIndexed(.rgba64, .indexed8).convert(allocator, source, &destination),
        conversionId(.rgba64, .indexed16) => try RgbColorToIndexed(.rgba64, .indexed16).convert(allocator, source, &destination),

        // rgba64 -> Grayscale
        conversionId(.rgba64, .grayscale1) => RgbColorToGrayscale(.rgba64, .grayscale1).convert(source, &destination),
        conversionId(.rgba64, .grayscale2) => RgbColorToGrayscale(.rgba64, .grayscale2).convert(source, &destination),
        conversionId(.rgba64, .grayscale4) => RgbColorToGrayscale(.rgba64, .grayscale4).convert(source, &destination),
        conversionId(.rgba64, .grayscale8) => RgbColorToGrayscale(.rgba64, .grayscale8).convert(source, &destination),
        conversionId(.rgba64, .grayscale8Alpha) => RgbColorToGrayscaleAlpha(.rgba64, .grayscale8Alpha).convert(source, &destination),
        conversionId(.rgba64, .grayscale16Alpha) => RgbColorToGrayscaleAlpha(.rgba64, .grayscale16Alpha).convert(source, &destination),

        // rgba64 -> RGB + Colorf32
        conversionId(.rgba64, .rgb332) => RgbColorToRgbColor(.rgba64, .rgb332).convert(source, &destination),
        conversionId(.rgba64, .rgb555) => RgbaColorToRgbColor(.rgba64, .rgb555).convert(source, &destination),
        conversionId(.rgba64, .rgb565) => RgbaColorToRgbColor(.rgba64, .rgb565).convert(source, &destination),
        conversionId(.rgba64, .rgb24) => RgbaColorToRgbColor(.rgba64, .rgb24).convert(source, &destination),
        conversionId(.rgba64, .rgba32) => RgbaColorToRgbaColor(.rgba64, .rgba32).convert(source, &destination),
        conversionId(.rgba64, .bgr555) => RgbaColorToRgbColor(.rgba64, .bgr555).convert(source, &destination),
        conversionId(.rgba64, .bgr24) => RgbaColorToRgbColor(.rgba64, .bgr24).convert(source, &destination),
        conversionId(.rgba64, .bgra32) => RgbaColorToRgbColor(.rgba64, .bgra32).convert(source, &destination),
        conversionId(.rgba64, .rgb48) => RgbaColorToRgbColor(.rgba64, .rgb48).convert(source, &destination),
        conversionId(.rgba64, .float32) => rgbColorToColorf32(.rgba64, source, &destination),

        // Colorf32(float32) -> Indexed
        conversionId(.float32, .indexed1) => try RgbColorToIndexed(.float32, .indexed1).convert(allocator, source, &destination),
        conversionId(.float32, .indexed2) => try RgbColorToIndexed(.float32, .indexed2).convert(allocator, source, &destination),
        conversionId(.float32, .indexed4) => try RgbColorToIndexed(.float32, .indexed4).convert(allocator, source, &destination),
        conversionId(.float32, .indexed8) => try RgbColorToIndexed(.float32, .indexed8).convert(allocator, source, &destination),
        conversionId(.float32, .indexed16) => try RgbColorToIndexed(.float32, .indexed16).convert(allocator, source, &destination),

        // Colorf32(float32) -> Grayscale
        conversionId(.float32, .grayscale1) => colorf32ToGrayscale(.grayscale1, source, &destination),
        conversionId(.float32, .grayscale2) => colorf32ToGrayscale(.grayscale2, source, &destination),
        conversionId(.float32, .grayscale4) => colorf32ToGrayscale(.grayscale4, source, &destination),
        conversionId(.float32, .grayscale8) => colorf32ToGrayscale(.grayscale8, source, &destination),
        conversionId(.float32, .grayscale8Alpha) => colorf32ToGrayscaleAlpha(.grayscale8Alpha, source, &destination),
        conversionId(.float32, .grayscale16Alpha) => colorf32ToGrayscaleAlpha(.grayscale16Alpha, source, &destination),

        // Colorf32(float32) -> RGB
        conversionId(.float32, .rgb332) => colorf32ToRgbColor(.rgb332, source, &destination),
        conversionId(.float32, .rgb555) => colorf32ToRgbColor(.rgb555, source, &destination),
        conversionId(.float32, .rgb565) => colorf32ToRgbColor(.rgb565, source, &destination),
        conversionId(.float32, .rgb24) => colorf32ToRgbColor(.rgb24, source, &destination),
        conversionId(.float32, .rgba32) => colorf32ToRgba32(.rgba32, source, &destination),
        conversionId(.float32, .bgr555) => colorf32ToRgbColor(.bgr555, source, &destination),
        conversionId(.float32, .bgr24) => colorf32ToRgbColor(.bgr24, source, &destination),
        conversionId(.float32, .bgra32) => colorf32ToBgra32(.bgra32, source, &destination),
        conversionId(.float32, .rgb48) => colorf32ToRgbColor(.rgb48, source, &destination),
        conversionId(.float32, .rgba64) => colorf32ToRgbaColor(.rgba64, source, &destination),

        else => return Image.ConvertError.NoConversionAvailable,
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

// ========================
// Single color conversions
// ========================
fn rgbToRgb(comptime T: type, rgb: anytype) T {
    return T.from.color(rgb);
}

fn rgbToRgba(comptime T: type, rgb: anytype) T {
    return T.from.color(rgb);
}

fn rgbaToRgb(comptime T: type, rgba: anytype) T {
    return T.from.color(rgba.to.premultipliedAlpha());
}

fn rgbaToRgba(comptime T: type, rgba: anytype) T {
    return T.from.color(rgba);
}

fn grayscaleToGrayscale(comptime T: type, gray: anytype) T {
    const scaleValue = color.ScaleValue(std.meta.fieldInfo(T, .value).type);
    return .{ .value = scaleValue(gray.value) };
}

fn grayscaleAlphaToGrayscale(comptime T: type, gray: anytype) T {
    const toF32 = color.ScaleValue(f32);
    const scaleValue = color.ScaleValue(std.meta.fieldInfo(T, .value).type);
    return .{ .value = scaleValue(toF32(gray.value) * toF32(gray.alpha)) };
}

fn grayscaleAlphaToGrayscaleAlpha(comptime T: type, gray: anytype) T {
    const scaleValue = color.ScaleValue(std.meta.fieldInfo(T, .value).type);
    const scaleAlpha = color.ScaleValue(std.meta.fieldInfo(T, .alpha).type);
    return .{
        .value = scaleValue(gray.value),
        .alpha = scaleAlpha(gray.alpha),
    };
}

fn grayscaleToRgb(comptime T: type, gray: anytype) T {
    return T.from.grayscale(gray);
}

fn grayscaleToRgba(comptime T: type, gray: anytype) T {
    return T.from.grayscale(gray);
}

fn grayscaleAlphaToRgb(comptime T: type, gray: anytype) T {
    return T.from.grayscale(grayscaleAlphaToGrayscale(color.Grayscalef32, gray));
}

fn grayscaleAlphaToRgba(comptime T: type, gray: anytype) T {
    return T.from.grayscale(gray);
}

// ===================
// Indexed conversions
// ===================
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

fn IndexedLargeToSmall(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination: *color.PixelStorage) Image.ConvertError!void {
            const source_indexed = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_indexed = @field(destination, getFieldNameFromPixelFormat(destination_format));

            var quantizer = OctTreeQuantizer.init(allocator);
            defer quantizer.deinit();

            // First pass: read all color in the palette and fill in the quantizer
            for (source_indexed.palette) |entry| {
                quantizer.addColor(entry) catch |err| {
                    return switch (err) {
                        std.mem.Allocator.Error.OutOfMemory => std.mem.Allocator.Error.OutOfMemory,
                        else => Image.ConvertError.QuantizeError,
                    };
                };
            }

            // Make the palette
            const color_count: u32 = @as(u32, 1) << @as(u5, @truncate(destination_format.bitsPerChannel()));
            destination_indexed.palette = quantizer.makePalette(color_count, destination_indexed.palette);

            // Second pass: assign indices
            for (0..source_indexed.indices.len) |index| {
                destination_indexed.indices[index] = @truncate(quantizer.getPaletteIndex(source_indexed.palette[source_indexed.indices[index]]) catch return Image.ConvertError.QuantizeError);
            }
        }
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
        destination.float32[index] = source_indexed.palette[source_indexed.indices[index]].to.color(color.Colorf32);
    }
}

// =====================
// Grayscale convertions
// =====================
fn GrayscaleToGrayscale(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleToGrayscale(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleAlphaToGrayscale(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToGrayscale(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleAlphaToGrayscaleAlpha(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToGrayscaleAlpha(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleToRgb(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleToRgba(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleAlphaToRgbColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToRgb(destination_type, source_grayscale[index]);
            }
        }
    };
}

fn GrayscaleAlphaToRgbaColor(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const destination_type = @TypeOf(destination_pixels[0]);

            for (0..source_grayscale.len) |index| {
                destination_pixels[index] = grayscaleAlphaToRgba(destination_type, source_grayscale[index]);
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

fn GrayscaleToIndexed(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination: *color.PixelStorage) Image.ConvertError!void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));

            var quantizer = OctTreeQuantizer.init(allocator);
            defer quantizer.deinit();

            // First pass: read all pixels and fill in the quantizer
            for (source_grayscale) |pixel| {
                const rgba_pixel = grayscaleToRgb(color.Rgb24, pixel);

                quantizer.addColor(rgba_pixel) catch |err| {
                    return switch (err) {
                        std.mem.Allocator.Error.OutOfMemory => std.mem.Allocator.Error.OutOfMemory,
                        else => Image.ConvertError.QuantizeError,
                    };
                };
            }

            // Make the palette
            const color_count: u32 = @as(u32, 1) << @as(u5, @truncate(destination_format.bitsPerChannel()));
            destination_pixels.palette = quantizer.makePalette(color_count, destination_pixels.palette);

            // Second pass: assign indices
            for (0..source_grayscale.len) |index| {
                const rgba_pixel = grayscaleToRgb(color.Rgb24, source_grayscale[index]);

                destination_pixels.indices[index] = @truncate(quantizer.getPaletteIndex(rgba_pixel) catch return Image.ConvertError.QuantizeError);
            }
        }
    };
}

fn GrayscaleAlphaToIndexed(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination: *color.PixelStorage) Image.ConvertError!void {
            const source_grayscale = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));

            var quantizer = OctTreeQuantizer.init(allocator);
            defer quantizer.deinit();

            // First pass: read all pixels and fill in the quantizer
            for (source_grayscale) |pixel| {
                const rgba_pixel = grayscaleAlphaToRgba(color.Rgba32, pixel);

                quantizer.addColor(rgba_pixel) catch |err| {
                    return switch (err) {
                        std.mem.Allocator.Error.OutOfMemory => std.mem.Allocator.Error.OutOfMemory,
                        else => Image.ConvertError.QuantizeError,
                    };
                };
            }

            // Make the palette
            const color_count: u32 = @as(u32, 1) << @as(u5, @truncate(destination_format.bitsPerChannel()));
            destination_pixels.palette = quantizer.makePalette(color_count, destination_pixels.palette);

            // Second pass: assign indices
            for (0..source_grayscale.len) |index| {
                const rgba_pixel = grayscaleAlphaToRgba(color.Rgba32, source_grayscale[index]);

                destination_pixels.indices[index] = @truncate(quantizer.getPaletteIndex(rgba_pixel) catch return Image.ConvertError.QuantizeError);
            }
        }
    };
}

// =====================
// RGB color conversions
// =====================
fn RgbColorToGrayscale(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const DestinationType = @TypeOf(destination_pixels[0]);

            const scaleValue = color.ScaleValue(std.meta.fieldInfo(DestinationType, .value).type);

            for (0..source_rgb.len) |index| {
                const source_float4 = source_rgb[index].to.float4();

                const converted_float4 = GrayscaleFactors * source_float4;

                const grayscale = scaleValue(
                    (converted_float4[0] + converted_float4[1] + converted_float4[2]) * converted_float4[3],
                );

                destination_pixels[index] = .{ .value = grayscale };
            }
        }
    };
}

fn RgbColorToGrayscaleAlpha(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(source: *const color.PixelStorage, destination: *color.PixelStorage) void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
            const DestinationType = @TypeOf(destination_pixels[0]);

            const scaleValue = color.ScaleValue(std.meta.fieldInfo(DestinationType, .value).type);
            const scaleAlpha = color.ScaleValue(std.meta.fieldInfo(DestinationType, .alpha).type);

            for (0..source_rgb.len) |index| {
                const source_float4 = source_rgb[index].to.float4();

                const converted_float4 = GrayscaleFactors * source_float4;

                const grayscale = scaleValue(converted_float4[0] + converted_float4[1] + converted_float4[2]);

                destination_pixels[index] = DestinationType{
                    .value = grayscale,
                    .alpha = scaleAlpha(converted_float4[3]),
                };
            }
        }
    };
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
        destination.float32[index] = source_rgb[index].to.color(color.Colorf32);
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
                const vector_source = simd.load(u8, std.mem.sliceAsBytes(source_pixels[index..]), VectorType, vector_length);

                const shuffled = @shuffle(u8, vector_source, undefined, shuffle_mask);

                simd.store(u8, std.mem.sliceAsBytes(destination_pixels[index..]), shuffled, vector_length);

                index += color_count;
            }

            // Process the rest sequentially
            while (index < source_pixels.len) : (index += 1) {
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
        const source_vector = simd.load(u8, std.mem.sliceAsBytes(source_pixels[index..]), ByteVectorType, vector_length);

        const float_vector = simd.intToFloat(f32, source_vector, vector_length);
        const conversion_vector: FloatVectorType = @splat(255.0);

        const destination_vector = float_vector / conversion_vector;

        simd.store(f32, destination_f32[(index * 4)..(index * 4 + color_count * 4)], destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) : (index += 1) {
        destination_pixels[index] = source_pixels[index].to.color(color.Colorf32);
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
        const source_vector = simd.load(u8, std.mem.sliceAsBytes(source_pixels[index..]), ByteVectorType, vector_length);

        const shuffled = @shuffle(u8, source_vector, undefined, shuffle_mask);

        const float_vector = simd.intToFloat(f32, shuffled, vector_length);
        const conversion_vector: FloatVectorType = @splat(255.0);

        const destination_vector = float_vector / conversion_vector;

        simd.store(f32, destination_f32[(index * 4)..(index * 4 + color_count * 4)], destination_vector, vector_length);

        index += color_count;
    }

    // Process the rest sequentially
    while (index < source_pixels.len) : (index += 1) {
        destination_pixels[index] = source_pixels[index].to.color(color.Colorf32);
    }
}

fn RgbColorToIndexed(comptime source_format: PixelFormat, comptime destination_format: PixelFormat) type {
    return struct {
        pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination: *color.PixelStorage) Image.ConvertError!void {
            const source_rgb = @field(source, getFieldNameFromPixelFormat(source_format));
            var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));

            var quantizer = OctTreeQuantizer.init(allocator);
            defer quantizer.deinit();

            // First pass: read all pixels and fill in the quantizer
            for (source_rgb) |pixel| {
                quantizer.addColor(pixel) catch |err| {
                    return switch (err) {
                        std.mem.Allocator.Error.OutOfMemory => std.mem.Allocator.Error.OutOfMemory,
                        else => Image.ConvertError.QuantizeError,
                    };
                };
            }

            // Make the palette
            const color_count: u32 = @as(u32, 1) << @as(u5, @truncate(destination_format.bitsPerChannel()));
            destination_pixels.palette = quantizer.makePalette(color_count, destination_pixels.palette);

            // Second pass: assign indices
            for (0..source_rgb.len) |index| {
                destination_pixels.indices[index] = @truncate(quantizer.getPaletteIndex(source_rgb[index]) catch return Image.ConvertError.QuantizeError);
            }
        }
    };
}

// ====================================
// Colorf32 (float32) color conversions
// ====================================
fn colorf32ToRgb(comptime T: type, source: color.Colorf32) T {
    return T.from.color(source);
}

fn colorf32ToRgba(comptime T: type, source: color.Colorf32) T {
    return T.from.color(source);
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
    while (index < source_pixels.len) : (index += 1) {
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
    while (index < source_pixels.len) : (index += 1) {
        destination_pixels[index] = colorf32ToRgba(destination_type, source_pixels[index]);
    }
}

fn colorf32ToGrayscale(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const DestinationType = @TypeOf(destination_pixels[0]);

    const scaleValue = color.ScaleValue(std.meta.fieldInfo(DestinationType, .value).type);

    for (0..source_pixels.len) |index| {
        const source_float4 = source_pixels[index].to.float4();

        const converted_float4 = GrayscaleFactors * source_float4;

        const grayscale = scaleValue(
            (converted_float4[0] + converted_float4[1] + converted_float4[2]) * converted_float4[3],
        );

        destination_pixels[index] = DestinationType{ .value = grayscale };
    }
}

fn colorf32ToGrayscaleAlpha(comptime destination_format: PixelFormat, source: *const color.PixelStorage, destination: *color.PixelStorage) void {
    const source_pixels = source.float32;

    var destination_pixels = @field(destination, getFieldNameFromPixelFormat(destination_format));
    const DestinationType = @TypeOf(destination_pixels[0]);

    const scaleValue = color.ScaleValue(std.meta.fieldInfo(DestinationType, .value).type);
    const scaleAlpha = color.ScaleValue(std.meta.fieldInfo(DestinationType, .alpha).type);

    for (0..source_pixels.len) |index| {
        const source_float4 = source_pixels[index].to.float4();

        const converted_float4 = GrayscaleFactors * source_float4;

        const grayscale = scaleValue(converted_float4[0] + converted_float4[1] + converted_float4[2]);

        destination_pixels[index] = DestinationType{
            .value = grayscale,
            .alpha = scaleAlpha(converted_float4[3]),
        };
    }
}
