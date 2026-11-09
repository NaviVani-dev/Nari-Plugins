shader_type canvas_item;
render_mode blend_disabled, skip_vertex_transform;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D history : filter_nearest, repeat_disable;
uniform float heights[352];
uniform int count = 349;
uniform int field_width = 350;
uniform int source = 0;
uniform int mode = 5;
uniform int roll = 0;
uniform int stripe = 0;
uniform int reach = 0;
uniform int amount = 0;
uniform ivec2 center = ivec2(175, 160);
uniform vec2 wave = vec2(0.0, 0.0);
uniform float wave_curve = 0.0;
uniform int wave_base = 0;
uniform vec2 phase = vec2(0.0, 0.0);
uniform int turn_x = 0;
uniform int turn_y = 0;
uniform int turn_z = 0;
uniform int angle_x = 0;
uniform int angle_y = 0;
uniform int angle_z = 0;
uniform float twist = 0.0;
uniform int left = 0;
uniform int top = 0;
uniform ivec2 drift = ivec2(0, 0);
uniform int fade = 0;

varying vec4 shade;

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
	if (x >= count) {
		return vec4(0.0);
	}
	int value = int(heights[x]);
	if (mode == 20) {
		if (value <= 2) {
			return vec4(0.0);
		}
		int row = 160 - value / 2 + 30 - y;
		if (row < 0 || row >= 31) {
			return vec4(0.0);
		}
		int index = 3 * value + 5 - 5 * row;
		int old = (max(index, 0) / 3) % 256;
		int gap = min(old + 1, 256 - old);
		int alpha = gap <= 140 ? 180 - gap * 180 / 140 : 0;
		gap = min(row + 1, 31 - row);
		if (gap <= 5) {
			alpha = 180 - gap * 36;
		}
		vec3 color = max(tone(index) * 255.0 - float(alpha), vec3(0.0)) / 255.0;
		return vec4(color, 1.0 - float(alpha) / 255.0);
	}
	int row = 319 - y - (160 - value / 2);
	if (row < 0 || row >= value) {
		return vec4(0.0);
	}
	int first = (value + 1) / 2;
	int gap = min(min(row + 1, value - row), 255);
	int alpha = gap <= reach ? min(amount - gap * amount / reach, 255) : 0;
	return vec4(tone(row < first ? row : first - (row - first)), 1.0 - float(alpha) / 255.0);
}

float degrees_cos(int value) {
	return cos(float(value % 360) * 0.017453292);
}

float degrees_sin(int value) {
	return sin(float(value % 360) * 0.017453292);
}

void fragment() {
	COLOR = shade;
}

void vertex() {
	int width = field_width;
	int x = INSTANCE_ID % width;
	int y = INSTANCE_ID / width;
	vec4 pixel = bar(x, y);
	if (source == 1) {
		if (pixel.a <= 0.002) {
			pixel = textureLod(history, vec2((float(x) + 0.5) / float(width), (319.5 - float(y)) / 320.0), 0.0);
		}
		pixel.a -= float(fade) / 255.0;
		x += drift.x;
		y += drift.y;
	}
	vec2 place = vec2(-10.0);
	shade = vec4(0.0);
	if (pixel.a > 0.002) {
		float dx = float(x - center.x);
		float dy = float(y - center.y);
		float px = dx;
		float py = dy;
		if (wave.x != 0.0) {
			int angle = abs(int(abs(dy) * wave.x + phase.x)) % 360;
			px += degrees_cos(angle) * (dy * dy * wave_curve + float(wave_base));
		}
		if (wave.y != 0.0) {
			int angle = abs(int(abs(dx) * wave.y + phase.y)) % 360;
			py += degrees_cos(angle) * (dx * dx * wave_curve + float(wave_base));
		}
		int spin = 0;
		if (twist != 0.0) {
			spin = int(float(int(px * px + py * py)) * twist);
		}
		if (turn_z != 0) {
			int angle = (angle_z - spin) % 360;
			float c = degrees_cos(angle);
			float s = degrees_sin(angle);
			float was = px;
			px = c * px + s * py;
			py = c * py - s * was;
		}
		if (turn_x != 0) {
			py *= degrees_cos(angle_x - spin);
		}
		if (turn_y != 0) {
			px *= degrees_cos(angle_y - spin);
		}
		int nx = int(px) + center.x;
		int ny = int(py) + center.y;
		if (nx >= 0 && ny >= 0 && nx < width && ny < 320) {
			place = vec2(float(nx + left), float(top + 319 - ny));
			shade = source != 0 ? pixel : vec4(max(pixel.rgb - (1.0 - pixel.a), vec3(0.0)), 1.0);
		}
	}
	VERTEX = place + VERTEX;
}
