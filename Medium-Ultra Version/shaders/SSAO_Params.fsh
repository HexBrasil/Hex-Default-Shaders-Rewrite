#version 120

uniform sampler2D u_texture; // The main texture (color)
uniform sampler2D u_depth;   // The depth texture
uniform vec2 u_screenSize;   // Screen size (width, height)
uniform mat4 u_projection;   // Projection matrix

varying vec2 v_texcoord;

// SSAO Params 
const int kernelSize = 16;
const vec3 kernel[kernelSize] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(-1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, -1.0, 0.0),
    vec3(1.0, 1.0, 0.0),
    vec3(-1.0, -1.0, 0.0),
    vec3(1.0, -1.0, 0.0),
    vec3(-1.0, 1.0, 0.0),
    vec3(1.0, 0.0, 1.0),
    vec3(-1.0, 0.0, 1.0),
    vec3(0.0, 1.0, 1.0),
    vec3(0.0, -1.0, 1.0),
    vec3(1.0, 1.0, 1.0),
    vec3(-1.0, -1.0, 1.0),
    vec3(1.0, -1.0, 1.0),
    vec3(-1.0, 1.0, 1.0)
);

float getDepth(vec2 coord) {
    return texture2D(u_depth, coord).r;
}

void main() {
    float depth = getDepth(v_texcoord);

    vec4 position = u_projection * vec4(v_texcoord * 2.0 - 1.0, depth, 1.0);
    position /= position.w;

    float occlusion = 1.0;
    for (int i = 0; i < kernelSize; i++) {
        vec2 sampleTexcoord = v_texcoord + kernel[i].xy * 0.05 / u_screenSize;
        float sampleDepth = getDepth(sampleTexcoord);

        float rangeCheck = smoothstep(0.0, 1.0, 0.1 / abs(depth - sampleDepth));
        occlusion += (sampleDepth >= sampleTexcoord.y ? 1.0 : 0.0) * rangeCheck;
    }

    occlusion = clamp(1.0 - (occlusion / float(kernelSize)), 0.0, 1.0); // Clamp the occlusion value

    vec3 color = texture2D(u_texture, v_texcoord).rgb;
    color *= occlusion;

    gl_FragColor = vec4(color, 1.0);
}
