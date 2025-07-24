const std = @import("std");
const gl = @import("gl");

pub fn glfwErrorCallback(error_code: c_int, description: [*:0]u8) callconv(.C) void {
    std.log.err("Error: code {d}, detail: {s}\n", .{ error_code, description });
}

pub fn createShaderProgram(vs_file: []const u8, fs_file: []const u8) !gl.uint {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const vs = try readShaderSource(alloc, vs_file);
    defer alloc.free(vs);
    const fs = try readShaderSource(alloc, fs_file);
    defer alloc.free(fs);

    var success: c_int = undefined;
    var info_log_buf: [512:0]u8 = undefined;

    const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    if (vertex_shader == 0) return error.GlCreateVertexShaderFailed;
    defer gl.DeleteShader(vertex_shader);

    gl.ShaderSource(vertex_shader, 1, &.{vs.ptr}, null);
    gl.CompileShader(vertex_shader);
    checkOpenGLError();
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(vertex_shader, info_log_buf.len, null, &info_log_buf);
        std.log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.GlCompileVertexShaderFailed;
    }

    const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
    if (fragment_shader == 0) return error.GlCreateFragmentShaderFailed;
    defer gl.DeleteShader(fragment_shader);
    gl.ShaderSource(fragment_shader, 1, &.{fs.ptr}, null);
    gl.CompileShader(fragment_shader);
    checkOpenGLError();
    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(fragment_shader, info_log_buf.len, null, &info_log_buf);
        std.log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.GlCompileVertexShaderFailed;
    }

    const program = gl.CreateProgram();
    if (program == 0) return error.GlCreateProgramFailed;
    errdefer gl.DeleteProgram(program);

    gl.AttachShader(program, vertex_shader);
    gl.AttachShader(program, fragment_shader);
    gl.LinkProgram(program);
    checkOpenGLError();
    gl.GetProgramiv(program, gl.LINK_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
        std.log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.LinkProgramFailed;
    }

    return program;
}

pub inline fn checkOpenGLError() void {
    const shouldCheck = switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => true,
        else => false,
    };
    if (!shouldCheck) return;

    var err = gl.GetError();
    while (err != gl.NO_ERROR) {
        std.log.err("glError: {any}", .{err});
        err = gl.GetError();
    }
}

fn readShaderSource(alloc: std.mem.Allocator, file_path: []const u8) ![:0]const u8 {
    const cwd = std.fs.cwd();
    return try cwd.readFileAllocOptions(alloc, file_path, 4096, null, @alignOf(u8), 0);
}
