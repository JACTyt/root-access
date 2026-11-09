shader_type canvas_item;

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * 8.0 + vec2(TIME * 0.6, TIME * 0.2));
	float d = distance(UV, vec2(0.5));
	float a = smoothstep(0.5, 0.15, d) * (0.45 + 0.35 * noise(cell));
	COLOR = vec4(0.18, 0.28, 0.3, a);
}
