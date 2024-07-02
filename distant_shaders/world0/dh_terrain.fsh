#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec3 viewSpacePosition;

uniform vec3 fogColor;
uniform sampler2D texture;
uniform sampler2D depthtex0;

uniform float viewHeight;
uniform float viewWidth;


varying vec2 uv;

uniform sampler2D colortex0; // Textura de cor
uniform sampler2D colortex2; // Textura de máscara

uniform float near; // Distância do plano de visão próximo
uniform float far; // Distância do plano de visão distante
uniform float rainStrength; // Intensidade da chuva

#define FOG_DENSITY 0.0003 // Densidade do nevoeiro
#define RAIN_MODIFIER 0.3 // Modificador de chuva

float LinearDepth(float z) {
    return 1.0 / ((1.0 - far / near) * z + (far / near));
}

float FogExp(float viewDistance, float density) {
    float factor = viewDistance * (density / log(2.0));
    return exp2(-factor);
}

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0)));
    return exp2(-factor * factor);
}




void main(){
    vec4 Albedo = texture2D(texture, TexCoords) * Color;

    vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth,viewHeight);
    float depth = texture(depthtex0,texCoord).r;

    if(depth != 1.0) {
        discard;
    }
    vec3 albedo = texture2D(colortex0, uv).rgb;
    
    float mask = 1.0 - texture2D(colortex2, uv).r;

    depth = LinearDepth(depth);
    float viewDistance = depth * far - near;

    // Sempre ajustar a densidade do nevoeiro com base na intensidade da chuva
    float density = FOG_DENSITY + (RAIN_MODIFIER * rainStrength);

    // Ajustar ainda mais a densidade com base na profundidade
    density *= mix(0.2, 1.0, rainStrength);



    float fogFactor1 = FogExp(viewDistance, density);
    float fogFactor2 = FogExp2(viewDistance, density);
    
    float fogFactor = 1.0 - clamp(mix(fogFactor1, (fogFactor2 + fogFactor1) / 2.0, rainStrength), 0.0, 1.0);
    fogFactor *= mask;

    vec3 fogColor = vec3(0.82, 0.83, 0.9);
    fogColor *= mix(1.0, 0.25, rainStrength);
    vec3 fogged = mix(albedo, fogColor, fogFactor);

    gl_FragColor = vec4(fogged, 1.0);



    /* DRAWBUFFERS:012 */
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.7f + 0.9f, 0.8f);
    gl_FragData[2] = vec4(LightmapCoords, 1012.0f, 0.0f);
}