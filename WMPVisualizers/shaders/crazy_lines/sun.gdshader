shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D sprite : filter_linear, repeat_disable;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec4 bands[8];
uniform vec4 tint = vec4(1.0, 0.0, 0.5, 1.0);
uniform float sun = 6.0;
uniform float fade = 1.0;
uniform float time = 0.0;

float glow(vec2 offset, vec2 size) {
	return texture(sprite, clamp(offset / size * 0.5 + 0.5, 0.0, 1.0)).r;
}

float band(float index) {
	float base = clamp(floor(index), 0.0, 31.0);
	float next = min(base + 1.0, 31.0);
	float a = bands[int(base) / 4][int(base) % 4];
	float b = bands[int(next) / 4][int(next) % 4];
	return mix(a, b, clamp(index - base, 0.0, 1.0));
}

float linear(float position) {
	float at = log(max(position * 22050.0, 40.0) / 40.0) / log(400.0) * 32.0 - 0.5;
	float value = band(at);
	float rolloff = 1.0 - max(0.0, position - 0.5) * 1.4;
	return clamp(5.0 * pow(10.0, (-66.0 * (1.0 - value) - 0.9 * at) / 32.0), 0.0, 1.0) * min(value * 8.0, 1.0) * rolloff;
}

float hash(float value) {
	return fract(sin(value * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 world = (UV - 0.5) * vec2(resolution.x / resolution.y, 1.0) * 2.0;
	vec2 near = world * 4.0;
	vec3 color = tint.rgb * glow(near, vec2(sun));
	float bin = 402.0 + world.x * 8.0 / 0.04;
	float cell = floor(bin / 5.0);
	float frame_seed = floor(time * 30.0);
	float noise = mix(hash(cell + frame_seed), hash(cell + 1.0 + frame_seed), fract(bin / 5.0));
	float level = pow(linear(max(bin, 1.0) / 1024.0) * (0.75 + noise * 0.5), 0.4);
	level = min(level, 1.0);
	float across = abs(world.y * 8.0 - 7.0);
	color += (tint.rgb * level + vec3(0.05)) * glow(vec2(0.0, across), vec2(1.0, max(level, 0.05))) * 5.0;
	COLOR = vec4(color * fade, 1.0);
}
