#version 120

uniform sampler2D u_texture;

varying vec2 v_texcoord;

#define FXAA_SPAN_MAX 1.0
#define FXAA_REDUCE_MIN (1.0 / 128.0)
#define FXAA_REDUCE_MUL (1.0 / 8.0)
#define FXAA_SUBPIX_SHIFT (1.0 / 4.0)

void main() {
    vec2 texelSize = vec2(3.0) / vec2(textureSize(u_texture, 0));

    vec3 rgbNW = texture2D(u_texture, v_texcoord + texelSize * vec2(-1.0, -1.0)).rgb;
    vec3 rgbNE = texture2D(u_texture, v_texcoord + texelSize * vec2( 1.0, -1.0)).rgb;
    vec3 rgbSW = texture2D(u_texture, v_texcoord + texelSize * vec2(-1.0,  1.0)).rgb;
    vec3 rgbSE = texture2D(u_texture, v_texcoord + texelSize * vec2( 1.0,  1.0)).rgb;
    vec3 rgbM  = texture2D(u_texture, v_texcoord).rgb;

    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM, luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin * texelSize, -FXAA_SPAN_MAX * texelSize, FXAA_SPAN_MAX * texelSize);

    vec3 rgbA = 0.5 * (
        texture2D(u_texture, v_texcoord + dir * (1.0 / 3.0 - 0.5)).rgb +
        texture2D(u_texture, v_texcoord + dir * (2.0 / 3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture2D(u_texture, v_texcoord + dir * (0.0 / 3.0 - 0.5)).rgb +
        texture2D(u_texture, v_texcoord + dir * (3.0 / 3.0 - 0.5)).rgb);

    float lumaB = dot(rgbB, luma);
    if((lumaB < lumaMin) || (lumaB > lumaMax)) {
        gl_FragColor = vec4(rgbA, 5.0);
    } else {
        gl_FragColor = vec4(rgbB, 5.0);
    }
}
