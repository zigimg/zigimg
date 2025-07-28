const std = @import("std");
pub const Error = std.mem.Allocator.Error;

const color = @import("color.zig");
const ImageUnmanaged = @import("ImageUnmanaged.zig");

/// Flip the image vertically, along the X axis.
pub fn flipVertically(pixels: *const color.PixelStorage, height: usize, allocator: std.mem.Allocator) Error!void {
    var image_data = pixels.asBytes();
    const row_size = image_data.len / height;

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

/// Create and allocate a cropped subsection of this image.
pub fn crop(
    image: *const ImageUnmanaged,
    crop_area: Box,
    allocator: std.mem.Allocator,
) Error!ImageUnmanaged {
    const box = crop_area.normalize(image.width, image.height);

    const new_buffer = try color.PixelStorage.init(
        allocator,
        image.pixelFormat(),
        box.width * box.height,
    );

    if (box.width == 0 or box.height == 0 or
        image.width == 0 or image.height == 0)
    {
        return ImageUnmanaged{
            .width = box.width,
            .height = box.height,
            .pixels = new_buffer,
        };
    }
    const original_data = image.pixels.asBytes();
    const new_data = new_buffer.asBytes();
    const pixel_size = original_data.len / image.height / image.width;
    std.debug.assert(new_data.len == box.width * box.height * pixel_size);

    var y: usize = 0;
    const row_byte_width = box.width * pixel_size;
    while (y < box.height) : (y += 1) {
        const start_pixel = (box.x * pixel_size) + ((y + box.y) * image.width * pixel_size);
        const src = original_data[start_pixel .. start_pixel + row_byte_width];
        const dest_pixel = y * row_byte_width;
        const dst = new_data[dest_pixel .. dest_pixel + row_byte_width];
        @memcpy(dst, src);
    }

    return ImageUnmanaged{
        .width = box.width,
        .height = box.height,
        .pixels = new_buffer,
    };
}

/// A box describes the region of an image to be extracted. The crop
/// box should be a subsection of the original image.
///
/// If any of the parameters fall outside of the physical dimensions
/// of the image, the parameters can be normalised. For example, if
/// it is attempted to crop an area wider then the source image, the
/// `width` will be normalised to the physical width of the image.
pub const Box = struct {
    x: usize = 0,
    y: usize = 0,
    width: usize = 0,
    height: usize = 0,

    /// If the crop area falls partially outside the image boundary,
    /// adjust the crop region.
    pub fn normalize(area: Box, image_width: usize, image_height: usize) Box {
        var box = area;
        if (box.x + box.width > image_width) box.width = image_width - box.x;
        if (box.y + box.height > image_height) box.height = image_height - box.y;
        return box;
    }
};
