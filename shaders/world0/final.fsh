#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

void main() {
   vec3 Color = pow(texture2D(colortex0, TexCoords).rgb, vec3(0.7f / 2.2f));
   gl_FragColor = vec4(Color, 1.0f);
}