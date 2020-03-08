# Zig Image library

This is a work in progress library to create, process, read and write different image formats with [Zig](https://ziglang.org/) programming language.

![License](https://img.shields.io/github/license/mlarouche/zigimg) ![Issue](https://img.shields.io/github/issues-raw/mlarouche/zigimg?style=flat) ![Commit](https://img.shields.io/github/last-commit/mlarouche/zigimg) ![CI](https://github.com/mlarouche/zigimg/workflows/CI/badge.svg)

## Build

This project assume current Zig master (0.5.0+378bf1c3b). 

Build tests
```
zig build test
```

How to add to your project:
1. Clone this repository or add as a submodule
1. Add to your `build.zig`
```
exe.addPackagePath("zigimg", "zigimg/zigimg.zig");
```


## Supported image formats

| Image Format  | Read          | Write  |
| ------------- |:-------------:|:------:|
| ANIM          | ❌            |❌     |
| BMP           | ✔️ (Partial)  |❌     |
| GIF           | ❌            |❌     |
| ICO           | ❌            |❌     |
| IILBM         | ❌            |❌     |
| JPEG          | ❌            |❌     |
| PAM           | ❌            |❌     |
| PBM           | ✔️            |❌     |
| PCX           | ✔️            |❌     |
| PGM           | ✔️ (Partial)  |❌     |
| PNG           | ❌            |❌     |
| PPM           | ✔️ (Partial)  |❌     |
| TGA           | ❌            |❌     |
| TIFF          | ❌            |❌     |
| XBM           | ❌            |❌     |
| XPM           | ❌            |❌     |

### BMP - Bitmap

* version 4 BMP
* version 5 BMP
* 24-bit RGB
* 32 RGBA
* Doesn't support any compression

### PBM - Portable Bitmap format

* Everything is supported

### PCX - ZSoft Picture Exchange format

* Support monochrome, 4 color, 16 color and 256 color indexed images
* Support 24-bit RGB images

### PGM - Portable Graymap format

* Support 8-bit grayscale images
* Missing 16-bit grayscale support for now

### PPM - Portable Pixmap format

* Support 24-bit RGB (8-bit per channel)
* Missing 48-bit RGB (16-bit per channel)
