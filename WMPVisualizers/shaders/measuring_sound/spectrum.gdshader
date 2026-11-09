shader_type canvas_item;
render_mode blend_disabled;

uniform float bands[32];
uniform float bars[16];
uniform vec2 resolution = vec2(640.0, 480.0);
uniform int frame = 0;
uniform vec4 background = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ink = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 bar_color = vec4(0.353, 0.157, 0.157, 1.0);
uniform vec4 line_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float channels = 0.0;
uniform float bar_width = 170.0;
uniform float stretch = 1.0;
uniform float show_spectrum = 1.0;
uniform float grid_set = 0.0;

const float GRID_A[10] = float[](0.0, 20.0, 43.0, 90.0, 136.0, 182.0, 229.0, 461.0, 925.0, 1023.0);
const float GRID_B[10] = float[](0.0, 18.0, 41.0, 88.0, 134.0, 180.0, 227.0, 458.0, 922.0, 1021.0);

float hash(float x, float s) {
	return fract(sin(x * 12.9898 + s * 78.233) * 43758.5453);
}

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

void fragment() {
	vec2 pixel = vec2(UV.x * 640.0, UV.y * resolution.y);
	vec4 color = background;
	float column = floor(pixel.x);
	if (grid_set > 0.5) {
		float pitch = resolution.y / 256.0;
		for (int i = 0; i < 10; i++) {
			float x = grid_set > 1.5 ? GRID_B[i] : GRID_A[i];
			if (column == x) {
				color = line_color;
			}
		}
		float y = floor(pixel.y);
		if (y == floor(resolution.y - pitch * 64.0) || y == floor(resolution.y - pitch * 128.0) || y == floor(resolution.y - pitch * 192.0) || y == floor(resolution.y) - 1.0) {
			color = line_color;
		}
	}
	if (channels > 0.5) {
		int slot = int(column / bar_width);
		if (slot < 16 && float(slot) < channels && pixel.y >= resolution.y * (1.0 - bars[slot] / 256.0)) {
			color = bar_color;
		}
	}
	if (show_spectrum > 0.5) {
		float bin = floor(column / stretch);
		float spread = hash(bin, float(frame));
		float detail = bin < 64.0 ? 0.3 + spread * spread * spread * 2.6 : 0.3 + spread * spread * 0.85;
		float height = min(255.0, amount(bin) * detail);
		if (pixel.y >= resolution.y * (1.0 - height / 256.0)) {
			color = ink;
		}
	}
	COLOR = color;
}
