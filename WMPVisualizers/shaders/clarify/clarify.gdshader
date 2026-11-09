shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform float left[400];
uniform float right[400];
uniform vec2 offset_a = vec2(0.0);
uniform vec2 offset_b = vec2(0.0);
uniform vec4 tint_a = vec4(0.0);
uniform vec4 tint_b = vec4(0.0);
uniform bool split = false;
uniform int frame = 0;

ivec3 rings(vec2 point, vec2 center, vec4 tint, int channel) {
	int bin = min(int(round(length(floor(point) - center))), 399);
	int value = channel == 0 ? int(left[bin]) : channel == 1 ? int(right[bin]) : (int(left[bin]) + int(right[bin])) / 2;
	return ivec3(tint.rgb) * value / 255;
}

void fragment() {
	float scale = 480.0 / resolution.y;
	vec2 space = resolution * scale;
	vec2 middle = floor(space * 0.5);
	float far = length((SCREEN_UV - 0.5) * space);
	float shrink = far > 1.0 ? (1.0 - 0.5 / far) * 0.98 + 0.01 : 0.0;
	vec2 from = (SCREEN_UV - 0.5) * shrink + 0.5;
	vec2 point = from * space;
	ivec3 now = rings(point, middle + offset_a, tint_a, split ? 0 : 2);
	if (split) {
		now = now ^ rings(point, middle + offset_b, tint_b, 1);
	}
	if (frame < 2) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		ivec3 before = ivec3(texture(screen, from).rgb * 255.0);
		COLOR = vec4(vec3((before * 246 >> 8) + (now * 10 >> 8)) / 255.0, 1.0);
	}
}
