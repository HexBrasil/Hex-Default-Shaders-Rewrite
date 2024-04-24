void BSLTonemap(inout vec3 color) {
	color *= exp2(2.0 + EXPOSURE);
	color /= pow(pow(color, vec3(TONEMAP_WHITE_CURVE)) + 1.0, vec3(1.0 / TONEMAP_WHITE_CURVE));
	color = pow(color, mix(vec3(TONEMAP_LOWER_CURVE), vec3(TONEMAP_UPPER_CURVE), sqrt(color)));
}

void ColorSaturation(inout vec3 color) {
	float grayVibrance = (color.r + color.g + color.b) / 3.0;
	float graySaturation = grayVibrance;
	if (SATURATION < 1.00) graySaturation = dot(color, vec3(0.299, 0.587, 0.114));

	float minimumColor = min(color.r, min(color.g, color.b));
	float maximumColor = max(color.r, max(color.g, color.b));
	float saturation = (1.0 - (maximumColor - minimumColor)) * (1.0 - maximumColor) * grayVibrance * 5.0;
	vec3 lightness = vec3((minimumColor + maximumColor) * 0.5);

	color = mix(color, mix(color, lightness, 1.0 - VIBRANCE), saturation);
	color = mix(color, lightness, (1.0 - lightness) * (2.0 - VIBRANCE) / 2.0 * abs(VIBRANCE - 1.0));
	color = color * SATURATION - graySaturation * (SATURATION - 1.0);
}