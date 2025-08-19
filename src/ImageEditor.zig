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
pub fn crop(image: *const ImageUnmanaged, allocator: std.mem.Allocator, crop_area: Box) Error!ImageUnmanaged {
    const box = crop_area.clamp(image.width, image.height);

    var cropped_pixels = try color.PixelStorage.init(
        allocator,
        image.pixelFormat(),
        box.width * box.height,
    );

    if (image.pixelFormat().isIndexed()) {
        const source_palette = image.pixels.getPalette().?;
        cropped_pixels.resizePalette(source_palette.len);

        const destination_palette = cropped_pixels.getPalette().?;

        @memcpy(destination_palette, source_palette);
    }

    if (box.width == 0 or box.height == 0 or
        image.width == 0 or image.height == 0)
    {
        return ImageUnmanaged{
            .width = box.width,
            .height = box.height,
            .pixels = cropped_pixels,
        };
    }

    const original_data = image.pixels.asBytes();
    const cropped_data = cropped_pixels.asBytes();
    const pixel_size = image.pixelFormat().pixelStride();
    std.debug.assert(cropped_data.len == box.width * box.height * pixel_size);

    var y: usize = 0;
    const row_byte_width = box.width * pixel_size;
    while (y < box.height) : (y += 1) {
        const start_pixel = (box.x * pixel_size) + ((y + box.y) * image.width * pixel_size);
        const source = original_data[start_pixel .. start_pixel + row_byte_width];
        const destination_pixel = y * row_byte_width;
        const destination = cropped_data[destination_pixel .. destination_pixel + row_byte_width];
        @memcpy(destination, source);
    }

    return ImageUnmanaged{
        .width = box.width,
        .height = box.height,
        .pixels = cropped_pixels,
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
    pub fn clamp(area: Box, image_width: usize, image_height: usize) Box {
        var box = area;
        if (box.x + box.width > image_width) box.width = image_width - box.x;
        if (box.y + box.height > image_height) box.height = image_height - box.y;
        return box;
    }
};
