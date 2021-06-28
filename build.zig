const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const buildMode = b.standardReleaseOptions();

    const zigimg_test = b.addTest("zigimg.zig");
    zigimg_test.setBuildMode(buildMode);

    const test_step = b.step("check_semantics", "Verifies that all declarations are kinda sane.");
    test_step.dependOn(&zigimg_test.step);
}
