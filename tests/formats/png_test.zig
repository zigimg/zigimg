// const assert = std.debug.assert;
// const testing = std.testing;

const std = @import("std");
const helpers = @import("../helpers.zig");
const png = @import("../../src/formats/png.zig");
const types = @import("../../src/formats/png/types.zig");
const color = @import("../../src/color.zig");
const Image = @import("../../src/Image.zig");
const ImageUnmanaged = @import("../../src/ImageUnmanaged.zig");
const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const InfoProcessor = @import("../../src/formats/png/InfoProcessor.zig");
const ImageReadError = Image.ReadError;
const expectError = std.testing.expectError;
const magic_header = types.magic_header;

const valid_header_data = magic_header ++ "\x00\x00\x00\x0d" ++ png.Chunks.IHDR.name ++
    "\x00\x00\x00\xff\x00\x00\x00\x75\x08\x06\x00\x00\x01\xf6\x24\x07\xe2";

test "Should error on non PNG images" {
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "bmp/simple_v4.bmp");
    defer file.close();

    var stream_source = std.Io.StreamSource{ .file = file };

    const invalidFile = png.PNG.readImage(helpers.zigimg_test_allocator, &stream_source);

    try helpers.expectError(invalidFile, ImageReadError.InvalidData);
}

test "loadHeader_valid" {
    const expectEqual = std.testing.expectEqual;
    var buffer = valid_header_data.*;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(&buffer) };
    const header = try png.loadHeader(&stream);
    try expectEqual(@as(u32, 0xff), header.width);
    try expectEqual(@as(u32, 0x75), header.height);
    try expectEqual(@as(u8, 8), header.bit_depth);
    try expectEqual(png.ColorType.rgba_color, header.color_type);
    try expectEqual(png.CompressionMethod.deflate, header.compression_method);
    try expectEqual(png.FilterMethod.adaptive, header.filter_method);
    try expectEqual(png.InterlaceMethod.adam7, header.interlace_method);
}

test "PNG loadHeader() should error when data is empty" {
    var buffer: [0]u8 = undefined;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(&buffer) };
    try expectError(Image.ReadError.EndOfStream, png.loadHeader(&stream));
}

test "PNG loadHeader() should error when header signature is invalid" {
    var buffer = "asdsdasdasdsads".*;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(&buffer) };
    try expectError(Image.ReadError.InvalidData, png.loadHeader(&stream));
}

test "PNG loadHeader() should error on bad header chunk" {
    var buffer = (magic_header ++ "\x00\x00\x01\x0d" ++ png.Chunks.IHDR.name ++ "asad").*;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(&buffer) };
    try expectError(Image.ReadError.InvalidData, png.loadHeader(&stream));
}

test "PNG loadHeader() should error when header is too short" {
    var buffer = (magic_header ++ "\x00\x00\x00\x0d" ++ png.Chunks.IHDR.name ++ "asad").*;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(&buffer) };
    try expectError(Image.ReadError.EndOfStream, png.loadHeader(&stream));
}

test "PNG loadHeader() should error on invalid data in header" {
    var buffer = valid_header_data.*;
    var position = magic_header.len + @sizeOf(types.ChunkHeader);

    try testHeaderWithInvalidValue(buffer[0..], position, 0xf0); // width highest bit is 1
    position += 3;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x00); // width is 0
    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0xf0); // height highest bit is 1
    position += 3;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x00); // height is 0

    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x00); // invalid bit depth
    try testHeaderWithInvalidValue(buffer[0..], position, 0x07); // invalid bit depth
    try testHeaderWithInvalidValue(buffer[0..], position, 0x03); // invalid bit depth
    try testHeaderWithInvalidValue(buffer[0..], position, 0x04); // invalid bit depth for rgba color type
    try testHeaderWithInvalidValue(buffer[0..], position, 0x02); // invalid bit depth for rgba color type
    try testHeaderWithInvalidValue(buffer[0..], position, 0x01); // invalid bit depth for rgba color type
    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x01); // invalid color type
    try testHeaderWithInvalidValue(buffer[0..], position, 0x05);
    try testHeaderWithInvalidValue(buffer[0..], position, 0x07);
    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x01); // invalid compression method
    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x01); // invalid filter method
    position += 1;
    try testHeaderWithInvalidValue(buffer[0..], position, 0x02); // invalid interlace method
}

fn testHeaderWithInvalidValue(buf: []u8, position: usize, val: u8) !void {
    const origin = buf[position];
    buf[position] = val;
    var stream = Image.Stream{ .buffer = std.Io.fixedBufferStream(buf) };
    try expectError(Image.ReadError.InvalidData, png.loadHeader(&stream));
    buf[position] = origin;
}

test "png: Indexed PNG with transparency (Aseprite output)" {
    // mlarouche: While the full test suite already test this image, I like having a smaller test that I can verify
    // some specific info myself
    const file = try helpers.testOpenFile(helpers.fixtures_path ++ "png/aseprite_indexed_transparent.png");
    defer file.close();

    var stream_source = std.Io.StreamSource{ .file = file };

    var png_image = try png.PNG.readImage(helpers.zigimg_test_allocator, &stream_source);
    defer png_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(png_image.pixels == .indexed8);

    const pixels8_indexed = png_image.pixels.indexed8;

    try helpers.expectEq(pixels8_indexed.palette.len, 32);

    try helpers.expectEq(pixels8_indexed.palette[0].r, 0);
    try helpers.expectEq(pixels8_indexed.palette[0].g, 0);
    try helpers.expectEq(pixels8_indexed.palette[0].b, 0);
    try helpers.expectEq(pixels8_indexed.palette[0].a, 0);

    try helpers.expectEq(pixels8_indexed.palette[1].r, 0x22);
    try helpers.expectEq(pixels8_indexed.palette[1].g, 0x20);
    try helpers.expectEq(pixels8_indexed.palette[1].b, 0x34);
    try helpers.expectEq(pixels8_indexed.palette[1].a, 255);
}

pub const CheckTrnsPresentProcessor = struct {
    const Self = @This();

    present: bool = false,
    trns_processor: png.TrnsProcessor = .{},

    pub fn processor(self: *Self) png.ReaderProcessor {
        return png.ReaderProcessor.init(
            png.Chunks.tRNS.id,
            self,
            processChunk,
            processPalette,
            processDataRow,
        );
    }

    pub fn processChunk(self: *Self, data: *png.ChunkProcessData) ImageUnmanaged.ReadError!PixelFormat {
        self.present = true;
        return self.trns_processor.processChunk(data);
    }

    pub fn processPalette(self: *Self, data: *png.PaletteProcessData) ImageUnmanaged.ReadError!void {
        return self.trns_processor.processPalette(data);
    }

    pub fn processDataRow(self: *Self, data: *png.RowProcessData) ImageUnmanaged.ReadError!PixelFormat {
        return self.trns_processor.processDataRow(data);
    }
};

test "png: Don't write tRNS chunk in indexed format when there is no alpha" {
    var source_image = try Image.create(helpers.zigimg_test_allocator, 8, 1, .indexed8);
    defer source_image.deinit();

    source_image.pixels.indexed8.palette[0] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    source_image.pixels.indexed8.palette[1] = .{ .r = 255, .g = 255, .b = 255, .a = 255 };

    source_image.pixels.indexed8.indices[0] = 0;
    for (1..source_image.width) |index| {
        source_image.pixels.indexed8.indices[index] = 1;
    }

    const image_file_name = "zigimg_png_indexed_no_trns.png";
    try source_image.writeToFilePath(image_file_name, Image.EncoderOptions{
        .png = .{},
    });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var check_trns_processor: CheckTrnsPresentProcessor = .{};

    var processors: [1]png.ReaderProcessor = undefined;
    processors[0] = check_trns_processor.processor();

    const png_reader_options = png.ReaderOptions.initWithProcessors(helpers.zigimg_test_allocator, processors[0..]);

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, png_reader_options);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(!check_trns_processor.present);
}

test "png: Write tRNS chunk in indexed format only when alpha is present" {
    var source_image = try Image.create(helpers.zigimg_test_allocator, 8, 1, .indexed8);
    defer source_image.deinit();

    source_image.pixels.indexed8.palette[0] = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    source_image.pixels.indexed8.palette[1] = .{ .r = 255, .g = 255, .b = 255, .a = 255 };

    source_image.pixels.indexed8.indices[0] = 0;
    for (1..source_image.width) |index| {
        source_image.pixels.indexed8.indices[index] = 1;
    }

    const image_file_name = "zigimg_png_indexed_trns.png";
    try source_image.writeToFilePath(image_file_name, Image.EncoderOptions{
        .png = .{},
    });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var check_trns_processor: CheckTrnsPresentProcessor = .{};

    var processors: [1]png.ReaderProcessor = undefined;
    processors[0] = check_trns_processor.processor();

    const png_reader_options = png.ReaderOptions.initWithProcessors(helpers.zigimg_test_allocator, processors[0..]);

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, png_reader_options);
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(check_trns_processor.present);
}

test "png: Write indexed1 format" {
    const SOURCE_WIDTH = 477;
    const SOURCE_HEIGHT = 512;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .indexed1);
    defer source_image.deinit();

    for (0..2) |palette_index| {
        source_image.pixels.indexed1.palette[palette_index] = .{
            .r = @truncate(palette_index % 2),
            .g = @truncate(palette_index % 1),
            .b = 1,
            .a = 255,
        };
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.indexed1.indices[index] = @truncate(index % 2);
    }

    const image_file_name = "zigimg_png_indexed1.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .indexed1);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..2) |palette_index| {
        try helpers.expectEq(read_image.pixels.indexed1.palette[palette_index].r, @as(u8, @truncate(palette_index % 2)));
        try helpers.expectEq(read_image.pixels.indexed1.palette[palette_index].g, @as(u8, @truncate(palette_index % 1)));
        try helpers.expectEq(read_image.pixels.indexed1.palette[palette_index].b, 1);
        try helpers.expectEq(read_image.pixels.indexed1.palette[palette_index].a, 255);
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.indexed1.indices[index], @as(u1, @truncate(index % 2)));
    }
}

test "png: Write indexed2 format" {
    const SOURCE_WIDTH = 467;
    const SOURCE_HEIGHT = 524;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .indexed2);
    defer source_image.deinit();

    for (0..4) |palette_index| {
        source_image.pixels.indexed2.palette[palette_index] = .{
            .r = @truncate(palette_index % 4),
            .g = @truncate(palette_index % 2),
            .b = @truncate(palette_index % 1),
            .a = 255,
        };
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.indexed2.indices[index] = @truncate(index % 4);
    }

    const image_file_name = "zigimg_png_indexed2.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .indexed2);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..4) |palette_index| {
        try helpers.expectEq(read_image.pixels.indexed2.palette[palette_index].r, @as(u8, @truncate(palette_index % 4)));
        try helpers.expectEq(read_image.pixels.indexed2.palette[palette_index].g, @as(u8, @truncate(palette_index % 2)));
        try helpers.expectEq(read_image.pixels.indexed2.palette[palette_index].b, @as(u8, @truncate(palette_index % 1)));
        try helpers.expectEq(read_image.pixels.indexed2.palette[palette_index].a, 255);
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.indexed2.indices[index], @as(u2, @truncate(index % 4)));
    }
}

test "png: Write indexed4 format" {
    const SOURCE_WIDTH = 513;
    const SOURCE_HEIGHT = 486;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .indexed4);
    defer source_image.deinit();

    for (0..16) |palette_index| {
        source_image.pixels.indexed4.palette[palette_index] = .{
            .r = @truncate(palette_index % 16),
            .g = @truncate(palette_index % 8),
            .b = @truncate(palette_index % 4),
            .a = 255,
        };
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.indexed4.indices[index] = @truncate(index % 16);
    }

    const image_file_name = "zigimg_png_indexed4.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .indexed4);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..16) |palette_index| {
        try helpers.expectEq(read_image.pixels.indexed4.palette[palette_index].r, @as(u8, @truncate(palette_index % 16)));
        try helpers.expectEq(read_image.pixels.indexed4.palette[palette_index].g, @as(u8, @truncate(palette_index % 8)));
        try helpers.expectEq(read_image.pixels.indexed4.palette[palette_index].b, @as(u8, @truncate(palette_index % 4)));
        try helpers.expectEq(read_image.pixels.indexed4.palette[palette_index].a, 255);
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.indexed4.indices[index], @as(u4, @truncate(index % 16)));
    }
}

test "png: Write indexed8 format" {
    const SOURCE_WIDTH = 513;
    const SOURCE_HEIGHT = 612;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .indexed8);
    defer source_image.deinit();

    for (0..256) |index| {
        source_image.pixels.indexed8.palette[index] = .{
            .r = @truncate(index % 256),
            .g = @truncate(index % 128),
            .b = @truncate(index % 64),
            .a = 255,
        };
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.indexed8.indices[index] = @truncate(index % 256);
    }

    const image_file_name = "zigimg_png_indexed8.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .indexed8);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..256) |palette_index| {
        try helpers.expectEq(read_image.pixels.indexed8.palette[palette_index].r, @as(u8, @truncate(palette_index % 256)));
        try helpers.expectEq(read_image.pixels.indexed8.palette[palette_index].g, @as(u8, @truncate(palette_index % 128)));
        try helpers.expectEq(read_image.pixels.indexed8.palette[palette_index].b, @as(u8, @truncate(palette_index % 64)));
        try helpers.expectEq(read_image.pixels.indexed8.palette[palette_index].a, 255);
    }

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.indexed8.indices[index], @as(u8, @truncate(index % 256)));
    }
}

test "png: Write grayscale1 format" {
    const SOURCE_WIDTH = 479;
    const SOURCE_HEIGHT = 534;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale1);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale1[index].value = @truncate(index % 2);
    }

    const image_file_name = "zigimg_png_grayscale1.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale1);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale1[index].value, @as(u1, @truncate(index % 2)));
    }
}

test "png: Write grayscale2 format" {
    const SOURCE_WIDTH = 457;
    const SOURCE_HEIGHT = 568;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale2);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale2[index].value = @truncate(index % 4);
    }

    const image_file_name = "zigimg_png_grayscale2.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale2);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale2[index].value, @as(u2, @truncate(index % 4)));
    }
}

test "png: Write grayscale4 format" {
    const SOURCE_WIDTH = 457;
    const SOURCE_HEIGHT = 568;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale4);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale4[index].value = @truncate(index % 16);
    }

    const image_file_name = "zigimg_png_grayscale4.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale4);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale4[index].value, @as(u4, @truncate(index % 16)));
    }
}

test "png: Write grayscale8 format" {
    const SOURCE_WIDTH = 502;
    const SOURCE_HEIGHT = 457;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale8);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale8[index].value = @truncate(index % 256);
    }

    const image_file_name = "zigimg_png_grayscale8.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale8);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale8[index].value, @as(u8, @truncate(index % 256)));
    }
}

test "png: Write grayscale8Alpha format" {
    const SOURCE_WIDTH = 567;
    const SOURCE_HEIGHT = 612;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale8Alpha);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale8Alpha[index].value = @truncate(index % 256);
        source_image.pixels.grayscale8Alpha[index].alpha = @truncate(index % 256);
    }

    const image_file_name = "zigimg_png_grayscale8Alpha.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale8Alpha);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale8Alpha[index].value, @as(u8, @truncate(index % 256)));
        try helpers.expectEq(read_image.pixels.grayscale8Alpha[index].alpha, @as(u8, @truncate(index % 256)));
    }
}

test "png: Write grayscale16 format" {
    const SOURCE_WIDTH = 534;
    const SOURCE_HEIGHT = 567;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale16);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale16[index].value = @truncate(index % 65535);
    }

    const image_file_name = "zigimg_png_grayscale16.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale16);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale16[index].value, @as(u16, @truncate(index % 65535)));
    }
}

test "png: Write grayscale16Alpha format" {
    const SOURCE_WIDTH = 467;
    const SOURCE_HEIGHT = 658;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .grayscale16Alpha);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.grayscale16Alpha[index].value = @truncate(index % 65535);
        source_image.pixels.grayscale16Alpha[index].alpha = @truncate(index % 65535);
    }

    const image_file_name = "zigimg_png_grayscale16Alpha.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .grayscale16Alpha);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.grayscale16Alpha[index].value, @as(u16, @truncate(index % 65535)));
        try helpers.expectEq(read_image.pixels.grayscale16Alpha[index].alpha, @as(u16, @truncate(index % 65535)));
    }
}

test "png: Write rgb24 format" {
    const SOURCE_WIDTH = 512;
    const SOURCE_HEIGHT = 512;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .rgb24);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.rgb24[index].r = @truncate(index % 256);
        source_image.pixels.rgb24[index].g = @truncate(index % 128);
        source_image.pixels.rgb24[index].b = @truncate(index % 64);
    }

    const image_file_name = "zigimg_png_rgb24.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .rgb24);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.rgb24[index].r, @as(u8, @truncate(index % 256)));
        try helpers.expectEq(read_image.pixels.rgb24[index].g, @as(u8, @truncate(index % 128)));
        try helpers.expectEq(read_image.pixels.rgb24[index].b, @as(u8, @truncate(index % 64)));
    }
}

test "png: Write rgba32 format" {
    const SOURCE_WIDTH = 470;
    const SOURCE_HEIGHT = 327;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .rgba32);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.rgba32[index].r = @truncate(index % 256);
        source_image.pixels.rgba32[index].g = @truncate(index % 128);
        source_image.pixels.rgba32[index].b = @truncate(index % 64);
        source_image.pixels.rgba32[index].a = @truncate(index % 256);
    }

    const image_file_name = "zigimg_png_rgba32.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .rgba32);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.rgba32[index].r, @as(u8, @truncate(index % 256)));
        try helpers.expectEq(read_image.pixels.rgba32[index].g, @as(u8, @truncate(index % 128)));
        try helpers.expectEq(read_image.pixels.rgba32[index].b, @as(u8, @truncate(index % 64)));
        try helpers.expectEq(read_image.pixels.rgba32[index].a, @as(u8, @truncate(index % 256)));
    }
}

test "png: Write rgb48 format" {
    const SOURCE_WIDTH = 453;
    const SOURCE_HEIGHT = 217;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .rgb48);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.rgb48[index].r = @truncate(index % 65535);
        source_image.pixels.rgb48[index].g = @truncate(index % 32767);
        source_image.pixels.rgb48[index].b = @truncate(index % 21845);
    }

    const image_file_name = "zigimg_png_rgb48.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .rgb48);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.rgb48[index].r, @as(u16, @truncate(index % 65535)));
        try helpers.expectEq(read_image.pixels.rgb48[index].g, @as(u16, @truncate(index % 32767)));
        try helpers.expectEq(read_image.pixels.rgb48[index].b, @as(u16, @truncate(index % 21845)));
    }
}

test "png: Write rgba64 format" {
    const SOURCE_WIDTH = 556;
    const SOURCE_HEIGHT = 464;

    var source_image = try Image.create(helpers.zigimg_test_allocator, SOURCE_WIDTH, SOURCE_HEIGHT, .rgba64);
    defer source_image.deinit();

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        source_image.pixels.rgba64[index].r = @truncate(index % 65535);
        source_image.pixels.rgba64[index].g = @truncate(index % 32767);
        source_image.pixels.rgba64[index].b = @truncate(index % 21845);
        source_image.pixels.rgba64[index].a = @truncate(index % 65535);
    }

    const image_file_name = "zigimg_png_rgba64.png";
    try source_image.writeToFilePath(image_file_name, .{ .png = .{} });
    defer {
        std.fs.cwd().deleteFile(image_file_name) catch {};
    }

    const read_file = try helpers.testOpenFile(image_file_name);
    defer read_file.close();

    var stream_source = std.Io.StreamSource{ .file = read_file };

    var options = png.DefaultOptions.init(.{});

    var read_image = try png.load(&stream_source, helpers.zigimg_test_allocator, options.get());
    defer read_image.deinit(helpers.zigimg_test_allocator);

    try std.testing.expect(read_image.pixels == .rgba64);
    try helpers.expectEq(read_image.width, SOURCE_WIDTH);
    try helpers.expectEq(read_image.height, SOURCE_HEIGHT);

    for (0..(SOURCE_WIDTH * SOURCE_HEIGHT)) |index| {
        try helpers.expectEq(read_image.pixels.rgba64[index].r, @as(u16, @truncate(index % 65535)));
        try helpers.expectEq(read_image.pixels.rgba64[index].g, @as(u16, @truncate(index % 32767)));
        try helpers.expectEq(read_image.pixels.rgba64[index].b, @as(u16, @truncate(index % 21845)));
        try helpers.expectEq(read_image.pixels.rgba64[index].a, @as(u16, @truncate(index % 65535)));
    }
}

test "PNG Official Test Suite" {
    try testWithDir(helpers.fixtures_path ++ "png/", true);
}

// Useful to quickly test everything on full dir of images
pub fn testWithDir(directory: []const u8, testMd5Sig: bool) !void {
    var testdir = std.fs.cwd().openDir(directory, .{ .access_sub_paths = false, .no_follow = true, .iterate = true }) catch null;
    if (testdir) |*idir| {
        defer idir.close();
        var it = idir.iterate();
        if (testMd5Sig) std.debug.print("\n", .{});
        while (try it.next()) |entry| {
            if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.name), ".png")) continue;

            if (testMd5Sig) std.debug.print("Testing file {s} ... ", .{entry.name});
            var tst_file = try idir.openFile(entry.name, .{ .mode = .read_only });
            defer tst_file.close();
            var stream = Image.Stream{ .file = tst_file };
            if (entry.name[0] == 'x' and entry.name[2] != 't' and entry.name[2] != 's') {
                try std.testing.expectError(Image.ReadError.InvalidData, png.loadHeader(&stream));
                if (testMd5Sig) std.debug.print("OK\n", .{});
                continue;
            }

            var default_options = png.DefaultOptions.init(.{});
            var header = try png.loadHeader(&stream);
            if (entry.name[0] == 'x') {
                const error_result = png.loadWithHeader(&stream, &header, std.testing.allocator, default_options.get());
                try std.testing.expectError(Image.ReadError.InvalidData, error_result);
                if (testMd5Sig) std.debug.print("OK\n", .{});
                continue;
            }

            var result = try png.loadWithHeader(&stream, &header, std.testing.allocator, default_options.get());
            defer result.deinit(std.testing.allocator);

            if (!testMd5Sig) continue;

            const result_bytes = result.asBytes();
            var md5_val: [16]u8 = undefined;
            std.crypto.hash.Md5.hash(result_bytes, &md5_val, .{});

            const len = entry.name.len;
            var tst_data_name: [200]u8 = undefined;
            @memcpy(tst_data_name[0 .. len - 3], entry.name[0 .. len - 3]);
            @memcpy(tst_data_name[len - 3 .. len], "tsd");

            // Read test data and check with it
            if (idir.openFile(tst_data_name[0..len], .{ .mode = .read_only })) |tdata| {
                defer tdata.close();
                var treader = tdata.deprecatedReader();
                var expected_md5: [16]u8 = undefined;
                var read_buffer: [50]u8 = undefined;
                const str_format = try treader.readUntilDelimiter(read_buffer[0..], '\n');
                const expected_pixel_format = std.meta.stringToEnum(PixelFormat, str_format).?;
                const str_md5 = try treader.readUntilDelimiterOrEof(read_buffer[0..], '\n');
                _ = try std.fmt.hexToBytes(expected_md5[0..], str_md5.?);
                try std.testing.expectEqual(expected_pixel_format, std.meta.activeTag(result));
                try std.testing.expectEqualSlices(u8, expected_md5[0..], md5_val[0..]); // catch std.debug.print("MD5 Expected: {s} Got {s}\n", .{std.fmt.fmtSliceHexUpper(expected_md5[0..]), std.fmt.fmtSliceHexUpper(md5_val[0..])});
            } else |_| {
                // If there is no test data assume test is correct and write it out
                try writeTestData(idir, tst_data_name[0..len], &result, md5_val[0..]);
            }

            if (testMd5Sig) std.debug.print("OK\n", .{});

            // Write Raw bytes
            // std.mem.copyForwards(u8, tst_data_name[len - 3 .. len + 1], "data");
            // var rawoutput = try idir.createFile(tst_data_name[0 .. len + 1], .{});
            // defer rawoutput.close();
            // try rawoutput.writeAll(result_bytes);
        }
    }
}

fn writeTestData(dir: *std.fs.Dir, tst_data_name: []const u8, result: *color.PixelStorage, md5_val: []const u8) !void {
    var toutput = try dir.createFile(tst_data_name, .{});
    defer toutput.close();
    var writer = toutput.deprecatedWriter();
    try writer.print("{s}\n{X}", .{ @tagName(result.*), md5_val });
}

test "InfoProcessor on Png Test suite" {
    const directory = helpers.fixtures_path ++ "png/";

    var testdir = std.fs.cwd().openDir(directory, .{ .access_sub_paths = false, .no_follow = true, .iterate = true }) catch null;
    if (testdir) |*idir| {
        defer idir.close();
        var it = idir.iterate();

        var info_buffer: [16384]u8 = undefined;
        var info_stream = std.Io.StreamSource{ .buffer = std.Io.fixedBufferStream(info_buffer[0..]) };

        while (try it.next()) |entry| {
            if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.name), ".png")) {
                continue;
            }

            var options = InfoProcessor.PngInfoOptions.init(InfoProcessor.init(info_stream.writer()));

            var tst_file = try idir.openFile(entry.name, .{ .mode = .read_only });
            defer tst_file.close();
            var stream = Image.Stream{ .file = tst_file };
            if (entry.name[0] == 'x') {
                continue;
            }

            info_stream.buffer.reset();

            var result = try png.load(&stream, std.testing.allocator, options.get());
            defer result.deinit(helpers.zigimg_test_allocator);

            const len = entry.name.len + 1;
            var tst_data_name: [50]u8 = undefined;
            @memcpy(tst_data_name[0 .. len - 4], entry.name[0 .. len - 4]);
            @memcpy(tst_data_name[len - 4 .. len], "info");

            // Read test data and check with it
            if (idir.openFile(tst_data_name[0..len], .{ .mode = .read_only })) |tdata| {
                defer tdata.close();
                var expected_data_buffer: [16384]u8 = undefined;
                const loaded = try tdata.deprecatedReader().readAll(expected_data_buffer[0..]);
                try std.testing.expectEqualSlices(u8, expected_data_buffer[0..loaded], info_buffer[0..loaded]);
            } else |_| {
                // If there is no test data assume test is correct and write it out
                var toutput = try idir.createFile(tst_data_name[0..len], .{});
                defer toutput.close();
                var writer = toutput.deprecatedWriter();
                try writer.writeAll(info_buffer[0..info_stream.buffer.pos]);
            }
        }
    }
}
