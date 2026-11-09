shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float bands[32];
uniform float smooth_amount = 0.0;
uniform float floor_value = 0.35;
uniform float texel = 0.0009765625;

float spectrum(float position) {
	float scaled = clamp(position, 0.0, 1.0) * 31.0;
	int index = int(floor(scaled));
	return mix(bands[index], bands[min(index + 1, 31)], fract(scaled));
}

void fragment() {
	if (SCREEN_UV.y > 1.0 - texel) {
		float raw = max(0.0, (spectrum(abs(SCREEN_UV.x - 0.5) * 2.0) - floor_value) / (1.0 - floor_value));
		float previous = texture(screen, vec2(SCREEN_UV.x, SCREEN_UV.y)).r;
		COLOR = vec4(vec3(mix(raw, previous, smooth_amount)), 1.0);
	} else {
		COLOR = vec4(texture(screen, vec2(SCREEN_UV.x, SCREEN_UV.y + texel)).rgb, 1.0);
	}
}
