const std = @import("std");
const zigimg = @import("zigimg");
const tracy = @import("tracy");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 3) {
        std.debug.print("Correct usage:\n\tto_png <input file> <output file>", .{});
        std.process.exit(1);
    }

    const input_filepath = args[1];
    const output_filepath = args[2];

    const read_trace = tracy.trace(@src(), "read image");
    var image = try zigimg.Image.fromFilePath(gpa, input_filepath);
    defer image.deinit();
    read_trace.end();

    const write_trace = tracy.trace(@src(), "write image");
    try image.writeToFilePath(output_filepath, .{ .png = .{} });
    write_trace.end();
}
