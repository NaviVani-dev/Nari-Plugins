shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec4 drop = vec4(-10.0, -10.0, 0.0, 1.0);
uniform int frame = 0;
uniform float rate = 0.07;
uniform float calm = 0.98;

vec2 cell(ivec2 at) {
	return texelFetch(screen, (at + ivec2(64)) % 64, 0).rg;
}

void fragment() {
	ivec2 at = ivec2(floor(UV * 64.0));
	vec2 here = cell(at);
	float edge = (cell(at + ivec2(1, 0)).r + cell(at - ivec2(1, 0)).r + cell(at + ivec2(0, 1)).r + cell(at - ivec2(0, 1)).r) * 0.16667;
	float corner = (cell(at + ivec2(1, 1)).r + cell(at + ivec2(-1, 1)).r + cell(at + ivec2(1, -1)).r + cell(at + ivec2(-1, -1)).r) * 0.083333;
	float speed = here.g;
	if (abs(speed) > 0.01) {
		speed *= 0.99;
	}
	if (abs(speed) > 20.0) {
		speed *= 0.9;
	}
	speed += (edge + corner - here.r) * rate;
	float height = (here.r + speed) * calm;
	speed *= calm;
	vec2 away = abs(vec2(at) - drop.xy);
	if (away.x < 1.5 && away.y < 1.5) {
		float weight = away.x + away.y < 0.5 ? 0.04 : (away.x + away.y < 1.5 ? 0.02 : 0.03);
		height = drop.z * weight;
	}
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(height, speed, 0.0, 1.0);
}
