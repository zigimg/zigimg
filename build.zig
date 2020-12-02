const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const buildMode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zigimg", "zigimg.zig");
    lib.setBuildMode(buildMode);
    lib.addPackagePath("zigimg", "zigimg.zig");
    lib.install();
}
