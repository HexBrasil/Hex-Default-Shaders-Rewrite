#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

vec3 Uncharted2Tonemap(vec3 x) {
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

void main() {
    // Apply gamma correction to the input texture
    vec3 Color = pow(texture2D(colortex0, TexCoords).rgb, vec3(1.0 / 2.2));

    // Apply the Uncharted 2 tonemap
    vec3 mapped = Uncharted2Tonemap(Color);

    // Perform additional adjustments if necessary (e.g., exposure)
    float exposure = 2.6;
    mapped *= exposure;

    // Reapply gamma correction
    mapped = pow(mapped, vec3(1.8 / 2.2));

    // Output the final color
    gl_FragColor = vec4(mapped, 1.0);
}
