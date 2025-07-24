const std = @import("std");

pub fn build(b: *std.Build) !void {
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

    const utils_mod = b.addModule("utils", .{
        .root_source_file = b.path("src/utils/utils.zig"),
        .target = target,
        .optimize = optimize,
    });
    utils_mod.addImport("gl", gl_bindings_mod);

    const codes = [_][]const u8{
        "src/sample.zig",
        // examples
        "src/examples/02001_first.zig",
        "src/examples/02002_draw_point.zig",
        "src/examples/02004_glsl_from_file.zig",
        "src/examples/02005_draw_triangle.zig",
        "src/examples/02006_simple_animation.zig",
        // exercises
        "src/exercises/02001.zig",
        "src/exercises/02004.zig",
    };

    for (codes) |code| {
        const name = retriveName(code);
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(code),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("glfw", glfw_mod);
        exe.root_module.addImport("gl", gl_bindings_mod);
        exe.root_module.addImport("utils", utils_mod);

        b.installArtifact(exe);

        const cmd = b.addRunArtifact(exe);
        cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            cmd.addArgs(args);
        }

        const desc = try std.fmt.allocPrint(b.allocator, "Run {s}", .{name});
        const step = b.step(name, desc);
        step.dependOn(&cmd.step);
    }

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

fn retriveName(full_code_path: []const u8) []const u8 {
    var parts =
        std.mem.splitBackwardsScalar(u8, full_code_path, '/');
    const full_name = parts.next().?;
    return full_name[0 .. full_name.len - 4]; // remove .zig
}
