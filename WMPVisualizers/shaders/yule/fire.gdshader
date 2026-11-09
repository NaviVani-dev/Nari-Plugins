shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D hearth : filter_linear;
uniform sampler2D flame1 : filter_linear;
uniform sampler2D flame2 : filter_linear;
uniform sampler2D flame3 : filter_linear;
uniform sampler2D flame4 : filter_linear;
uniform sampler2D turbx : filter_linear, repeat_enable;
uniform sampler2D turby : filter_linear, repeat_enable;
uniform float clock = 0.0;
uniform float scroll = 0.0;
uniform vec4 heights = vec4(1.0);
uniform vec4 tint = vec4(1.0);

vec3 flame(vec3 base, sampler2D tex, vec2 uv, float seed, float pixels, float rise) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return base;
	}
	float swing_x = fract(clock / (30.0 * (0.75 + 0.5 * fract(seed * 7.13))) + seed) * 3.0;
	float swing_y = fract(clock / (0.75 + 0.5 * fract(seed * 3.71)) + seed) * 3.0;
	vec3 tx = texture(turbx, uv * pixels / 256.0 + vec2(0.0, scroll)).rgb;
	vec3 ty = texture(turby, uv * pixels / 256.0 + vec2(0.0, scroll)).rgb;
	int x1 = int(swing_x) % 3;
	int y1 = int(swing_y) % 3;
	float dx = mix(tx[x1], tx[(x1 + 1) % 3], fract(swing_x)) - 0.5;
	float dy = mix(ty[y1], ty[(y1 + 1) % 3], fract(swing_y)) - 0.5;
	if (uv.y < 1.0 - rise) {
		return base;
	}
	vec2 at = vec2(uv.x, (uv.y - (1.0 - rise)) / rise) + vec2(dx, dy) * 256.0 / pixels;
	if (at.x < 0.0 || at.y < 0.0 || at.x > 1.0 || at.y > 1.0) {
		return base;
	}
	vec4 color = texture(tex, at);
	return base * (1.0 - color.a) + color.rgb * color.a;
}

void fragment() {
	vec2 p = UV;
	vec3 color = texture(hearth, p).rgb * tint.rgb;
	color = flame(color, flame4, vec2(-1.6408 * p.x + -0.0000 * p.y + 1.0056, -0.3672 * p.x + 1.2789 * p.y + 0.2363) / (-0.5603 * p.x + -0.0000 * p.y + 1.0), 0.1, 256.0, heights.x);
	color = flame(color, flame2, vec2(-1.3826 * p.x + -0.0000 * p.y + 1.4765, -0.0000 * p.x + 1.2506 * p.y + 0.1292) / (-0.0000 * p.x + -0.0000 * p.y + 1.0), 0.37, 256.0, heights.y);
	color = flame(color, flame3, vec2(-2.5181 * p.x + -0.0000 * p.y + 1.5003, -0.4615 * p.x + 1.1660 * p.y + 0.2121) / (-0.9143 * p.x + -0.0000 * p.y + 1.0), 0.61, 128.0, heights.z);
	color = flame(color, flame1, vec2(-3.0032 * p.x + -0.0000 * p.y + 2.1454, -0.0000 * p.x + 2.4730 * p.y + -0.8700) / (0.0000 * p.x + -0.0000 * p.y + 1.0), 0.83, 128.0, heights.w);
	COLOR = vec4(color, 1.0);
}
