const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

const Vertex = struct {
    pos: [2]f32,
    col: [3]f32,
};

const vertices = [3]Vertex{
    .{
        .pos = .{ -0.6, -0.4 },
        .col = .{ 1.0, 0.0, 0.0 },
    },
    .{
        .pos = .{ 0.6, -0.4 },
        .col = .{ 0.0, 1.0, 0.0 },
    },
    .{
        .pos = .{ 0.0, 0.6 },
        .col = .{ 0.0, 0.0, 1.0 },
    },
};

const vertex_shader_text =
    \\#version 330
    \\
    \\uniform mat4 MVP;
    \\in vec3 vCol;
    \\in vec2 vPos;
    \\out vec3 color;
    \\
    \\void main()
    \\{
    \\    gl_Position = MVP * vec4(vPos, 0.0, 1.0);
    \\    color = vCol;
    \\}
;

const fragment_shader_text =
    \\#version 330
    \\
    \\in vec3 color;
    \\out vec4 fragment;
    \\
    \\void main()
    \\{
    \\    fragment = vec4(color, 1.0);
    \\}
;

fn errorCallback(error_code: c_int, description: [*:0]u8) callconv(.C) void {
    std.debug.print("Error: code {d}, detail: {s}\n", .{ error_code, description });
}

// Procedure table that will hold OpenGL functions loaded at runtime.
var procs: gl.ProcTable = undefined;

pub fn main() !void {
    var major: i32 = 0;
    var minor: i32 = 0;
    var rev: i32 = 0;

    glfw.getVersion(&major, &minor, &rev);
    std.debug.print("GLFW {}.{}.{}\n", .{ major, minor, rev });

    // should before init
    _ = glfw.setErrorCallback(errorCallback);
    try glfw.init();
    defer glfw.terminate();
    std.debug.print("GLFW Init Succeeded.\n", .{});

    glfw.windowHint(glfw.ContextVersionMajor, 4);
    glfw.windowHint(glfw.ContextVersionMinor, 1);
    glfw.windowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile);
    glfw.windowHint(glfw.OpenGLForwardCompat, 1);
    const window: *glfw.Window = try glfw.createWindow(800, 640, "Hello World", null, null);
    defer glfw.destroyWindow(window);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    // Initialize the procedure table.
    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;

    // Make the procedure table current on the calling thread.
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    const program = try compileProgram();

    var vertex_buffer: gl.uint = undefined;
    gl.GenBuffers(1, (&vertex_buffer)[0..1]);
    gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);

    const mvp_location = gl.GetUniformLocation(program, "MVP");
    const vpos_location: gl.uint = @intCast(gl.GetAttribLocation(program, "vPos"));
    const vcol_location: gl.uint = @intCast(gl.GetAttribLocation(program, "vCol"));

    var vertex_array: gl.uint = undefined;
    gl.GenVertexArrays(1, (&vertex_array)[0..1]);
    gl.BindVertexArray(vertex_array);
    gl.EnableVertexAttribArray(vpos_location);
    gl.VertexAttribPointer(vpos_location, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @offsetOf(Vertex, "pos"));
    gl.EnableVertexAttribArray(vcol_location);
    gl.VertexAttribPointer(vcol_location, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @offsetOf(Vertex, "col"));

    while (!glfw.windowShouldClose(window)) {
        if (glfw.getKey(window, glfw.KeyEscape) == glfw.Press) {
            glfw.setWindowShouldClose(window, true);
        }

        var width: c_int = undefined;
        var height: c_int = undefined;
        glfw.getFramebufferSize(window, &width, &height);
        const width_f: f32 = @floatFromInt(width);
        const height_f: f32 = @floatFromInt(height);
        const ratio = width_f / height_f;

        gl.Viewport(0, 0, width, height);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        var p: linmath.Mat4x4 = undefined;
        var mvp: linmath.Mat4x4 = undefined;
        var m = linmath.mat4x4Identity();
        linmath.mat4x4RotateZ(&m, m, @floatCast(glfw.getTime()));
        linmath.mat4x4Ortho(&p, -ratio, ratio, -1.0, 1.0, 1.0, -1.0);
        linmath.mat4x4Mul(&mvp, p, m);

        gl.UseProgram(program);
        gl.UniformMatrix4fv(mvp_location, 1, gl.FALSE, @ptrCast(&mvp));
        gl.BindVertexArray(vertex_array);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

        glfw.swapBuffers(window);

        glfw.pollEvents();
    }
}

fn compileProgram() !gl.uint {
    var success: c_int = undefined;
    var info_log_buf: [512:0]u8 = undefined;

    const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    if (vertex_shader == 0) return error.GlCreateVertexShaderFailed;
    defer gl.DeleteShader(vertex_shader);

    gl.ShaderSource(vertex_shader, 1, &.{vertex_shader_text}, &.{vertex_shader_text.len});
    gl.CompileShader(vertex_shader);
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(vertex_shader, info_log_buf.len, null, &info_log_buf);
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.GlCompileVertexShaderFailed;
    }

    const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
    if (fragment_shader == 0) return error.GlCreateFragmentShaderFailed;
    defer gl.DeleteShader(fragment_shader);
    gl.ShaderSource(fragment_shader, 1, &.{fragment_shader_text}, &.{fragment_shader_text.len});
    gl.CompileShader(fragment_shader);
    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(fragment_shader, info_log_buf.len, null, &info_log_buf);
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.GlCompileVertexShaderFailed;
    }

    const program = gl.CreateProgram();
    gl.AttachShader(program, vertex_shader);
    gl.AttachShader(program, fragment_shader);
    gl.LinkProgram(program);
    gl.GetProgramiv(program, gl.LINK_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
        std.debug.print("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.LinkProgramFailed;
    }

    return program;
}

// Copied from https://github.com/glfw/glfw/blob/master/deps/linmath.h
const linmath = struct {
    const Vec4 = [4]f32;
    pub const Mat4x4 = [4]Vec4;

    fn vec4Dup(dst: *Vec4, src: Vec4) void {
        for (0..4) |i| {
            dst[i] = src[i];
        }
    }

    pub fn mat4x4Dup(m: *Mat4x4, n: Mat4x4) void {
        for (0..4) |i| {
            vec4Dup(&m[i], n[i]);
        }
    }

    pub fn mat4x4Mul(m: *Mat4x4, a: Mat4x4, b: Mat4x4) void {
        var temp: Mat4x4 = undefined;
        for (0..4) |c| {
            for (0..4) |r| {
                temp[c][r] = 0.0;
                for (0..4) |k| {
                    temp[c][r] += a[k][r] * b[c][k];
                }
            }
        }
        mat4x4Dup(m, temp);
    }

    pub fn mat4x4Identity() Mat4x4 {
        var m: Mat4x4 = undefined;
        for (0..4) |i| {
            for (0..4) |j| {
                if (i == j) {
                    m[i][j] = 1.0;
                } else {
                    m[i][j] = 0.0;
                }
            }
        }
        return m;
    }

    pub fn mat4x4RotateZ(q: *Mat4x4, m: Mat4x4, angle: f32) void {
        const s: f32 = @sin(angle);
        const c: f32 = @cos(angle);
        const r = Mat4x4{
            .{ c, s, 0.0, 0.0 },
            .{ -s, c, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        };
        mat4x4Mul(q, m, r);
    }

    pub fn mat4x4Ortho(m: *Mat4x4, l: f32, r: f32, b: f32, t: f32, n: f32, f: f32) void {
        m[0][0] = 2.0 / (r - l);
        m[0][1] = 0.0;
        m[0][2] = 0.0;
        m[0][3] = 0.0;

        m[1][1] = 2.0 / (t - b);
        m[1][0] = 0.0;
        m[1][2] = 0.0;
        m[1][3] = 0.0;

        m[2][2] = -2.0 / (f - n);
        m[2][0] = 0.0;
        m[2][1] = 0.0;
        m[2][3] = 0.0;

        m[3][0] = -(r + l) / (r - l);
        m[3][1] = -(t + b) / (t - b);
        m[3][2] = -(f + n) / (f - n);
        m[3][3] = 1.0;
    }
};
