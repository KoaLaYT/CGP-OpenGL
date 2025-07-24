const std = @import("std");
const log = std.log;
const glfw = @import("glfw");
const gl = @import("gl");

var procs: gl.ProcTable = undefined;
var shaderProgram: gl.uint = undefined;
var vao: [1]gl.uint = undefined;

pub fn main() !void {
    _ = glfw.setErrorCallback(errorCallback);
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(glfw.ContextVersionMajor, 4);
    glfw.windowHint(glfw.ContextVersionMinor, 1);
    glfw.windowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile);
    glfw.windowHint(glfw.OpenGLForwardCompat, 1);
    const window: *glfw.Window = try glfw.createWindow(600, 600, "Chapter2 - program4", null, null);
    defer glfw.destroyWindow(window);

    glfw.makeContextCurrent(window);
    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);
    glfw.swapInterval(1);

    try init(window);

    while (!glfw.windowShouldClose(window)) {
        try display(window, glfw.getTime());
        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}

fn init(window: *glfw.Window) !void {
    shaderProgram = try createShaderProgram();
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao[0]);
    _ = window;
}

fn display(window: *glfw.Window, current_time: f64) !void {
    gl.UseProgram(shaderProgram);
    gl.PointSize(30);
    gl.DrawArrays(gl.POINTS, 0, 1);

    _ = window;
    _ = current_time;
}

fn readShaderSource(alloc: std.mem.Allocator, file_path: []const u8) ![:0]const u8 {
    const cwd = std.fs.cwd();
    return try cwd.readFileAllocOptions(alloc, file_path, 4096, null, @alignOf(u8), 0);
}

fn createShaderProgram() !gl.uint {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const vs = try readShaderSource(alloc, "glsl/02004_vs.glsl");
    defer alloc.free(vs);
    const fs = try readShaderSource(alloc, "glsl/02004_fs.glsl");
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
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
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
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
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
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.LinkProgramFailed;
    }

    return program;
}

inline fn checkOpenGLError() void {
    const shouldCheck = switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => true,
        else => false,
    };
    if (!shouldCheck) return;

    var err = gl.GetError();
    while (err != gl.NO_ERROR) {
        log.err("glError: {any}", .{err});
        err = gl.GetError();
    }
}

fn errorCallback(error_code: c_int, description: [*:0]u8) callconv(.C) void {
    log.err("Error: code {d}, detail: {s}\n", .{ error_code, description });
}
