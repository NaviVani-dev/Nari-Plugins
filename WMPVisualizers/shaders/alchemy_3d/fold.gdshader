shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D rt : filter_linear;
uniform float crop = 1.0;

vec4 stage_at(vec2 uv) {
	return texture(rt, 0.5 + (uv - 0.5) * crop);
}

uniform float cells = 1.0;
uniform float mirror = 0.0;
uniform float turn = 0.0;

void fragment() {
	vec2 at = (UV - 0.5) * 2.0;
	at = vec2(at.x * cos(turn) - at.y * sin(turn), at.x * sin(turn) + at.y * cos(turn));
	at = at * cells;
	vec2 map = mirror > 0.5 ? abs(fract(at * 0.5) * 2.0 - 1.0) : at * 0.5 + 0.5;
	COLOR = vec4(stage_at(map).rgb, 1.0);
}
