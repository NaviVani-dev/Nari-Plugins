shader_type canvas_item;
render_mode blend_disabled;

uniform float bands[32];
uniform float wave[128];
uniform vec2 resolution = vec2(640.0, 480.0);

const float HUE = 144.0;
const float SATURATION = 168.0;

float amount(float bin) {
	float frequency = (bin + 0.5) * 21.533;
	float at = clamp(log(max(frequency, 40.0) / 40.0) / 0.18723 - 0.5, 0.0, 31.0);
	int index = int(at);
	float value = mix(bands[index], bands[min(index + 1, 31)], at - float(index));
	if (value <= 0.0) {
		return 0.0;
	}
	return min(255.0, pow(10.0, (value * 66.0 - 66.0 - at * 0.9) / 40.0) * 905.0);
}

float spiral(float column, float row) {
	float ring = min(min(column, row), min(31.0 - column, 31.0 - row));
	float side = 32.0 - ring * 2.0;
	float before = 0.0;
	for (float k = 0.0; k < ring; k += 1.0) {
		before += 2.0 * (32.0 - 2.0 * k) + 2.0 * (30.0 - 2.0 * k);
	}
	if (column == ring) {
		return before + (31.0 - ring - row);
	}
	if (row == ring) {
		return before + side + (column - ring - 1.0);
	}
	if (column == 31.0 - ring) {
		return before + side + side - 2.0 + (row - ring);
	}
	return before + side + side - 2.0 + side + (31.0 - ring - column - 1.0);
}

float channel(float m1, float m2, float hue) {
	hue = mod(hue, 240.0);
	if (hue < 40.0) {
		return m1 + (m2 - m1) * hue / 40.0;
	}
	if (hue < 120.0) {
		return m2;
	}
	if (hue < 160.0) {
		return m1 + (m2 - m1) * (160.0 - hue) / 40.0;
	}
	return m1;
}

vec3 hls(float hue, float light, float saturation) {
	float l = light / 240.0;
	float s = saturation / 240.0;
	float m2 = l <= 0.5 ? l * (1.0 + s) : l + s - l * s;
	float m1 = 2.0 * l - m2;
	return vec3(channel(m1, m2, hue + 80.0), channel(m1, m2, hue), channel(m1, m2, hue - 80.0));
}

void fragment() {
	vec2 cell = floor(resolution / 32.0);
	vec2 margin = floor((resolution - cell * 32.0) * 0.5);
	vec2 local = floor(UV * resolution) - margin;
	vec2 grid = floor(local / cell);
	vec3 color = vec3(0.0);
	if (grid.x >= 0.0 && grid.y >= 0.0 && grid.x < 32.0 && grid.y < 32.0) {
		float index = spiral(grid.x, grid.y);
		float sample_at = mod(index * 0.25, 128.0);
		float byte = wave[int(sample_at)] * 127.0 + 128.0;
		float frequency = amount(index);
		float light = min(240.0, floor(frequency * 0.53) + 15.0);
		float hue = floor((byte - 127.0) * 1.75) + HUE;
		vec2 inner = local - grid * cell;
		vec2 half_size = cell * 0.5;
		vec2 radius = max(cell / 2.5 * 0.5, vec2(1.0));
		vec2 q = abs(inner + 0.5 - half_size) - (half_size - radius);
		float shape = length(max(q, 0.0) / radius);
		if (shape < 1.0 && max(q.x, q.y) < radius.x + radius.y) {
			bool edge = shape > 1.0 - 1.2 / min(radius.x, radius.y) || inner.x < 1.0 || inner.y < 1.0 || inner.x >= cell.x - 1.0 || inner.y >= cell.y - 1.0;
			color = edge ? vec3(0.0) : hls(hue, light, SATURATION);
		}
	}
	COLOR = vec4(color, 1.0);
}
