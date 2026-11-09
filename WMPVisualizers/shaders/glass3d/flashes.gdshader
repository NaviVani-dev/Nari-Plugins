shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float erase = 0.05;
uniform int frame = 0;

float hash(vec2 p, float s) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + s) * 43758.5453);
}

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	if (hash(FRAGCOORD.xy, float(frame % 251)) < erase) {
		color = vec3(0.0);
	}
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color, 1.0);
}
