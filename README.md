# Zig Image library

This is a work in progress library to create, process, read and write different image formats with [Zig](https://ziglang.org/) programming language.

![License](https://img.shields.io/github/license/zigimg/zigimg) ![Issue](https://img.shields.io/github/issues-raw/zigimg/zigimg?style=flat) ![Commit](https://img.shields.io/github/last-commit/zigimg/zigimg) ![CI](https://github.com/zigimg/zigimg/workflows/CI/badge.svg)

[![Join our Discord!](https://discordapp.com/api/guilds/1161009516771549374/widget.png?style=banner2)](https://discord.gg/TYgEEuEGnK)

## Install & Build

This library currently uses zig [0.14.1](https://ziglang.org/download/), we do plan to go back to using mach nominated zig until a newer version than 0.14.1 will be nominated.

### Use zigimg in your project

How to add to your project:

#### As a submodule

1. Clone this repository or add as a submodule
1. Add to your `build.zig`
```
pub fn build(b: *std.Build) void {
    exe.root_module.addAnonymousModule("zigimg", .{ .root_source_file = b.path("zigimg.zig") });
}
```

#### Through the package manager

1. Run this command in your project folder to add `zigimg` to your `build.zig.zon`

```sh
zig fetch --save git+https://github.com/zigimg/zigimg.git
```

2. Get the module in your `build.zig` file

```zig
const zigimg_dependency = b.dependency("zigimg", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zigimg", zigimg_dependency.module("zigimg"));
```

After you are done setting up, you can look at the user guide below.

## Test suite

To run the test suite, checkout the [test suite](https://github.com/zigimg/test-suite) and run

1. Checkout zigimg
1. Go back one folder and checkout the [test suite](https://github.com/zigimg/test-suite) 
1. Run the tests with `zig build`
```
zig build test
```

## Supported image formats

| Image Format  | Read          | Write          |
| ------------- |:-------------:|:--------------:|
| ANIM          | ❌            | ❌            |
| BMP           | ✔️ (Partial)  | ✔️ (Partial)  |
| Farbfeld      | ✔️            | ✔️            |
| GIF           | ✔️            | ❌            |
| ICO           | ❌            | ❌            |
| IFF           | ✔️            | ❌            |
| JPEG          | ✔️ (Partial)  | ❌            |
| PAM           | ✔️            | ✔️            |
| PBM           | ✔️            | ✔️            |
| PCX           | ✔️            | ✔️            |
| PGM           | ✔️ (Partial)  | ✔️ (Partial)  |
| PNG           | ✔️            | ✔️ (Partial)  |
| PPM           | ✔️ (Partial)  | ✔️ (Partial)  |
| QOI           | ✔️            | ✔️            |
| SGI           | ✔️            | ❌            |
| SUN           | ✔️            | ❌            |
| TGA           | ✔️            | ✔️            |
| TIFF          | ✔️ (Partial)  | ❌            |
| XBM           | ❌            | ❌            |
| XPM           | ❌            | ❌            |

### BMP - Bitmap

* version 4 BMP
* version 5 BMP
* 24-bit RGB read & write
* 32-bit RGBA read & write
* Doesn't support any compression

### GIF - Graphics Interchange Format

* Support GIF87a and GIF89a
* Support animated GIF with Netscape application extension for looping information
* Supports interlaced
* Supports tiled and layered images used to achieve pseudo true color and more.
* The plain text extension is not supported

### IFF - InterchangeFileFormat

 * Supports 1-8 bit, 24 bit, HAM6/8, EHB ILBM files
 * Supports uncompressed, byterun 1 & 2 (Atari) compressed ILBM files
 * Supports PBM (Deluxe Paint DOS) encoded files
 * Supports ACBM (Amiga Basic) files
 * Color cycle chunks are ignored
 * Mask is not supported (skipped)

### JPEG - Joint Photographic Experts Group

 * 8-bit baseline and progressive

### PAM - Portable Arbitrary Map

Currently, this only supports a subset of PAMs where:
* The tuple type is official (see `man 5 pam`) or easily inferred (and by extension, depth is 4 or less)
* All the images in a sequence have the same dimensions and maxval (it is technically possible to support animations with different maxvals and tuple types as each `AnimationFrame` has its own `PixelStorage`, however, this is likely not expected by users of the library)
* Grayscale,
* Grayscale with alpha
* Rgb555
* Rgb24 and Rgba32
* Bgr24 and Bgra32
* Rgb48 and Rgba64

### PBM - Portable Bitmap format

* Everything is supported

### PCX - ZSoft Picture Exchange format

* Support monochrome, 4 color, 16 color and 256 color indexed images
* Support 24-bit RGB images

### PGM - Portable Graymap format

* Support 8-bit and 16-bit grayscale images
* 16-bit ascii grayscale loading not tested

### PNG - Portable Network Graphics

* Support all pixel formats supported by PNG (grayscale, grayscale+alpha, indexed, truecolor, truecolor with alpha) in 8-bit or 16-bit.
* Support the mininal chunks in order to decode the image.
* Can write all supported pixel formats but writing interlaced images is not supported yet.

### PPM - Portable Pixmap format

* Support 24-bit RGB (8-bit per channel)
* Missing 48-bit RGB (16-bit per channel)

### QOI - Quite OK Image format

* Imported from https://github.com/MasterQ32/zig-qoi with blessing of the author

### SGI - Silicon Graphics Image

* Supports 8-bit, RGB (24/48-bit), RGBA(32/64-bit) files
* Supports RLE and uncompressed files

### SUN - Sun Raster format

* Supports 1/8/24/32-bit files
* Supports uncompressed & RLE files
* Supports BGR/RGB encoding
* TIFF/IFF/Experimental encoding is not supported

### TGA - Truevision TGA format

* Supports uncompressed and compressed 8-bit grayscale, indexed with 16-bit and 24-bit colormap, truecolor with 16-bit(RGB555), 24-bit or 32-bit bit depth.
* Supports reading version 1 and version 2
* Supports writing version 2

### TIFF - Tagged Image File Format

#### What's supported:
* bilevel, grayscale, palette and RGB(A) files
* most _baseline_ tags
* Raw, LZW, Deflate, PackBits, CCITT 1D files
* big-endian (MM) and little-endian (II) files should both be decoded fine

#### What's missing:
* Tile-based files are not supported
* YCbCr, CMJN and CIE Lab files are not supported
* JPEG, CCITT Fax 3 / 4 are not supported yet

#### Notes
* Only the first IFD is decoded
* Orientation tag is not supported yet

## Supported Pixel formats

* **Indexed**: 1bpp (bit per pixel), 2bpp, 4bpp, 8bpp, 16bpp
* **Grayscale**: 1bpp, 2bpp, 4bpp, 8bpp, 16bpp, 8bpp with alpha, 16bpp with alpha
* **Truecolor**: RGB332, RGB555, RGB565, RGB24 (8-bit per channel), RGBA32 (8-bit per channel), BGR555, BGR24 (8-bit per channel), BGRA32 (8-bit per channel), RGB48 (16-bit per channel), RGBA64 (16-bit per channel)
* **float**: 32-bit float RGBA, this is the neutral format.

# User Guide

## Design philosophy

zigimg offers color and image functionality. The library is designed around either using the convenient `Image` (or `ImageUnmanaged`) struct that can read and write image formats no matter the format.

Or you can also use the image format directly in case you want to extract more data from the image format. So if you find that `Image` does not give you the information that you need from a PNG or other format, you can use the PNG format albeit with a more manual API that `Image` hide from you.

## `Image` vs `ImageUnmanaged`

`Image` bundle a memory allocator and `ImageUnmanaged` does not. Similar to `std.ArrayList()` and `std.ArrayListUnmanaged()` in Zig standard library. For all the examples we are going to use `Image` but it is similar with `ImageUnmanaged`. 

## Read an image

It is pretty straightforward to read an image using the `Image` struct.

### From a file

You can use either a file path

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var image = try zigimg.Image.fromFilePath(allocator, "my_image.png");
    defer image.deinit();

    // Do something with your image
}
```

or a `std.fs.File` directly

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var image = try zigimg.Image.fromFile(allocator, file);
    defer image.deinit();

    // Do something with your image
}
```

### From memory

```zig
const std = @import("std");
const zigimg = @import("zigimg");

const image_data = @embedFile("test.bmp");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const image = try zigimg.Image.fromMemory(allocator, image_data[0..]);
    defer image.deinit();

    // Do something with your image
}
```

## Accessing pixel data

For a single image, they are two ways to get access to the pixel data.

### Accessing a specific format directly

You can access the pixel data directly using `Image.pixels`. `pixels` is an union of all supported pixel formats.

For RGB pixel formats, just use the pixel format enum value and addresss the data directly.
```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const first_pixel = image.pixels.rgb24[0];
}
```

For grayscale formats, you need to use .value to get the grayscale value. It can also contain the alpha value if you use the grayscale with alpha.

```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const first_pixel = image.pixels.grayscale8Alpha[0];
    const grayscale = first_pixel.value;
    const alpha = grayscale.alpha;
}
```

For indexed formats, you need to first access the union value then either the indices or the palette. The palette color are stored in the `Rgba32` pixel format.

```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const first_color_palette = image.pixels.indexed8.palette[0];
    const first_pixel = image.pixels.indexed8.indices[0];
}
```

If you want to know the current pixel format use `Image.pixelFormat()`.

### Using the color iterator

You can use the iterator to get each pixel as the universal `Colorf32` pixel format. (32-bit floating ploint RGBA)

```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const color_it = image.iterator();

    while (color_it.next()) |color| {
        // Do something with color
    }
}
```

### Accessing animation frames

In the case of an `Image` containing multiple frames, you can use `Image.animation` to get access to the animation information. Use `Image.animation.frames` to access each indivial frame. Each frame contain the pixel data and a frame duration in seconds (32-bit floating point).

`Image.pixels` will always point to the first frame of an animation also.

```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const loop_count = image.animation.loop_count;

    for (image.animation.frames) |frame| {
        const rgb24_data = frame.pixels.rgb24;
        const frame_duration = frame.duration;
    }
}
```

### Get raw bytes for texture transfer

`Image` has helper functions to help you get the right data to upload your image to the GPU.

```zig
pub fn example() void {
    // [...]
    // Assuming you already have an image loaded

    const image_data = image.rawBytes();
    const row_pitch = image.rowByteSize();
    const image_byte_size = image.imageByteSize();
}
```

## Detect image format

You can query the image format used by a file or a memory buffer.

### From a file

You can use either a file path

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    const image_format = try zigimg.Image.detectFormatFromFilePath(allocator, "my_image.png");

    // Will print png
    std.log.debug("Image format: {}", .{image_format});
}
```

or a `std.fs.File` directly

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("my_image.gif", .{});
    defer file.close();

    const image_format = try zigimg.Image.detectFormatFromFile(allocator, file);

    // Will print gif
    std.log.debug("Image format: {}", .{image_format});
}
```

### From memory

```zig
const std = @import("std");
const zigimg = @import("zigimg");

const image_data = @embedFile("test.bmp");

pub fn main() !void {
    const image_format = try zigimg.Image.detectFormatFromMemory(allocator, image_data[0..]);

    // Will print bmp
    std.log.debug("Image format: {}", .{image_format});
}
```

## Write an image

Each 3 functions to write an image take a union of encoder options for the target format. To know the actual options you'll need to consult the source code. The active tag of the union determine the target format, not the file extension.

### Write to a file path

```zig
pub fn example() !void {
    // [...]
    // Assuming you already have an image loaded

    try image.writeToFilePath("my_new_image.png", .{ .png = .{} });

    // Or with encoder options
    try image.writeToFilePath("my_new_image.png", .{ .png = .{ .interlaced = true } });
}
```

### Write to `std.fs.File`

```zig
pub fn example() !void {
    // [...]
    // Assuming you already have an image loaded and the file already created

    try image.writeToFile(file, .{ .bmp = .{} });
}
```

### Write to a memory buffer

Ensure that you have enough place in your buffer before calling `writeToMemory()`

```zig
pub fn example() !void {
    // [...]
    // Assuming you already have an image loaded and the buffer already allocated

    try image.writeToMemory(buffer[0..], .{ .tga = .{} });
}
```

## Create an image

Use `Image.create()` and pass the width, height and the pixel format that you want.

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var image = try zigimg.Image.create(allocator, 1920, 1080, .rgba32);
    defer image.deinit();

    // Do something with your image
}
```

## Interpret raw pixels

If you are not dealing with a image format, you can import your pixel data using `Image.fromRawPixels()`. It will create a copy of the pixels data. If you want the image to take ownership or just pass the data along to write it to a image format, use `ImageUnmanaged.fromRawPixelsOwned()`.

Using `fromRawPixel()`:
```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const my_raw_pixels = @embedData("raw_bgra32.bin");

    var image = try zigimg.Image.fromRawPixels(allocator, 1920, 1080, my_raw_pixels[0..], .bgra32);
    defer image.deinit();

    // Do something with your image
}
```

Using `fromRawPixelsOwned()`:
```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const my_raw_pixels = @embedData("raw_bgra32.bin");

    var image = try zigimg.ImageUnmanaged.fromRawPixelsOwned(1920, 1080, my_raw_pixels[0..], .bgra32);

    // Do something with your image
}
```

## Use image format directly

In the case you want more direct access to the image format, all the image formats are accessible from the `zigimg` module. However, you'll need to do a bit more manual steps in order to retrieve the pixel data.

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const image_data = @embedFile("windows_rgba_v5.bmp");

    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(image_data) };

    var bmp = zigimg.formats.bmp.BMP{};

    const pixels = try bmp.read(allocator, &stream_source);
    defer pixels.deinit(allocator);

    std.log.info("BMP info header: {}", .{bmp.info_header});
}
```

For the curious, the program above generate the following output:
```
info: BMP info header: src.formats.bmp.BitmapInfoHeader{ .v5 = src.formats.bmp.BitmapInfoHeaderV5{ .header_size = 124, .width = 240, .height = 160, .color_plane = 1, .bit_count = 32, .compression_method = src.formats.bmp.CompressionMethod.bitfields, .image_raw_size = 153600, .horizontal_resolution = 2835, .vertical_resolution = 2835, .palette_size = 0, .important_colors = 0, .red_mask = 16711680, .green_mask = 65280, .blue_mask = 255, .alpha_mask = 4278190080, .color_space = src.formats.bmp.BitmapColorSpace.srgb, .cie_end_points = src.formats.bmp.CieXyzTriple{ .red = src.formats.bmp.CieXyz{ ... }, .green = src.formats.bmp.CieXyz{ ... }, .blue = src.formats.bmp.CieXyz{ ... } }, .gamma_red = 0, .gamma_green = 0, .gamma_blue = 0, .intent = src.formats.bmp.BitmapIntent.graphics, .profile_data = 0, .profile_size = 0, .reserved = 0 } }
```

## Convert between pixel formats

You can use `Image.convert()` to convert between pixel formats. It will allocate the new pixel data and free the old one for you. It supports conversion from and to any pixel format. When converting down to indexed format, no dithering is done.

```zig
pub fn example() !void {
    // [...]
    // Assuming you already have an image loaded

    try image.convert(.float32);
}
```

### PixelFormatConverter

If you prefer, you can use `PixelFormatConverter` directly.

```zig
pub fn example(allocator: std.mem.Allocator) !void {
    const indexed2_pixels = try zigimg.color.PixelStorage.init(allocator, .indexed2, 4);
    defer indexed2_pixels.deinit(allocator);

    // [...] Setup your indexed2 pixel data

    const bgr24_pixels = try zigimg.PixelFormatConverter.convert(allocator, &indexed2_pixels, .bgr24);
    defer bgr24_pixels.deinit(allocator);
}
```

### OctTreeQuantizer

If you prefer more granular control to create an indexed image, you can use the `OctTreeQuantizer` directly.

```zig
pub fn example(allocator: std.mem.Allocator) !void {
    const image_data = @embedFile("windows_rgba_v5.bmp");

    var image = try zigimg.Image.fromMemory(allocator, image_data[0..]);
    defer image.deinit();

    var quantizer = zigimg.OctTreeQuantizer.init(allocator);
    defer quantizer.deinit();

    var color_it = image.iterator();

    while (color_it.next()) |pixel| {
        try quantizer.addColor(pixel);
    }

    var palette_storage: [256]zigimg.color.Rgba32 = undefined;
    const palette = quantizer.makePalette(255, palette_storage[0..]);

    const palette_index = try quantizer.getPaletteIndex(zigimg.color.Rgba32.from.rgba(110, 0, 0, 255));
}
```

## Get a color from a HTML hex string

You can get a color from a HTML hex string. The alpha component is always last. It also supports the shorthand version.

```zig
pub fn example() !void {
    const rgb24 = try zigimg.color.Rgb24.from.htmlHex("#123499");
    const rgba32 = try zigimg.color.Rgba32.from.htmlHex("FF000045");

    const red_rgb24 = try zigimg.color.Rgb24.from.htmlHex("#F00");
    const blue_rgba32 = try zigimg.color.Rgba32.from.htmlHex("#00FA");
}
```

## Predefined colors

You can access predefined colors for any pixel format using `Colors()`.

```zig
const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    const red_float32 = zigimg.Colors(zigimg.color.Colorf32).Red;
    const blue_rgb24 = zigimg.Colors(zigimg.color.Rgb24).Blue;
}
```

## Color management & color space

While zigimg does not support ICC profile yet (see #36) it does support a variety of color models and color spaces. All color space and color model are done in 32-bit floating point. So if you are not using `Colorf32` / `float32` as your pixel format, you'll need to convert to that format first.

The following device-dependent color model are supported:
* HSL (Hue, Saturation, Luminance)
* HSV (Hue, Saturation, Value) or also known as HSB (Hue, Saturation, Brightness)
* CMYK (Cyan-Magenta-Yellow-Black)

The following device-inpendent color spaces are supported, with or without alpha:
* CIE XYZ
* CIE Lab
* CIE LCh(ab), the cylindral representation of CIE Lab
* CIE Luv
* CIE LCh(uv), the cylindral representation of CIE Luv
* [HSLuv](https://www.hsluv.org/), a HSL representation of CIE LCh(uv) which is a cylindrical representation of CIE Luv color space
* [Oklab](https://bottosson.github.io/posts/oklab/)
* Oklch, the cylindrical representation of Oklab

### Convert between linear and gamma-corrected color

All color space transformation are done assuming a linear version of the color. To convert between gamma-converted and linear, you need to use any RGB colorspace and then call `toGamma()` or `toLinear()`, in this example I'm using both `sRGB` and `BT709` (aka Rec.709).

You can use either the accurate version or the fast version. For example the sRGB transfer function is linear below a threshold and an exponent curve above the threshold but the fast version will use the approximate exponent curve for the whole range.

```zig
pub fn example(linear_color: zigimg.color.Colorf32) {
    const gamma_srgb = zigimg.color.sRGB.toGamma(linear_color);
    const gamma_bt709 = zigimg.color.BT709.toGammaFast(linear_color);

    const linear_srgb = zigimg.color.sRGB.toLinearFast(gamma_srgb);
    const linear_bt709 = zigimg.color.BT709.toLinear(gamma_bt609);
}
```

### Convert a single color to a different color space

To convert to a device independant color space, you need first to use a reference RGB color space. Usually the most common for computer purposes is `sRGB`. Then each RGB colorspace has functions to convert from and to various color spaces. They support both non-alpha and alpha of the color space.

To a color space:
```zig
pub fn example(linear_color: zigimg.color.Colorf32) void {
    const xyz = zigimg.color.sRGB.toXYZ(linear_color);
    const lab_alpha = zigimg.color.sRGB.toLabAlpha(linear_color);
    const lch_ab = zigimg.color.sRGB.toLCHab(linear_color);
    const luv_alpha = zigimg.color.sRGB.toLuvAlpha(linear_color);
    const lch_uv = zigimg.color.sRGB.toLCHuv(linear_color);
    const hsluv = zigimg.color.sRGB.toHSLuv(linear_color);
    const oklab = zigimg.color.sRGB.toOklab(linear_color);
    const oklch = zigimg.color.sRGB.toOkLCh(linear_color);
}
```

When converting from a color space to a RGB color space, you need to specify if you want the color to be clamped inside the RGB colorspace or not because the resulting color could be outside of the RGB color space.
```zig
pub fn example(oklab: zigimg.color.Oklab) {
    const linear_srgb_clamped = zigimg.color.sRGB.fromOklab(oklab, .clamp);
    const linear_srgb = zigimg.color.sRGB.fromOklab(oklab, .none);
}
```

### Convert a slice of color to a different color space

Converting each pixel individually will be tedious if you want to use image processing on the CPU. Almost all color space conversion offer
an slice in-place conversion or a slice copy conversion. The in-place will reuse the same memory but interpret the color data differently. When you are conversion from a color space to a RGB color space, you need to specify if you want clamping or not.

Those conversions are only available with the alpha version of each color space.

```zig
pub fn exampleInPlace(linear_srgb_image: []zigimg.color.Colorf32) void {
    const slice_lab_alpha = zigimg.color.sRGB.sliceToLabAlphaInPlace(linear_srgb_image);

    // Do your image manipulation in CIE L*a*b*

    // Convert back to linear sRGB
    _ = zigimg.color.sRGB.sliceFromLabAlphaInPlace(slice_lab_alpha, .clamp);

    // or without clamping
     _ = zigimg.color.sRGB.sliceFromLabAlphaInPlace(slice_lab_alpha, .none);
}

pub fn exampleCopy(allocator: std.mem.Allocator, linear_srgb_image: []const zigimg.color.Colorf32) ![]zigimg.color.Colorf32 {
    const slice_oklab_alpha = try zigimg.color.sRGB.sliceToOklabCopy(allocator, linear_srgb_image);

    // Do your image manipulatioon in Oklab

    // Convert back to linear sRGB
    return try zigimg.color.sRGB.sliceFromOklabCopy(allocator, slice_oklab_alpha, .clamp);

    // Or without clamping
    return try zigimg.color.sRGB.sliceFromOklabCopy(allocator, slice_oklab_alpha, .none);
}
```

### Convert between some cylindrical representation

CIE Lab, CIE Luv and Oklab have cylindrical representation of their color space, each color has functions to convert from and to the cylindrical version.

```zig
pub fn example() void {
    const lab = zigimg.color.CIELab{ .l = 0.12, .a = -0.23, .b = 0.56 };
    const luv_alpha = zigimg.color.CIELuvAlpha { .l = 0.4, .u = 0.5, .v = -0.2, .alpha = 0.8 };
    const oklab = zigimg.color.Oklab{ .l = 0.67, .a = 0.1, .b = 0.56 };

    const lch_ab = lab.toLCHab();
    const lch_uv_alpha = luv_alpha.toLCHuvAlpha();
    const oklch = oklab.toOkLCh();

    const result_lab = lch_ab.toLab();
    const result_luv_alpha = lch_uv_alpha.toLuvAlpha();
    const result_oklab = oklch.toOklab();
}
```

### Convert color between RGB color spaces

To convert a single color, use the `convertColor()` function on the `RgbColorspace` struct:
```zig
pub fn example(linear_color: zigimg.color.Colorf32) void {
    const pro_photo_color = zigimg.color.sRGB.convertColor(zigimg.color.ProPhotoRGB, linear_color);
}
```

If you want to convert a whole slice of pixels, use `convertColors()`, it will apply the conversion in-place:
```zig
pub fn example(linear_image: []zigimg.color.Colorf32) void {
    const adobe_image = zigimg.color.sRGB.convertColors(zigimg.color.AdobeRGB, linear_image);
}
```

If the target RGB colorspace have a different white point, it will do the [chromatic adapdation](http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html) for you using the Bradford method.

### Predefined RGB color spaces

Here the list of predefined RGB color spaces, all accessible from `zigimg.color` struct:

* `BT601_NTSC`
* `BT601_PAL`
* `BT709`
* `sRGB`
* `DCIP3.Display`
* `DCIP3.Theater`
* `DCIP3.ACES`
* `BT2020`
* `AdobeRGB`
* `AdobeWideGamutRGB`
* `ProPhotoRGB`

### Predefined white points

All predefined white point are accessed with `zigimg.color.WhitePoints`. All the standard illuminants are defined there.

### Create your own RGB color space

You can create your own RGB color space using `zigimg.color.RgbColorspace.init()`. Each coordinate is in the 2D version of the CIE xyY color space.

If you don't care about linear and gamma conversion, just ignore those functions in the init struct.

```zig
fn myColorSpaceToGamma(value: f32) f32 {
    return std.math.pow(f32, value, 1.0 / 2.4);
}

fn myColorSpaceToLinear(value: f32) f32 {
    return std.math.pow(f32, value, 2.4);
}

pub fn example() void {
    pub const my_color_space = zigimg.color.RgbColorspace.init(.{
        .red = .{ .x = 0.6400, .y = 0.3300 },
        .green = .{ .x = 0.3000, .y = 0.6000 },
        .blue = .{ .x = 0.1500, .y = 0.0600 },
        .white = zigimg.color.WhitePoints.D50,
        .to_gamma = myColorSpaceToGamma,
        .to_gamma_fast = myColorSpaceToGamma,
        .to_linear = myColorSpaceToLinear,
        .to_linear_fast = myColorSpaceToLinear,
    });
}
```
