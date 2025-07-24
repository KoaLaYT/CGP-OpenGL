const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const utils = @import("utils");

var procs: gl.ProcTable = undefined;
var shaderProgram: gl.uint = undefined;
var vao: [1]gl.uint = undefined;
var x: f64 = 0.0;
var speed: f64 = 0.5;
var last_time: f64 = 0.0;

pub fn main() !void {
    _ = glfw.setErrorCallback(utils.glfwErrorCallback);
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(glfw.ContextVersionMajor, 4);
    glfw.windowHint(glfw.ContextVersionMinor, 1);
    glfw.windowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile);
    glfw.windowHint(glfw.OpenGLForwardCompat, 1);
    const window: *glfw.Window = try glfw.createWindow(600, 600, "Chapter2 - program6", null, null);
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
    shaderProgram = try utils.createShaderProgram("glsl/e02004_vs.glsl", "glsl/02004_fs.glsl");
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao[0]);
    _ = window;
}

fn display(window: *glfw.Window, current_time: f64) !void {
    gl.ClearColor(0.0, 0.0, 0.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    gl.UseProgram(shaderProgram);

    const elapsed = current_time - last_time;
    last_time = current_time;

    const mov = elapsed * speed;
    x += mov;
    if (x > 1) speed *= -1;
    if (x < -1) speed *= -1;

    const offset_loc = gl.GetUniformLocation(shaderProgram, "offset");
    gl.ProgramUniform1f(shaderProgram, offset_loc, @floatCast(x));

    gl.DrawArrays(gl.TRIANGLES, 0, 3);

    _ = window;
}
