shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform sampler2D warp : filter_linear, repeat_disable;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform float jitter = 0.0;
uniform int frame = 0;

float hash(vec2 p, float s) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + s) * 43758.5453);
}

void fragment() {
	vec2 up = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y);
	vec2 cell = floor(up * resolution);
	vec2 move = texture(warp, up).rg;
	if (jitter > 0.0) {
		move += (vec2(hash(cell, 1.0), hash(cell, 2.0)) - 0.5) * jitter;
	}
	vec2 target = (cell + 0.5 + move) / resolution;
	float value = texture(screen, vec2(target.x, 1.0 - target.y)).r * 0.96875 - 0.5 / 255.0;
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(vec3(max(value, 0.0)), 1.0);
}
