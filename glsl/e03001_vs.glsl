#version 410

uniform float offset;

mat4 buildRotateZ(float rad) { 
    mat4 zrot = mat4(cos(rad), -sin(rad), 0.0, 0.0,
                     sin(rad),  cos(rad), 0.0, 0.0,
                          0.0,       0.0, 1.0, 0.0,
                          0.0,       0.0, 0.0, 1.0);
    return zrot;
}

void main() {
    mat4 zrot = buildRotateZ(0.523599); // 30deg
    if (gl_VertexID == 0) gl_Position = zrot * vec4(-0.25 + offset, 0.0, 0.0, 1.0);
    else if (gl_VertexID == 1) gl_Position = zrot * vec4(0 + offset, 0.5, 0.0, 1.0);
    else gl_Position = zrot * vec4(0.25 + offset, 0.0, 0.0, 1.0);
}
