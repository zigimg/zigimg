const std = @import("std");
const helpers = @import("helpers.zig");
const zigimg = @import("zigimg");

const TEST_FILE_CONTENTS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

test "io.ReadStream: should read and seek properly within a file" {
    const TEST_FILENAME = "io_read_stream_test.dat";

    var temp_folder = std.testing.tmpDir(.{});
    defer temp_folder.cleanup();

    try temp_folder.dir.writeFile(.{ .sub_path = TEST_FILENAME, .data = TEST_FILE_CONTENTS });

    var read_file = try temp_folder.dir.openFile(TEST_FILENAME, .{});
    defer read_file.close();

    var read_stream = zigimg.io.ReadStream.initFile(read_file);

    var reader = read_stream.reader();

    const read_inside_buffer = try reader.take(3);
    try helpers.expectEq(read_stream.getPos(), 3);
    try helpers.expectEqSlice(u8, read_inside_buffer[0..3], TEST_FILE_CONTENTS[0..3]);
}
