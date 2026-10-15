const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigimg_module = b.addModule("zigimg", .{
        .root_source_file = b.path("zigimg.zig"),
        .target = target,
        .optimize = optimize,
    });
    zigimg_module.addOptions("enabled_formats", getEnabledFormatOptions(b));

    zigimg_module.addImport("zigimg", zigimg_module);

    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

    const zigimg_build_test = b.addTest(.{
        .name = "zigimgtest",
        .root_module = zigimg_module,
        .filters = test_filters,
        .use_llvm = true,
    });

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
}

fn getEnabledFormatOptions(b: *std.Build) *std.Build.Step.Options {
    const default_disable_formats = b.option(bool, "default_disable_formats", "Disable support for all file formats by default") orelse false;

    const enable_bmp = b.option(bool, "bmp", "Enable BMP support (default: true)") orelse !default_disable_formats;
    const enable_farbfeld = b.option(bool, "farbfeld", "Enable Farbfeld support (default: true)") orelse !default_disable_formats;
    const enable_gif = b.option(bool, "gif", "Enable GIF support (default: true)") orelse !default_disable_formats;
    const enable_iff = b.option(bool, "iff", "Enable IFF support (default: true)") orelse !default_disable_formats;
    const enable_jpeg = b.option(bool, "jpeg", "Enable JPEG support (default: true)") orelse !default_disable_formats;
    const enable_pam = b.option(bool, "pam", "Enable PAM support (default: true)") orelse !default_disable_formats;
    const enable_pbm = b.option(bool, "pbm", "Enable PBM support (default: true)") orelse !default_disable_formats;
    const enable_pcx = b.option(bool, "pcx", "Enable PCX support (default: true)") orelse !default_disable_formats;
    const enable_pgm = b.option(bool, "pgm", "Enable PGM support (default: true)") orelse !default_disable_formats;
    const enable_png = b.option(bool, "png", "Enable PNG support (default: true)") orelse !default_disable_formats;
    const enable_ppm = b.option(bool, "ppm", "Enable PPM support (default: true)") orelse !default_disable_formats;
    const enable_qoi = b.option(bool, "qoi", "Enable QOI support (default: true)") orelse !default_disable_formats;
    const enable_ras = b.option(bool, "ras", "Enable RAS support (default: true)") orelse !default_disable_formats;
    const enable_sgi = b.option(bool, "sgi", "Enable SGI support (default: true)") orelse !default_disable_formats;
    const enable_tga = b.option(bool, "tga", "Enable TGA support (default: true)") orelse !default_disable_formats;
    const enable_tiff = b.option(bool, "tiff", "Enable TIFF support (default: true)") orelse !default_disable_formats;
    const enable_xbm = b.option(bool, "xbm", "Enable XBM support (default: true)") orelse !default_disable_formats;

    const enabled_format_options = b.addOptions();

    enabled_format_options.addOption(bool, "bmp", enable_bmp);
    enabled_format_options.addOption(bool, "farbfeld", enable_farbfeld);
    enabled_format_options.addOption(bool, "gif", enable_gif);
    enabled_format_options.addOption(bool, "iff", enable_iff);
    enabled_format_options.addOption(bool, "jpeg", enable_jpeg);
    enabled_format_options.addOption(bool, "pam", enable_pam);
    enabled_format_options.addOption(bool, "pbm", enable_pbm);
    enabled_format_options.addOption(bool, "pcx", enable_pcx);
    enabled_format_options.addOption(bool, "pgm", enable_pgm);
    enabled_format_options.addOption(bool, "png", enable_png);
    enabled_format_options.addOption(bool, "ppm", enable_ppm);
    enabled_format_options.addOption(bool, "qoi", enable_qoi);
    enabled_format_options.addOption(bool, "ras", enable_ras);
    enabled_format_options.addOption(bool, "sgi", enable_sgi);
    enabled_format_options.addOption(bool, "tga", enable_tga);
    enabled_format_options.addOption(bool, "tiff", enable_tiff);
    enabled_format_options.addOption(bool, "xbm", enable_xbm);

    return enabled_format_options;
}
