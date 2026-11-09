shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec2 resolution = vec2(384.0, 288.0);

float index_at(vec2 pixel) {
	return floor(texture(screen, (clamp(pixel, vec2(0.0), resolution - 1.0) + 0.5) / resolution).r * 255.0 + 0.5);
}

void fragment() {
	vec2 pixel = floor(SCREEN_UV * resolution);
	float sum = index_at(pixel) + index_at(pixel + vec2(1.0, 0.0)) + index_at(pixel + vec2(-1.0, 0.0)) + index_at(pixel + vec2(0.0, 1.0)) + index_at(pixel + vec2(0.0, -1.0));
	COLOR = vec4(max(floor(sum / 5.0) - 1.0, 1.0) / 255.0, 0.0, 0.0, 1.0);
}
