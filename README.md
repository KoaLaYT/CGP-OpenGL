# CGP-OpenGL

Exercise for Computer Graphics Programming in OpenGL with C++ Third Edition

## Libraries

`zig fetch` currently didnot support proxy, the solution is to use [zigfetch](https://github.com/jiacai2050/zigcli).
```
# detail usage see https://zigcli.liujiacai.net/programs/zigfetch/
# manually add to .dependencies in `build.zig.zon`
zigfetch .
```

1. [glfw](https://www.glfw.org/)
- use a zig binding for glfw, copy from this [repo](https://github.com/IridescenceTech/zglfw)
- unlike origin repo use system library of glfw, instead use a precompiled static library

2. [zigglgen](https://github.com/castholm/zigglgen)
- opengl bindings for zig

3. [zlm](https://github.com/ziglibs/zlm)
- matrix and vector math library for opengl

## Sample

```bash
zig build sample -Doptimize=ReleaseSafe
```

[Getting started](https://www.glfw.org/docs/3.4/quick.html#quick_timer) example from `glfw` official docs.
Also see [this example](https://github.com/castholm/zig-examples/blob/master/opengl-hexagon/README.md) for `zigglgen` usage.

## Example codes of the book

All files in `src/examples`, to run, do:

```bash
zig build 02001_first -Doptimize=ReleaseSafe
```

