#version 120

#include "distort.glsl"

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform int lodLevel;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int dhRenderDistance;
uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform mat4 dhPreviousProjection;

const float sunPathRotation = -35.0f;
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 1024;

const float Ambient = 0.2f;

#define DH_ENABLED

float AdjustLightmapTorch(in float torch) {
    const float K = 3.0f;
    const float P = 2.06f;
    return K * pow(torch, P);
}

float AdjustLightmapSky(in float sky){
    float sky_2 = sky * sky;
    return sky_2 * sky_2;
}

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

vec3 GetLightmapColor(in vec2 Lightmap){
    Lightmap = AdjustLightmap(Lightmap);
    const vec3 TorchColor = vec3(1f, 1f, 1f);
    const vec3 SkyColor = vec3(1.00f, 1.0f, 1.9f);
    vec3 TorchLighting = Lightmap.x * TorchColor;
    vec3 SkyLighting = Lightmap.y * SkyColor;
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    return LightmapLighting;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.000f, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.5f - ShadowColor0.a);
    return mix(TransmittedColor * ShadowVisibility1, vec3(2.0f), ShadowVisibility0);
}

#define SHADOW_SAMPLES 3
const int ShadowSamplesPerSize = 1 * SHADOW_SAMPLES + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

vec3 GetShadow(float depth) {
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
    float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;
    vec3 ShadowAccum = vec3(15.0f);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 Offset = Rotation * vec2(x, y);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
}

void main(){
    vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2f));
    float Depth = texture2D(depthtex0, TexCoords).r;

    if(Depth == 1.0f){
        gl_FragData[0] = vec4(Albedo, 1.5f);
        return;
    }

    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2.0f - 1.0f);
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    vec3 LightmapColor = GetLightmapColor(Lightmap);

    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    vec3 Diffuse;

    #ifdef DH_ENABLED
    if (lodLevel > 0) {
        Diffuse = Albedo * (LightmapColor + Ambient);
    } else {
        Diffuse = Albedo * (LightmapColor + NdotL * GetShadow(Depth) + Ambient);
    }
    #else
    Diffuse = Albedo * (LightmapColor + NdotL * GetShadow(Depth) + Ambient);
    #endif

    gl_FragData[0] = vec4(Diffuse, 1.0f);
}
