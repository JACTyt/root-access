shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float intensity = 0.0;
uniform float flash = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	float band = floor(SCREEN_UV.y * 24.0 + TIME * 7.0);
	float jump = step(0.94, hash(band + floor(TIME * 9.0))) * intensity * 0.03;
	float shift = 0.004 * intensity + jump;
	float r = texture(screen_tex, SCREEN_UV + vec2(shift, 0.0)).r;
	float g = texture(screen_tex, SCREEN_UV + vec2(jump, 0.0)).g;
	float b = texture(screen_tex, SCREEN_UV - vec2(shift, 0.0)).b;
	COLOR = vec4(mix(vec3(r, g, b), vec3(1.0, 0.1, 0.12), flash * 0.35), 1.0);
}
