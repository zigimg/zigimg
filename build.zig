const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const buildMode = b.standardReleaseOptions();

    const zigimg_test = b.addTest("zigimg.zig");
    zigimg_test.setBuildMode(buildMode);
    zigimg_test.emit_bin = .{ .emit_to = "zig-out/zigimgtest"};

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&zigimg_test.step);
}
