const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_disable_formats = b.option(bool, "default_disable_formats", "Disable support for all file formats by default") orelse false;

    const zigimg_module = b.addModule("zigimg", .{
        .root_source_file = b.path("zigimg.zig"),
        .target = target,
        .optimize = optimize,
    });

    zigimg_module.addImport("zigimg", zigimg_module);
    zigimg_module.addImport(
        "format_info",
        getSupportedFormatsModule(b, zigimg_module, target, optimize, default_disable_formats),
    );

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

    const build_only_test_step = b.step("test_build_only", "std.Build the tests but does not run it");
    build_only_test_step.dependOn(&zigimg_build_test.step);
    build_only_test_step.dependOn(b.getInstallStep());
}

fn getSupportedFormatsModule(
    b: *std.Build,
    zigimg_module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    default_disable_formats: bool,
) *std.Build.Module {
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

    var supported_formats_src: std.ArrayList(u8) = .empty;
    supported_formats_src.appendSlice(b.allocator, "const std = @import(\"std\");\n") catch @panic("OOM");
    supported_formats_src.appendSlice(b.allocator, "const formats = @import(\"zigimg\").formats;\n") catch @panic("OOM");
    supported_formats_src.appendSlice(b.allocator, "pub const SupportedFormats = struct {\n") catch @panic("OOM");

    var encoder_options_src: std.ArrayList(u8) = .empty;
    encoder_options_src.appendSlice(b.allocator, "pub const Format = std.meta.DeclEnum(SupportedFormats);\n") catch @panic("OOM");
    encoder_options_src.appendSlice(b.allocator, "pub const EncoderOptions = union(Format) {\n") catch @panic("OOM");

    if (enable_bmp) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "bmp", "bmp.BMP", true);
    if (enable_farbfeld) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "farbfeld", "farbfeld.Farbfeld", false);
    if (enable_gif) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "gif", "gif.GIF", true);
    if (enable_iff) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "iff", "iff.IFF", false);
    if (enable_jpeg) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "jpeg", "jpeg.JPEG", true);
    if (enable_pam) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "pam", "pam.PAM", true);
    if (enable_pbm) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "pbm", "netpbm.PBM", true);
    if (enable_pcx) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "pcx", "pcx.PCX", true);
    if (enable_pgm) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "pgm", "netpbm.PGM", true);
    if (enable_png) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "png", "png.PNG", true);
    if (enable_ppm) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "ppm", "netpbm.PPM", true);
    if (enable_qoi) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "qoi", "qoi.QOI", true);
    if (enable_ras) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "ras", "ras.RAS", false);
    if (enable_sgi) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "sgi", "sgi.SGI", false);
    if (enable_tga) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "tga", "tga.TGA", true);
    if (enable_tiff) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "tiff", "tiff.TIFF", false);
    if (enable_xbm) writeOne(b.allocator, &supported_formats_src, &encoder_options_src, "xbm", "xbm.XBM", false);

    supported_formats_src.appendSlice(b.allocator, "};\n") catch @panic("OOM");
    encoder_options_src.appendSlice(b.allocator, "};\n") catch @panic("OOM");

    supported_formats_src.appendSlice(
        b.allocator,
        encoder_options_src.toOwnedSlice(b.allocator) catch @panic("OOM"),
    ) catch @panic("OOM");

    const write_files = b.addWriteFiles();

    const supported_formats_write_file = write_files.add(
        "format_info.zig",
        supported_formats_src.toOwnedSlice(b.allocator) catch @panic("OOM"),
    );

    return b.createModule(.{
        .root_source_file = supported_formats_write_file,
        .target = target,
        .optimize = optimize,
        .imports = &.{.{
            .name = "zigimg",
            .module = zigimg_module,
        }},
    });
}

fn writeOne(
    allocator: std.mem.Allocator,
    supported_formats_src: *std.ArrayList(u8),
    encoder_options_src: *std.ArrayList(u8),
    id: []const u8,
    value: []const u8,
    comptime has_encoder_options: bool,
) void {
    supported_formats_src.print(allocator, "    pub const {s} = formats.{s};\n", .{ id, value }) catch @panic("OOM");

    const encoder_options_src_fmt = if (has_encoder_options)
        "    {0s}: SupportedFormats.{0s}.EncoderOptions,\n"
    else
        "    {s}: void,\n";
    encoder_options_src.print(allocator, encoder_options_src_fmt, .{id}) catch @panic("OOM");
}
