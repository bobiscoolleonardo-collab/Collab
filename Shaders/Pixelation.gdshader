shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 20.0, 0.1) = 4.0;
uniform float levels : hint_range(2.0, 100.0, 1.0) = 8.0;
uniform vec2 gamma = vec2(1.0, 1.0);

void fragment() {
    vec2 tex_size = vec2(textureSize(screen_texture, 0));
    vec2 pixel_count = tex_size / (pixel_size * 2.0);
    vec2 pixelated_uv = floor(SCREEN_UV * pixel_count) / pixel_count;
    vec4 color = texture(screen_texture, pixelated_uv);

    color.rgb = pow(max(color.rgb, vec3(0.0001)), vec3(gamma.x));

    float grayscale = max(color.r, max(color.g, color.b));
    float lower = floor(grayscale * levels) / levels;
    float higher = ceil(grayscale * levels) / levels;
    float level = (abs(lower - grayscale) < abs(higher - grayscale)) ? lower : higher;
    color.rgb *= level / max(grayscale, 0.0001);

    color.rgb = pow(max(color.rgb, vec3(0.0001)), vec3(gamma.y));

    COLOR = color;
}