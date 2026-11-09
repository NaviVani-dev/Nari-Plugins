shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D history : filter_nearest, repeat_disable;
uniform float heights[352];
uniform int count = 349;
uniform int field_width = 350;
uniform int mode = 5;
uniform int roll = 0;
uniform int reach = 0;
uniform int amount = 0;
uniform int stripe = 0;
uniform int left = 0;
uniform bool overlay = false;
uniform bool copy = false;
uniform ivec2 drift = ivec2(0, 0);
uniform int fade = 0;

vec3 tone(int index) {
	int at = clamp(index, 0, 767);
	int line = (at / 3 - roll) % 256;
	if (line < 0) {
		line += 256;
	}
	return texelFetch(palette, ivec2(at % 3, line), 0).rgb;
}

vec4 rolled(int x, int y) {
	for (int back = 0; back < 3; back++) {
		int column = x - back;
		if (column < 0 || column >= count) {
			continue;
		}
		int value = int(heights[column]);
		if (y <= value) {
			int line = (value - y + stripe) % 256;
			return vec4(texelFetch(palette, ivec2(back, line), 0).rgb, 1.0);
		}
	}
	return vec4(0.0);
}

vec4 bar(int x, int y) {
	if (mode == 1) {
		return rolled(x, y);
	}
	if (x >= count || x < 0) {
		return vec4(0.0);
	}
	int value = int(heights[x]);
	int row = 319 - y - (160 - value / 2);
	if (row < 0 || row >= value) {
		return vec4(0.0);
	}
	int first = (value + 1) / 2;
	int gap = min(min(row + 1, value - row), 255);
	int alpha = gap <= reach ? min(amount - gap * amount / reach, 255) : 0;
	return vec4(tone(row < first ? row : first - (row - first)), 1.0 - float(alpha) / 255.0);
}

void fragment() {
	if (copy) {
		vec2 from = UV + vec2(float(-drift.x) / float(field_width), float(drift.y) / 320.0);
		vec4 pixel = vec4(0.0);
		if (from.x >= 0.0 && from.y >= 0.0 && from.x <= 1.0 && from.y <= 1.0) {
			pixel = texture(history, from);
			pixel.a -= float(fade) / 255.0;
			if (pixel.a <= 0.002) {
				pixel = vec4(0.0);
			}
		}
		COLOR = pixel;
	} else if (overlay) {
		vec4 pixel = texture(history, UV);
		if (pixel.a <= 0.002) {
			discard;
		}
		COLOR = vec4(max(pixel.rgb - (1.0 - pixel.a), vec3(0.0)), 1.0);
	} else {
		int x = int(UV.x * float(field_width));
		int y = 319 - int(UV.y * 320.0);
		vec4 pixel = bar(x - left, y);
		COLOR = vec4(max(pixel.rgb - (1.0 - pixel.a), vec3(0.0)) * step(0.002, pixel.a), 1.0);
	}
}
