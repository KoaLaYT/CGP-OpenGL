const std = @import("std");
const glfw = @import("glfw");

pub fn main() !void {
    var major: i32 = 0;
    var minor: i32 = 0;
    var rev: i32 = 0;

    glfw.getVersion(&major, &minor, &rev);
    std.debug.print("GLFW {}.{}.{}\n", .{ major, minor, rev });

    try glfw.init();
    defer glfw.terminate();
    std.debug.print("GLFW Init Succeeded.\n", .{});

    const window: *glfw.Window = try glfw.createWindow(800, 640, "Hello World", null, null);
    defer glfw.destroyWindow(window);

    while (!glfw.windowShouldClose(window)) {
        if (glfw.getKey(window, glfw.KeyEscape) == glfw.Press) {
            glfw.setWindowShouldClose(window, true);
        }

        glfw.pollEvents();
    }
}
