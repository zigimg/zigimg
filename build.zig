const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_tracy = b.option(bool, "tracy", "Enable tracy (default: false)") orelse false;

    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .enable = enable_tracy,
    });

    const module = b.addModule("zigimg", .{
        .source_file = .{ .path = "zigimg.zig" },
        .dependencies = &.{
            .{
                .name = "tracy",
                .module = tracy.module("tracy"),
            },
        },
    });

    const zigimg_build_test = b.addTest(.{
        .name = "zigimgtest",
        .root_source_file = .{ .path = "zigimg.zig" },
        .target = target,
        .optimize = optimize,
    });
    zigimg_build_test.addModule("tracy", tracy.module("tracy"));
    if (enable_tracy) {
        zigimg_build_test.linkLibrary(tracy.artifact("tracy"));
    }

    b.installArtifact(zigimg_build_test);

    const run_test_cmd = b.addRunArtifact(zigimg_build_test);
    // Force running of the test command even if you don't have changes
    run_test_cmd.has_side_effects = true;
    run_test_cmd.step.dependOn(b.getInstallStep());

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_test_cmd.step);

    const build_only_test_step = b.step("test_build_only", "Build the tests but does not run it");
    build_only_test_step.dependOn(&zigimg_build_test.step);
    build_only_test_step.dependOn(b.getInstallStep());

    // Add `to_png` example executable
    const to_png_exe = b.addExecutable(.{
        .name = "to_png",
        .root_source_file = .{ .path = "examples/to_png.zig" },
        .target = target,
        .optimize = optimize,
    });
    to_png_exe.addModule("zigimg", module);
    to_png_exe.addModule("tracy", tracy.module("tracy"));
    if (enable_tracy) {
        to_png_exe.linkLibrary(tracy.artifact("tracy"));
    }
    b.installArtifact(to_png_exe);
}
