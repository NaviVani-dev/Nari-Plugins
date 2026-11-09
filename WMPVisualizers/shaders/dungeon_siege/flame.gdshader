shader_type canvas_item;

uniform sampler2D palette : filter_nearest;
uniform float heights[64];
uniform float scroll = 0.0;
uniform float radius = 116.0;
uniform float amount = 250.0;

void fragment() {
	float place = UV.x * 63.0;
	float index = floor(place);
	float value = mix(heights[int(index)], heights[int(min(index + 1.0, 63.0))], place - index);
	float above = (1.0 - UV.y) * 320.0;
	float run = value + 64.0 - above;
	if (run < 0.0) {
		discard;
	}
	vec3 color = texture(palette, vec2(0.5, fract((above - value + 255.0 + scroll) / 319.0))).rgb;
	if (run <= radius) {
		float blend = clamp(1.0 + (1.0 - run) / radius, 0.0, 1.0);
		color = mix(color, vec3(1.0, 1.0 / 255.0, 65.0 / 255.0), blend);
		color = max(color - max(0.0, amount - run * amount / radius) / 255.0, vec3(0.0));
	}
	COLOR = vec4(color, 1.0);
}
