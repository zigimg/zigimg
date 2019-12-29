const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const buildMode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zigimg", "zigimg.zig");
    lib.setBuildMode(buildMode);
    lib.addPackagePath("zigimg", "zigimg.zig");
    lib.install();

    const test_step = b.addTest("tests/tests.zig");
    test_step.addPackagePath("zigimg", "zigimg.zig");
    test_step.setBuildMode(buildMode);
    test_step.linkLibrary(lib);

    const test_cmd = b.step("test", "Run the tests");
    test_cmd.dependOn(&test_step.step);
}
