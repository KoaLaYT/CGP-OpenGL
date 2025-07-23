const std = @import("std");
const log = std.log;
const glfw = @import("glfw");
const gl = @import("gl");

var procs: gl.ProcTable = undefined;

pub fn main() !void {
    _ = glfw.setErrorCallback(errorCallback);
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(glfw.ContextVersionMajor, 4);
    glfw.windowHint(glfw.ContextVersionMinor, 1);
    glfw.windowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile);
    glfw.windowHint(glfw.OpenGLForwardCompat, 1);
    const window: *glfw.Window = try glfw.createWindow(600, 600, "Chapter2 - program1", null, null);
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
    _ = window;
}

fn display(window: *glfw.Window, current_time: f64) !void {
    gl.ClearColor(1.0, 0.0, 0.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    _ = window;
    _ = current_time;
}

fn errorCallback(error_code: c_int, description: [*:0]u8) callconv(.C) void {
    log.err("Error: code {d}, detail: {s}\n", .{ error_code, description });
}
