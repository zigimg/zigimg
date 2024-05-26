const color = @import("color.zig");
const std = @import("std");

const PixelFormat = @import("pixel_format.zig").PixelFormat;

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

fn conversionId(source_format: PixelFormat, destination_format: PixelFormat) u64 {
    return @as(u64, @intFromEnum(source_format)) | @as(u64, @intFromEnum(destination_format)) << 32;
}

pub fn convert(allocator: std.mem.Allocator, source: *const color.PixelStorage, destination_format: PixelFormat) !color.PixelStorage {
    const pixel_count = source.len();

    var destination = try color.PixelStorage.init(allocator, destination_format, pixel_count);
    errdefer destination.deinit(allocator);

    const conversion_id = conversionId(std.meta.activeTag(source.*), destination_format);

    switch (conversion_id) {
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

        else => return error.NoConversionAvailable,
    }

    return destination;
}
