shader_type spatial;
render_mode cull_disabled;

uniform float depth_push : hint_range(0.0, 5.0) = 2.5;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Push line toward camera like your wall shader
	DEPTH = FRAGCOORD.z * depth_push;

	ALBEDO = color.rgb;
}