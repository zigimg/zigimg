const std = @import("std");
const ImageUnmanaged = @import("ImageUnmanaged.zig");

pub const Error = std.mem.Allocator.Error;

/// Flip the image vertically, along the X axis.
pub fn flipVertically(image: *const ImageUnmanaged, allocator: std.mem.Allocator) Error!void {
    const row_size: usize = image.rowByteSize();
    var image_data = image.pixels.asBytes();

    const temp = try allocator.alloc(u8, row_size);
    defer allocator.free(temp);
    while (image_data.len > row_size) : (image_data = image_data[row_size..(image_data.len - row_size)]) {
        const row1_data = image_data[0..row_size];
        const row2_data = image_data[image_data.len - row_size .. image_data.len];
        @memcpy(temp, row1_data);
        @memcpy(row1_data, row2_data);
        @memcpy(row2_data, temp);
    }
}

/// Flip the image horizontally, along the Y axis.
pub fn flipHorizontally(image: *const ImageUnmanaged, allocator: std.mem.Allocator) Error!void {
    _ = image;
    _ = allocator;
}
