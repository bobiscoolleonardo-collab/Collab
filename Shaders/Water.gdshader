shader_type spatial;

uniform vec4 primary_color : source_color;
uniform vec4 secondary_color : source_color;

uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float specter : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float metalic : hint_range(0.0, 1.0, 0.01) = 0.4;

uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b : hint_normal;
uniform float normalmap_a_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float normalmap_b_strength : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform vec2 movement_direction = vec2(0.2, 0.1);
uniform float movement_strength : hint_range(0.0, 1, 0.01) = 0.12;

varying float wave_height;

uniform float uv_scale = 25.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform float depth_distance : hint_range(0.0, 20.0, 0.1) = 7.5;
uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_transparentcy : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float refraction_strength : hint_range(0.0, 8.0, 0.001) = 0.5;

uniform vec4 foam_color : source_color = vec4(0.8, 0.95, 1.0, 1.0);
uniform float foam_width : hint_range(0.0, 5.0, 0.01) = 0.45;
uniform float foam_softness : hint_range(0.0, 1.0, 0.01) = 0.03;
uniform float foam_strength : hint_range(0.0, 1.0, 0.01) = 1.0;


float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

vec3 gerstner(vec3 p, vec2 dir, float steepness, float wl) {
    dir = normalize(dir);
    float k = 2.0 * 3.14159 / wl;
    float c = sqrt(9.8 / k);
    float f = k * (dot(dir, p.xz) - c * TIME);
    float a = steepness / k;
    return vec3(
        dir.x * a * cos(f),
        a * sin(f),
        dir.y * a * cos(f)
    );
}

void vertex() {
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    vec3 offset = vec3(0.0);
    offset += gerstner(wp, vec2( 1.0,  0.3), 0.08, 6.0);
    offset += gerstner(wp, vec2( 0.3,  1.0), 0.06, 4.0);
    offset += gerstner(wp, vec2(-0.5,  0.8), 0.04, 2.5);

    VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
    wave_height = offset.y;
}

void fragment() {
	float basic_fresnel = fresnel(3.0, NORMAL, VIEW);
	
	vec2 uv = UV * uv_scale;
	vec2 uv_movement = movement_direction * TIME * movement_strength;
	
	vec3 normalmap = texture(normalmap_a, uv + uv_movement).rgb * normalmap_a_strength;
	normalmap += texture(normalmap_b, uv - uv_movement).rgb * normalmap_b_strength;
	
	vec3 ref_normalmap = normalmap * 2.0 - (normalmap_a_strength + normalmap_b_strength);
	vec3 ref_normal = mix(NORMAL, TANGENT * ref_normalmap + BINORMAL * ref_normalmap + NORMAL * ref_normalmap, 1.0);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_strength;
	
	float depth_clean = textureLod(depth_texture , SCREEN_UV, 0.0).r;
	float depth = textureLod(depth_texture, ref_ofs, 0.0).r;
	vec3 screen = textureLod(screen_texture, ref_ofs, 0.0).rgb;
	
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec3 ndc_clean = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean);
	
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z;
	
	vec4 world;
	
	if (linear_depth < 0.00001) {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	}
	else {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	}
	
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	
	vec4 foam_world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	float foam_depth_y = foam_world.y / foam_world.w;

	float water_depth = vertex_y - foam_depth_y;

	float foam_mask = 1.0 - smoothstep(
		foam_width,
		foam_width + foam_softness,
		water_depth
	);

	foam_mask = clamp(foam_mask, 0.0, 1.0);

	if (linear_depth < 0.00001) {
		foam_mask = 0.0;
	}


	
	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);
	
	vec3 depth_color = mix(secondary_color, primary_color, depth_blend).rgb;
	vec3 refraction_texture;
	
	if (linear_depth < 0.00001) {
		refraction_texture = textureLod(screen_texture, SCREEN_UV, ROUGHNESS * 2.0).rgb;
	}
	else {
		refraction_texture = textureLod(screen_texture, ref_ofs, ROUGHNESS * 2.0).rgb;
	}
	
	vec3 final_color = mix(depth_color, refraction_texture, water_transparentcy * depth_blend);
	final_color = mix(final_color, foam_color.rgb, foam_mask * foam_strength);
	
	ALBEDO = final_color;
	ROUGHNESS = roughness * (1.0 - basic_fresnel);
	NORMAL_MAP = normalmap;
	SPECULAR = specter;
	METALLIC = metalic;
}