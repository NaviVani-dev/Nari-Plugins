shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec2 resolution = vec2(256.0, 192.0);
uniform int frame = 0;
uniform int running = 0;
uniform float fade = 4.0;

vec3 at(vec2 pixel, vec2 offset) {
	vec2 spot = clamp(pixel + vec2(offset.x, -offset.y), vec2(0.0), resolution - 1.0);
	return texture(screen, (spot + 0.5) / resolution).rgb;
}

void fragment() {
	vec2 pixel = floor(SCREEN_UV * resolution);
	vec3 total;
	if (running == 0) {
		total = (at(pixel, vec2(1.0, 0.0)) + at(pixel, vec2(-1.0, 0.0)) + at(pixel, vec2(0.0, 1.0)) + at(pixel, vec2(0.0, -1.0))) * 0.25;
	} else {
		total = (at(pixel, vec2(1.0, 0.0)) + at(pixel, vec2(0.0, 1.0))) * 0.26890756;
		total += at(pixel, vec2(0.0, 0.0)) * 0.13445378;
		total += (at(pixel, vec2(1.0, -1.0)) + at(pixel, vec2(-1.0, 1.0))) * 0.06722689;
		total += (at(pixel, vec2(-1.0, 0.0)) + at(pixel, vec2(0.0, -1.0))) * 0.05042017;
		total += at(pixel, vec2(-1.0, -1.0)) * 0.02521008;
		total += (at(pixel, vec2(1.0, -2.0)) + at(pixel, vec2(-2.0, 1.0)) + at(pixel, vec2(-2.0, 0.0)) + at(pixel, vec2(0.0, -2.0))) * 0.01680672;
	}
	vec3 value = max(floor(total * 255.0 + 0.001) - fade, vec3(0.0)) / 255.0;
	COLOR = vec4(frame < 2 ? vec3(0.0) : value, 1.0);
}
