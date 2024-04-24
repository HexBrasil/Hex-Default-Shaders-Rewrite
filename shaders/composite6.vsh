#version 120

varying vec2 screenCoord;
varying vec3 screenRay;
varying float LdotV;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferProjection;

vec3 toScreen(vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos + gbufferProjection[3].xyz;
	return (data.xyz / -pos.z) * 0.5 + 0.5;
}

void main(){
    screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    screenRay = toScreen(normalize(shadowLightPosition));
    LdotV = -normalize(shadowLightPosition).z;
    gl_Position = ftransform();


}