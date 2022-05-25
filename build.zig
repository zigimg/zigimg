const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const buildMode = b.standardReleaseOptions();

    const test_out_path = "zig-out/zigimgtest";

    const zigimg_build_test = b.addTestExe("zigimgtest", "zigimg.zig");
    zigimg_build_test.setBuildMode(buildMode);
    zigimg_build_test.emit_bin = .{ .emit_to = test_out_path};

    const zigimg_test = b.addTest("zigimg.zig");
    zigimg_test.setBuildMode(buildMode);
    zigimg_test.emit_bin = .{ .emit_to = test_out_path};

    const test_build_step = b.step("tests", "build library tests to " ++ test_out_path);
    test_build_step.dependOn(&zigimg_build_test.step);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&zigimg_test.step);
}
