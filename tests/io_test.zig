const std = @import("std");
const helpers = @import("helpers.zig");
const zigimg = @import("zigimg");

const TEST_FILE_CONTENTS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

test "io.ReadStream: should read and seek properly within memory" {
    var read_stream = zigimg.io.ReadStream.initMemory(TEST_FILE_CONTENTS[0..]);

    var reader = read_stream.reader();

    const read_inside_buffer = try reader.take(3);
    try helpers.expectEq(read_stream.getPos(), 3);
    try helpers.expectEqSlice(u8, read_inside_buffer[0..3], TEST_FILE_CONTENTS[0..3]);

    try read_stream.seekTo(0);

    const read_beginning_again = try reader.take(3);
    try helpers.expectEqSlice(u8, read_beginning_again, read_inside_buffer);

    try read_stream.seekBy(-3);
    try helpers.expectEq(read_stream.getPos(), 0);

    try read_stream.seekBy(5);
    try helpers.expectEq(read_stream.getPos(), 5);

    try read_stream.seekBy(1);
    try helpers.expectEq(read_stream.getPos(), 6);

    const end_pos = try read_stream.getEndPos();
    try helpers.expectEq(end_pos, 36);

    const read_remaining = try reader.take(30);
    try helpers.expectEq(read_stream.getPos(), end_pos);
    try helpers.expectEqSlice(u8, read_remaining, TEST_FILE_CONTENTS[6..]);
}

test "io.ReadStream: should error on invalid seek within memory" {
    var read_stream = zigimg.io.ReadStream.initMemory(TEST_FILE_CONTENTS[0..]);

    const seek_to_error = read_stream.seekTo(123456);
    try helpers.expectError(seek_to_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_after_end_error = read_stream.seekBy(123456);
    try helpers.expectError(seek_by_after_end_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_before_error = read_stream.seekBy(-300);
    try helpers.expectError(seek_by_before_error, zigimg.io.ReadStream.SeekError.Unseekable);
}

test "io.ReadStream: should read and seek properly within a unbuffered file" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var read_stream = zigimg.io.ReadStream.initFile(read_file, &.{});

    var reader = read_stream.reader();

    var read_inside_buffer: [3]u8 = @splat(0);
    try reader.readSliceAll(read_inside_buffer[0..]);
    try helpers.expectEq(read_stream.getPos(), 3);
    try helpers.expectEqSlice(u8, read_inside_buffer[0..3], TEST_FILE_CONTENTS[0..3]);

    try read_stream.seekTo(0);

    var read_beginning_again: [3]u8 = @splat(0);
    try reader.readSliceAll(read_beginning_again[0..]);
    try helpers.expectEqSlice(u8, read_beginning_again[0..], read_inside_buffer[0..]);

    try read_stream.seekBy(-3);
    try helpers.expectEq(read_stream.getPos(), 0);

    try read_stream.seekBy(5);
    try helpers.expectEq(read_stream.getPos(), 5);

    try read_stream.seekBy(1);
    try helpers.expectEq(read_stream.getPos(), 6);

    const end_pos = try read_stream.getEndPos();
    try helpers.expectEq(end_pos, 36);

    var read_remaining: [30]u8 = @splat(0);
    try reader.readSliceAll(read_remaining[0..]);
    try helpers.expectEq(read_stream.getPos(), end_pos);
    try helpers.expectEqSlice(u8, read_remaining[0..], TEST_FILE_CONTENTS[6..]);
}

test "io.ReadStream: should error on invalid seek within unbuffered file" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var read_stream = zigimg.io.ReadStream.initFile(read_file, &.{});

    const seek_to_error = read_stream.seekTo(123456);
    try helpers.expectError(seek_to_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_after_end_error = read_stream.seekBy(123456);
    try helpers.expectError(seek_by_after_end_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_before_error = read_stream.seekBy(-300);
    try helpers.expectError(seek_by_before_error, zigimg.io.ReadStream.SeekError.Unseekable);
}

test "io.ReadStream: should read and seek properly within a file with a small buffer" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var small_buffer: [30]u8 = @splat(0);
    var read_stream = zigimg.io.ReadStream.initFile(read_file, small_buffer[0..]);

    var reader = read_stream.reader();

    const read_inside_buffer = try reader.take(3);
    try helpers.expectEq(read_stream.getPos(), 3);
    try helpers.expectEqSlice(u8, read_inside_buffer[0..3], TEST_FILE_CONTENTS[0..3]);

    try read_stream.seekTo(0);

    const read_beginning_again = try reader.take(3);
    try helpers.expectEqSlice(u8, read_beginning_again, read_inside_buffer);

    try read_stream.seekBy(-3);
    try helpers.expectEq(read_stream.getPos(), 0);

    try read_stream.seekBy(5);
    try helpers.expectEq(read_stream.getPos(), 5);

    try read_stream.seekBy(1);
    try helpers.expectEq(read_stream.getPos(), 6);

    const end_pos = try read_stream.getEndPos();
    try helpers.expectEq(end_pos, 36);

    const read_remaining = try reader.take(30);
    try helpers.expectEq(read_stream.getPos(), end_pos);
    try helpers.expectEqSlice(u8, read_remaining, TEST_FILE_CONTENTS[6..]);
}

test "io.ReadStream: should read and seek properly within a buffered file" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var read_stream = zigimg.io.ReadStream.initBufferedFile(read_file);

    var reader = read_stream.reader();

    const read_inside_buffer = try reader.take(3);
    try helpers.expectEq(read_stream.getPos(), 3);
    try helpers.expectEqSlice(u8, read_inside_buffer[0..3], TEST_FILE_CONTENTS[0..3]);

    try read_stream.seekTo(0);

    const read_beginning_again = try reader.take(3);
    try helpers.expectEqSlice(u8, read_beginning_again, read_inside_buffer);

    try read_stream.seekBy(-3);
    try helpers.expectEq(read_stream.getPos(), 0);

    try read_stream.seekBy(5);
    try helpers.expectEq(read_stream.getPos(), 5);

    try read_stream.seekBy(1);
    try helpers.expectEq(read_stream.getPos(), 6);

    const end_pos = try read_stream.getEndPos();
    try helpers.expectEq(end_pos, 36);

    const read_remaining = try reader.take(30);
    try helpers.expectEq(read_stream.getPos(), end_pos);
    try helpers.expectEqSlice(u8, read_remaining, TEST_FILE_CONTENTS[6..]);
}

test "io.ReadStream: should error on invalid seek within a default buffered file" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var read_stream = zigimg.io.ReadStream.initBufferedFile(read_file);

    const seek_to_error = read_stream.seekTo(123456);
    try helpers.expectError(seek_to_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_after_end_error = read_stream.seekBy(123456);
    try helpers.expectError(seek_by_after_end_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_before_error = read_stream.seekBy(-300);
    try helpers.expectError(seek_by_before_error, zigimg.io.ReadStream.SeekError.Unseekable);

    const seek_by_after_within_buffer_error = read_stream.seekBy(TEST_FILE_CONTENTS.len + 5);
    try helpers.expectError(seek_by_after_within_buffer_error, zigimg.io.ReadStream.SeekError.Unseekable);
}
