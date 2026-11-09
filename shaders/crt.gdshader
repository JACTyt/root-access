shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float curvature = 0.02;
uniform float scanline_strength = 0.12;

void fragment() {
	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	centered *= 1.0 + curvature * dot(centered, centered);
	vec2 uv = centered * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 col = texture(screen_tex, uv).rgb;
		col *= 1.0 - scanline_strength * (0.5 + 0.5 * sin(uv.y * 1440.0));
		float vignette = 1.0 - 0.25 * dot(centered, centered);
		COLOR = vec4(col * vignette, 1.0);
	}
}
