shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec4 water_tint : source_color = vec4(0.02, 0.22, 0.30, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float distortion_strength : hint_range(0.0, 0.05, 0.001) = 0.012;
uniform float caustic_strength : hint_range(0.0, 1.0, 0.01) = 0.16;
uniform float edge_darkness : hint_range(0.0, 1.0, 0.01) = 0.35;

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 wave_offset = vec2(
		sin(SCREEN_UV.y * 34.0 + TIME * 1.7),
		cos(SCREEN_UV.x * 28.0 - TIME * 1.25)
	) * distortion_strength * strength;

	vec4 screen_color = texture(screen_texture, SCREEN_UV + wave_offset);
	vec3 color = mix(screen_color.rgb, water_tint.rgb, tint_strength * strength);

	float caustic_a = sin((SCREEN_UV.x + SCREEN_UV.y * 0.65 + TIME * 0.18) * 42.0);
	float caustic_b = sin((SCREEN_UV.x * -0.8 + SCREEN_UV.y + TIME * 0.12) * 36.0);
	float caustic = smoothstep(0.82, 1.0, (caustic_a + caustic_b) * 0.25 + 0.5);
	color += vec3(0.10, 0.28, 0.26) * caustic * caustic_strength * strength;

	vec2 bubble_grid = floor((SCREEN_UV + vec2(0.0, TIME * 0.035)) * vec2(55.0, 32.0));
	float bubbles = step(0.985, random(bubble_grid));
	color += vec3(0.35, 0.65, 0.70) * bubbles * 0.08 * strength;

	float vignette = smoothstep(0.82, 0.25, distance(SCREEN_UV, vec2(0.5)));
	color *= mix(1.0 - edge_darkness * strength, 1.0, vignette);

	COLOR = vec4(color, 1.0);
}
