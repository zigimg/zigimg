//! this module implements the JFIF header
//! specified in https://www.w3.org/Graphics/JPEG/jfif3.pdf

const std = @import("std");

const ImageUnmanaged = @import("../../ImageUnmanaged.zig");
const io = @import("../../io.zig");

const Markers = @import("./utils.zig").Markers;

const JFIFHeader = @This();

/// see https://www.ecma-international.org/wp-content/uploads/ECMA_TR-98_1st_edition_june_2009.pdf
/// chapt 10.
pub const DensityUnit = enum(u8) {
    pixels = 0,
    dots_per_inch = 1,
    dots_per_cm = 2,
};

jfif_revision: u16,
density_unit: DensityUnit,
x_density: u16,
y_density: u16,

pub fn read(read_stream: *io.ReadStream) !JFIFHeader {
    // Read the first APP0 header.
    const reader = read_stream.reader();
    try read_stream.seekTo(2);
    const maybe_app0_marker = try reader.takeInt(u16, .big);
    if (maybe_app0_marker != @intFromEnum(Markers.app0)) {
        return error.App0MarkerDoesNotExist;
    }

    // Header length
    _ = try reader.takeInt(u16, .big);

    const identifier_buffer = try reader.take(4);
    if (!std.mem.eql(u8, identifier_buffer[0..], "JFIF")) {
        return error.JfifIdentifierNotSet;
    }

    // NUL byte after JFIF
    try reader.discardAll(1);

    const jfif_revision = try reader.takeInt(u16, .big);
    const density_unit: DensityUnit = @enumFromInt(try reader.takeByte());
    const x_density = try reader.takeInt(u16, .big);
    const y_density = try reader.takeInt(u16, .big);

    const thumbnailWidth = try reader.takeByte();
    const thumbnailHeight = try reader.takeByte();

    if (thumbnailWidth != 0 or thumbnailHeight != 0) {
        // TODO: Support thumbnails (not important)
        return error.ThumbnailImagesUnsupported;
    }

    // Make sure there are no application markers after us.
    // TODO: Support application markers, present in versions 1.02 and above.
    // see https://www.ecma-international.org/wp-content/uploads/ECMA_TR-98_1st_edition_june_2009.pdf
    // chapt 10.1
    if (((try reader.takeInt(u16, .big)) & 0xFFF0) == @intFromEnum(Markers.app0)) {
        return error.ExtraneousApplicationMarker;
    }

    try read_stream.seekBy(-2);

    return JFIFHeader{
        .jfif_revision = jfif_revision,
        .density_unit = density_unit,
        .x_density = x_density,
        .y_density = y_density,
    };
}
