const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_mod = b.addModule("glfw", .{
        .root_source_file = b.path("src/glfw/glfw.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    glfw_mod.linkFramework("Cocoa", .{});
    glfw_mod.linkFramework("IOKit", .{});
    // TODO auto download from glfw and add switch for different os
    glfw_mod.addObjectFile(b.path("src/glfw/libglfw3.a"));

    const gl_bindings_mod = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        // .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    const sample_exe = b.addExecutable(.{
        .name = "sample",
        .root_source_file = b.path("src/sample.zig"),
        .target = target,
        .optimize = optimize,
    });
    sample_exe.root_module.addImport("glfw", glfw_mod);
    sample_exe.root_module.addImport("gl", gl_bindings_mod);

    b.installArtifact(sample_exe);

    const sample_cmd = b.addRunArtifact(sample_exe);
    sample_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        sample_cmd.addArgs(args);
    }

    const sample_step = b.step("sample", "Run sample");
    sample_step.dependOn(&sample_cmd.step);

    // const lib_unit_tests = b.addTest(.{
    //     .root_module = lib_mod,
    // });
    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    //
    // const exe_unit_tests = b.addTest(.{
    //     .root_module = exe_mod,
    // });
    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    //
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
