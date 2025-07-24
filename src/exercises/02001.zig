const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const utils = @import("utils");

var procs: gl.ProcTable = undefined;
var shaderProgram: gl.uint = undefined;
var vao: [1]gl.uint = undefined;

var size: f32 = 30.0;
var inc: f32 = 1.0;

pub fn main() !void {
    _ = glfw.setErrorCallback(utils.glfwErrorCallback);
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(glfw.ContextVersionMajor, 4);
    glfw.windowHint(glfw.ContextVersionMinor, 1);
    glfw.windowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile);
    glfw.windowHint(glfw.OpenGLForwardCompat, 1);
    const window: *glfw.Window = try glfw.createWindow(600, 600, "Chapter2 - exercise1", null, null);
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
    shaderProgram = try utils.createShaderProgram("glsl/02004_vs.glsl", "glsl/02004_fs.glsl");
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao[0]);
    _ = window;
}

fn display(window: *glfw.Window, current_time: f64) !void {
    gl.Clear(gl.COLOR_BUFFER_BIT);

    gl.UseProgram(shaderProgram);

    size += inc;
    gl.PointSize(size);
    if (size >= 64) inc *= -1;
    if (size <= 1) inc *= -1;

    gl.DrawArrays(gl.POINTS, 0, 1);

    _ = window;
    _ = current_time;
}
