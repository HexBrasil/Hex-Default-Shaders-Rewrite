## Volumetric Lightning!

#version 120

varying vec2 screenCoord;
varying vec3 screenRay;
varying float LdotV;

const int noiseTextureResolution = 1028;

uniform sampler2D gcolor;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;

uniform mat4 gbufferProjection;

uniform vec3 shadowLightPosition;

float skyMask(in vec2 uv, in float brightness){
    if(textureLod(depthtex1, uv, 0).x == 1.0) return brightness;
    return 0.0;
}

void main(){
    ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
    vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;
    float blueNoise = texelFetch(noisetex, screenTexelCoord & 255, 0).x;

    const int stepSize = 55;
    const float rcpStepSize = 1.0 / float(stepSize);

    const float rayLength = 1;
    const float rayStrength = rcpStepSize / 20;
    const vec3 lightColor = vec3(1.5, 1.0, 0.55);

    vec2 endPos = (screenCoord - screenRay.xy) * rcpStepSize * rayLength;
    vec2 startPos = screenCoord - endPos * blueNoise;

    float godRays = 0.0;

    for(int i = 0; i < stepSize; i++){
        godRays += skyMask(startPos, rayStrength);
        startPos -= endPos;
    }

    sceneCol += godRays * lightColor * LdotV;

    gl_FragData[0] = vec4(sceneCol, 1);
}
