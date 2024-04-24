vec3 getMotionBlur(vec3 color, float z, float dither) {
	if (z >= 0.56) {
		float weight = 0.0;
		vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);
		vec3 blur = vec3(0.0);
		
		vec4 currentPosition = vec4(texCoord, z, 1.0) * 2.0 - 1.0;
		
		vec4 viewPos = gbufferProjectionInverse * currentPosition;
			 viewPos = gbufferModelViewInverse * viewPos;
			 viewPos /= viewPos.w;
		
		vec3 cameraOffset = cameraPosition - previousCameraPosition;
		
		vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
			 previousPosition = gbufferPreviousModelView * previousPosition;
			 previousPosition = gbufferPreviousProjection * previousPosition;
			 previousPosition /= previousPosition.w;

		vec2 velocity = (currentPosition - previousPosition).xy;
		velocity = velocity / (1.0 + length(velocity)) * MOTION_BLUR_STRENGTH * 0.025;
		
		vec2 coord = texCoord.st - velocity * (1.5 + dither);
		for(int i = 0; i < 5; i++, coord += velocity) {
			vec2 sampleCoord = clamp(coord, doublePixel, 1.0 - doublePixel);
			float mask = float(texture2D(depthtex1, sampleCoord).r > 0.56);
			blur += texture2DLod(colortex1, sampleCoord, 0.0).rgb * mask;
			weight += mask;
		}
		blur /= max(weight, 1.0);

		return blur;
	}
	else return color;
}