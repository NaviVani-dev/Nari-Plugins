shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec2 center_low = vec2(0.0);
uniform vec2 center_mid = vec2(0.0);
uniform vec2 center_high = vec2(0.0);
uniform vec4 radius = vec4(0.0);
uniform int mode = 0;
uniform int keep = 224;
uniform int frame = 0;

int ring(vec2 point, vec2 center, float reach, float period) {
	vec2 delta = abs(floor(point) - center);
	float distance_to = delta.x >= 512.0 || delta.y >= 512.0 ? 0.0 : round(length(delta));
	if (distance_to < reach) {
		return 255;
	}
	return int(round(cos(floor((distance_to - reach) * 1800.0 / period) * PI / 1800.0) * 127.0)) + 128;
}

ivec3 paint(int r, int g, int b) {
	int v = (4 * r + 3 * g + b) / 8;
	if (mode == 0) {
		return ivec3(r >> 1, g >> 1, b >> 1);
	} else if (mode == 1) {
		int c = min(255 - v + 64, 255);
		return ivec3(c, c, 255);
	} else if (mode == 2) {
		return ivec3(255 - v, 0, v);
	} else if (mode == 3) {
		return ivec3(v - g / 8, 0, v - r / 8);
	} else if (mode == 4) {
		int c = min(min(b, g), r);
		return ivec3(c, 255 - c, c);
	} else if (mode == 5) {
		int c = 128 - v;
		return ivec3(c < 0 ? 255 : 0, c < 0 ? 255 : 0, c & 255);
	} else if (mode == 6) {
		int c = 224 - 2 * v;
		return ivec3(c < 0 ? 255 : 0, c & 255, 0);
	}
	int c = v + 192;
	return ivec3((c >> 8) & 255, c & 255, 0);
}

void fragment() {
	vec2 point = SCREEN_UV * resolution * 480.0 / resolution.y;
	ivec3 now = paint(ring(point, center_low, radius.x, 32.0), ring(point, center_mid, radius.y, 16.0), ring(point, center_high, radius.z, 8.0));
	if (frame < 2) {
		COLOR = vec4(vec3(now) / 255.0, 1.0);
	} else {
		ivec3 before = ivec3(texture(screen, SCREEN_UV).rgb * 255.0 + 0.5);
		COLOR = vec4(vec3((before * keep >> 8) + (now * (256 - keep) >> 8)) / 255.0, 1.0);
	}
}
