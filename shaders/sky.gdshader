shader_type canvas_item;

uniform float height_t : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 low = vec3(0.12, 0.07, 0.20);
	vec3 mid = vec3(0.035, 0.045, 0.13);
	vec3 space = vec3(0.008, 0.012, 0.035);
	float y = UV.y;
	vec3 col = mix(low, mid, smoothstep(0.28, 0.82, y));
	col = mix(col, space, height_t * (0.35 + 0.65 * y));
	float horizon = exp(-pow((y - 0.74 + height_t * 0.18) * 7.5, 2.0));
	col += vec3(0.32, 0.12, 0.38) * horizon * (1.0 - height_t * 0.75);
	float haze = exp(-pow((y - 0.88) * 10.0, 2.0)) * (1.0 - height_t);
	col += vec3(0.18, 0.08, 0.10) * haze;
	COLOR = vec4(col, 1.0);
}
