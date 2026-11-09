shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform sampler2D lut_a : filter_nearest;
uniform sampler2D lut_b : filter_nearest;
uniform float fade = 0.0;
uniform int frame = 0;
uniform vec4 ball1 = vec4(-100.0, -100.0, 0.0, 0.0);
uniform vec4 ball2 = vec4(-100.0, -100.0, 0.0, 0.0);
uniform vec4 ball_color = vec4(1.0);

vec3 fetch(ivec2 at) {
	return floor(texelFetch(screen, ivec2(clamp(at.x, 0, 255), clamp(at.y, 0, 255)), 0).rgb * 255.0 + 0.5);
}

vec3 disc(vec3 base, vec2 p, vec4 ball) {
	if (ball.z < 1.0) {
		return base;
	}
	vec2 d = p - ball.xy;
	float dist = dot(d, d);
	float r = ball.z;
	if (dist > (r + 8.0) * (r + 8.0)) {
		return base;
	}
	float value = (r * r - dist) / r;
	vec3 color = ball_color.rgb * 255.0;
	if (value >= 0.0) {
		float t = value / r;
		base = mix(color, base, cos(t * t * 1.5708) * ball.w);
	}
	if (value > -1.5708 && value < 1.5708) {
		base = mix(base, color, cos(abs(value)));
	}
	return base;
}

void fragment() {
	ivec2 p = ivec2(FRAGCOORD.xy);
	vec2 near = mix(texelFetch(lut_a, p, 0).rg, texelFetch(lut_b, p, 0).rg, fade);
	ivec2 at = ivec2(near + 0.5);
	vec3 sum = fetch(at + ivec2(1, 0)) + fetch(at - ivec2(1, 0)) + fetch(at + ivec2(0, 1)) + fetch(at - ivec2(0, 1));
	vec3 color = floor((floor(sum / 4.0) * 3.0 + fetch(at)) / 4.0);
	if (p.y == 0 || p.y == 255) {
		color = vec3(0.0);
	}
	color = disc(color, vec2(p), ball1);
	color = disc(color, vec2(p), ball2);
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color / 255.0, 1.0);
}
