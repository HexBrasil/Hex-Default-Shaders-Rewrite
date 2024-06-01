#version 120

attribute vec2 position;
attribute vec2 texcoord;

varying vec2 v_texcoord;

void main() {
    v_texcoord = texcoord;

    gl_Position = vec4(position * 2.0 - 1.0, 0.0, 1.0);
}
