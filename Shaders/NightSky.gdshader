shader_type sky;

// --- Stars ---
uniform float star_density : hint_range(0.0, 1.0) = 0.98;
uniform float star_brightness : hint_range(0.0, 5.0) = 1.8;
uniform float star_size : hint_range(0.0, 1.0) = 0.3;
uniform float star_twinkle : hint_range(0.0, 1.0) = 0.3;

// --- Sky ---
uniform vec3 sky_top_color : source_color = vec3(0.01, 0.02, 0.08);
uniform vec3 sky_horizon_color : source_color = vec3(0.05, 0.08, 0.15);

// --- Moon ---
uniform vec3 moon_color : source_color = vec3(0.9, 0.95, 1.0);
uniform float moon_size : hint_range(0.0, 0.3) = 0.04;
uniform vec3 moon_direction = vec3(0.3, 0.6, 0.2);
uniform float moon_glow : hint_range(0.0, 2.0) = 0.4;

// --- Clouds ---
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.01;
uniform float cloud_brightness : hint_range(0.0, 1.0) = 0.5;
uniform vec3 cloud_color : source_color = vec3(0.15, 0.18, 0.28);

// =====================
//      UTILITIES
// =====================

float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// =====================
//      STAR FIELD
// =====================

float stars(vec3 dir, float density, float size) {
    vec2 uv = vec2(atan(dir.x, dir.z), asin(dir.y)) * 5.0;
    vec2 cell = floor(uv * 20.0);
    vec2 local = fract(uv * 20.0) - 0.5;

    float h = hash(cell);
    if (h < density) return 0.0;

    float twinkle = 1.0 - star_twinkle 
        + star_twinkle * (0.5 + 0.5 * sin(TIME * 3.0 * h + h * 100.0));

    float star = 1.0 - smoothstep(size * 0.01, size * 0.08, length(local));

    return star * h * star_brightness * twinkle;
}

// =====================
//       CLOUDS
// =====================

float cloud_layer(vec3 dir) {
    vec2 uv = dir.xz / (dir.y + 0.1);
    uv *= 0.25;

    vec2 uv1 = uv + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.4);
    vec2 uv2 = uv * 1.7 + vec2(TIME * cloud_speed * 0.6, TIME * cloud_speed * 0.8);

    float layer1 = texture(cloud_noise, uv1).r;
    float layer2 = texture(cloud_noise, uv2).r;

    float f = layer1 * 0.6 + layer2 * 0.4;

    float cloud = smoothstep(1.0 - cloud_coverage, 1.0, f);

    float horizon_fade = smoothstep(0.0, 0.25, dir.y);
    float above = step(0.0, dir.y);

    return cloud * horizon_fade * above;
}

// =====================
//        MAIN
// =====================

void sky() {
    vec3 dir = normalize(EYEDIR);

    // Sky gradient
    float horizon = pow(clamp(1.0 - dir.y, 0.0, 1.0), 2.0);
    vec3 color = mix(sky_top_color, sky_horizon_color, horizon);

    // Stars
    if (dir.y > -0.05) {
        float s = stars(dir, star_density, star_size);
        float fade = smoothstep(0.0, 0.2, dir.y);
        color += vec3(s) * fade;
    }

    // Moon
    vec3 moon_dir = normalize(moon_direction);
    float moon_dist = distance(dir, moon_dir);

    float moon = 1.0 - smoothstep(moon_size - 0.002, moon_size, moon_dist);
    float glow = pow(clamp(1.0 - moon_dist / (moon_size * 8.0), 0.0, 1.0), 3.0) * moon_glow;

    color += moon_color * moon;
    color += moon_color * glow * 0.3;

    // Clouds
    float cloud = cloud_layer(dir);
    float moon_light = clamp(1.0 - moon_dist * 2.0, 0.0, 1.0);

    vec3 lit_cloud = cloud_color + moon_color * moon_light * 0.08;

    color = mix(color, lit_cloud, cloud * cloud_brightness);

    COLOR = color;
}