const std = @import("std");
const builtin = @import("builtin");
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const color = @import("../color.zig");
const utils = @import("../utils.zig");
const buffered_stream_source = @import("../buffered_stream_source.zig");

/// XBM is a monochrome bitmap format in which data is stored as a C language data array.
/// Primarily used for the storage of cursor and icon bitmaps for use in the X graphical user interface.
// In place of the usual image file format header, XBM files have two or four #define statements. The first two #defines specify the height and width of the bitmap in pixels. The second two specify the position of the hotspot within the bitmap, and are not present if no hotspot is defined in the image.
// The labels of each #define contain the name of the image. Consider an image that is 8x8 pixels in size, named FOO, with a hotspot at pixel 0,7. This image contains the following #define statements:
// #define FOO_width 8
// #define FOO_height 8
// #define FOO_x_hot 0
// #define FOO_y_hot 7
// The image data itself is a single line of pixel values stored in a static array. Data representing our FOO image appears as follows:
//
// Static unsigned char FOO_bits[] = {
// 0x3E, 0x80, 0x00, 0x7C, 0x00, 0x82, 0x41, 0x00};
//
// Because each pixel is only one bit in size, each byte in the array contains the information for eight pixels, with the first pixel in the bitmap (at position 0,0) represented by the high bit of the first byte in the array. If an image width is not a multiple of eight, the extra bits in the last byte of each row are not used and are ignored.
// XBM files are found in two variations: the older XI 0 format and the newer (as of 1986) XI 1 format. The only difference between these formats is how the pixel data is packed. The XI 1 flavor stores pixel data as 8-bit BYTEs. The older XI 0 flavor stores pixel data as 16-bit WORDs. There are no markers separating the rows of image data in either of these formats, and the size of an XBM array is limited only by the compiler and machine using the bitmap.
// The XI 0 XBM is considered obsolete. Make sure that any X software you write is able to read both the XBM XIO and XI 1 formats, but when you write data, use only the XI 1 XBM format.
pub const XBM = struct {
    width: u32 = 0,
    height: u32 = 0,
    hotspot_x: u32 = 0,
    hotspot_y: u32 = 0,

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    /// Takes a stream, Returns true if and only if the stream contains exactly two or four '#define' lines
    /// at the beginning.
    pub fn formatDetect(stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!bool {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        var define_buf: [64]u8 = undefined;
        var define_line_count: u32 = 0;
        var found_non_define = false;

        while (!found_non_define) {
            const line = try reader.readUntilDelimiterOrEof(&define_buf, '\n') orelse break;
            if (isDefineLine(line)) {
                define_line_count += 1;
            } else {
                found_non_define = true;
            }
        }

        return define_line_count == 2 or define_line_count == 4;
    }

    fn isDefineLine(line: []const u8) bool {
        return line.len >= 7 and std.mem.eql(u8, line[0..7], "#define");
    }

    fn parseDefineValue(line: []const u8) ?u32 {
        //  Split the line and take the last numeric token
        var it = std.mem.splitBackwardsAny(u8, line, " \t");
        const last_token = it.next();
        if (last_token) |token| {
            return std.fmt.parseInt(u32, token, 10) catch null;
        }
        return null;
    }

    fn collectHexBytes(line: []const u8, bytes: *std.ArrayList(u8)) !void {
        var it = std.mem.tokenizeAny(u8, line, ", \t\n{};");
        while (it.next()) |tok| {
            if (tok.len >= 2 and (tok[0] == '0' and (tok[1] == 'x' or tok[1] == 'X'))) {
                const val = std.fmt.parseInt(u32, tok[2..], 16) catch continue;
                if (val <= 0xFF) {
                    try bytes.append(@intCast(val));
                } else {
                    //  Older XI0 mode – 16-bit words, pack little-endian
                    try bytes.append(@intCast(val & 0xFF));
                    try bytes.append(@intCast((val >> 8) & 0xFF));
                }
            }
        }
    }

    pub fn read(self: *XBM, allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!color.PixelStorage {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);
        const reader = buffered_stream.reader();

        //  --- Parse #define lines ---
        var define_buf: [128]u8 = undefined;
        var width: ?u32 = null;
        var height: ?u32 = null;
        var hotspot_x: u32 = 0;
        var hotspot_y: u32 = 0;

        var first_pixel_line: []const u8 = &[_]u8{};
        var have_first_pixel_line = false;

        var line_opt = try reader.readUntilDelimiterOrEof(define_buf[0..], '\n');
        while (line_opt) |line_full| {
            const line = std.mem.trimRight(u8, line_full, " \r\n");
            if (isDefineLine(line)) {
                if (parseDefineValue(line)) |value| {
                    if (width == null) {
                        width = value;
                    } else if (height == null) {
                        height = value;
                    } else if (hotspot_x == 0) {
                        hotspot_x = value;
                    } else if (hotspot_y == 0) {
                        hotspot_y = value;
                    }
                } else {
                    return ImageUnmanaged.ReadError.InvalidData;
                }
            } else {
                //  Reached first non-define line – treat as pixel data
                first_pixel_line = line;
                have_first_pixel_line = true;
                break;
            }
            line_opt = try reader.readUntilDelimiterOrEof(define_buf[0..], '\n');
        }

        if (width == null or height == null) {
            return ImageUnmanaged.ReadError.InvalidData;
        }

        self.width = width.?;
        self.height = height.?;
        self.hotspot_x = hotspot_x;
        self.hotspot_y = hotspot_y;

        const pixel_count: usize = @as(usize, self.width) * @as(usize, self.height);
        var pixels = try color.PixelStorage.init(allocator, .indexed1, pixel_count);
        errdefer pixels.deinit(allocator);

        //  Prepare palette: 0 = white, 1 = black (common convention)
        pixels.indexed1.palette[0] = color.Rgba32.from.rgba(255, 255, 255, 255);
        pixels.indexed1.palette[1] = color.Rgba32.from.rgba(0, 0, 0, 255);

        //  --- Collect hex bytes ---
        var byte_list = std.ArrayList(u8).init(allocator);
        defer byte_list.deinit();

        const expected_bytes = (pixel_count + 7) / 8;
        try byte_list.ensureTotalCapacity(expected_bytes);

        if (have_first_pixel_line) {
            try collectHexBytes(first_pixel_line, &byte_list);
        }

        //  Read remaining lines till EOF and gather bytes
        while (true) {
            const l = try reader.readUntilDelimiterOrEof(define_buf[0..], '\n') orelse break;
            try collectHexBytes(l, &byte_list);
        }

        if (byte_list.items.len < expected_bytes) {
            return ImageUnmanaged.ReadError.InvalidData;
        }

        //  --- Decode bits into pixel indices ---
        //  XBM stores pixels LSB-first: the least-significant bit of the byte is the left-most pixel.
        const bytes_slice = byte_list.items;
        var idx: usize = 0;
        while (idx < pixel_count) : (idx += 1) {
            const byte_val = bytes_slice[idx / 8];
            const bit_pos: u3 = @intCast(idx & 7); // LSB -> leftmost
            const bit: u1 = @intCast((byte_val >> bit_pos) & 1);
            pixels.indexed1.indices[idx] = bit;
        }

        return pixels;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *ImageUnmanaged.Stream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result: ImageUnmanaged = .{};
        errdefer result.deinit(allocator);

        var xbm: XBM = .{};
        result.pixels = try xbm.read(allocator, stream);
        result.width = @intCast(xbm.width);
        result.height = @intCast(xbm.height);
        return result;
    }

    pub fn writeImage(
        _: std.mem.Allocator,
        _: *ImageUnmanaged.Stream,
        _: ImageUnmanaged,
        _: ImageUnmanaged.EncoderOptions,
    ) ImageUnmanaged.WriteError!void {}
};
