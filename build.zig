const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigimg_build_test = b.addTest(.{
        .name = "zigimgtest",
        .root_source_file = .{ .path = "zigimg.zig" },
        .kind = .test_exe,
        .target = target,
        .optimize = optimize,
    });
    zigimg_build_test.install();

    const run_test_cmd = zigimg_build_test.run();
    run_test_cmd.step.dependOn(b.getInstallStep());

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_test_cmd.step);

    const build_only_test_step = b.step("test_build_only", "Build the tests but does not run it");
    build_only_test_step.dependOn(&zigimg_build_test.step);
    build_only_test_step.dependOn(b.getInstallStep());
}
