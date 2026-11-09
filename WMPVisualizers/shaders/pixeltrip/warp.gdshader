shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec2 basis = vec2(640.0, 480.0);
uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec2 shift = vec2(0.0, 0.0);
uniform vec2 scale = vec2(0.005, 0.005);
uniform float reach = 2.0;
uniform float fade = 0.0;
uniform int first = 0;
uniform int second = -1;
uniform float a[12];
uniform float b[12];
uniform int frame = 0;

float amount(float value, float on, float flip, float r, float inv) {
	if (on < 0.5) {
		return value;
	}
	return flip > 0.5 ? (reach - r) * inv * value : inv * r * value;
}

float power(float base, float exponent) {
	float result = pow(abs(base), exponent);
	return mod(exponent, 2.0) > 0.5 && base < 0.0 ? -result : result;
}

float pick(int code, float value) {
	return code == 0 ? cos(value) : sin(value);
}

void step_warp(int kind, float p[12], vec2 u, inout float r, inout float t) {
	float inv = 1.0 / reach;
	if (kind == 0) {
		float v = amount(p[0], p[1], p[2], r, inv);
		r -= (p[3] * reach - r) * p[4] * r;
		t -= v + sin(inv * r * r * p[5]) * p[6];
	} else if (kind == 1) {
		t += sin((reach - r) * 0.3986) * p[0] * r;
		int form = int(p[1]);
		float x = (reach - r) * inv;
		float c = 0.18;
		if (form == 0) {
			r += atan(reach - r) * c;
		} else if (form == 1) {
			r += atan(inv * r) * c;
		} else if (form == 2) {
			r += atan(x) * c;
		} else if (form == 3) {
			r += cos(x) * c;
		} else if (form == 4) {
			r += atan(x) * x * c;
		} else if (form == 5) {
			r += cos(x) * x * c;
		} else if (form == 6) {
			r += sin(x) * x * c;
		} else if (form == 7) {
			r += sinh(x) * x * c;
		} else if (form == 8) {
			r += cosh(x) * x * c;
		} else {
			r += tanh(x) * x * c;
		}
	} else if (kind == 2) {
		float v = amount(p[0], p[1], p[2], r, inv);
		vec2 q = p[3] > 0.5 ? abs(u) : u;
		r += q.x * q.y * p[4] * inv * p[5];
		t -= sin(r * p[6]) * p[7] + v;
		if (p[8] > 0.5) {
			t -= sin(r * p[9]) * p[10];
		}
	} else if (kind == 3) {
		float v = amount(p[0], p[1], p[2], r, inv);
		t += (sin((reach - r) * 0.381) * 0.6 + sin((reach - r) * 0.539) * 0.4) * v;
		float d = inv * r * r;
		r += (sin(d * 0.339) * 0.6 + sin(d * 0.276) * 0.4) * p[3];
		if (p[4] > 0.5) {
			t -= sin((p[5] > 0.5 ? reach - r : r) * p[6]) * p[7];
		}
	} else if (kind == 4) {
		int form = int(p[0]);
		float s = form == 0 ? abs(u.x) : form == 1 ? abs(u.y) : sin(inv * r) * reach;
		r -= 0.01;
		t += sin(r * 11.0 - s * 3.3) * (1.3 - r) * 0.16;
	} else if (kind == 5) {
		float v = amount(p[0], p[1], p[2], r, inv);
		r += inv * r * p[3];
		t -= v;
		if (p[4] > 0.5) {
			t -= sin(p[5] * r) * p[6];
		}
	} else if (kind == 6) {
		r -= r * inv * p[0];
		float old = t;
		t -= p[1] < 0.5 ? p[2] : (p[3] < 0.5 ? r : reach - r) * inv * p[2];
		int group = int(p[4]);
		int form = int(p[5]);
		int gc = form == 0 || form == 2 ? 0 : 1;
		int hc = form == 0 || form == 3 ? 0 : 1;
		float rr = group == 3 ? reach - r : r;
		if (group == 1) {
			r += pick(hc, t * p[6]) * p[7];
			t += pick(gc, r * p[8]) * p[9];
		} else {
			float base = t + pick(gc, rr * p[8]) * p[9];
			float angle = group == 0 ? old : group == 2 ? base : atan(u.x, u.y);
			r += pick(hc, angle * p[6]) * p[7];
			t = base;
		}
	} else if (kind == 7) {
		t += amount(p[0], p[1], p[2], r, inv);
		r *= atan(p[3] - (reach - r)) * p[4] + 1.0;
	} else if (kind == 8) {
		t += amount(p[0], p[1], p[2], r, inv);
		r *= (p[3] < 0.5 ? sin(p[4] - r) : atan(p[4] - r)) * p[5] + 1.0;
		if (p[6] > 0.5) {
			t -= sin((p[7] > 0.5 ? reach - r : r) * p[8]) * p[9];
		}
	} else if (kind == 9) {
		t += amount(p[0], p[1], p[2], r, inv);
		r += sin(p[3] * r) * p[4];
	} else if (kind == 10) {
		r -= sin(p[0] * r) * p[1] + p[2];
		t += amount(p[3], p[4], p[5], r, inv);
		if (p[6] > 0.5) {
			t -= sin(p[7] * r) * p[8];
		}
	} else {
		r -= p[0] * r * inv * r;
		t -= power(cos(r), p[1]) * p[2];
		if (p[3] > 0.5) {
			t -= sin(p[4] * r) * p[5];
		}
	}
}

void fragment() {
	vec2 point = SCREEN_UV * basis + shift;
	vec2 edge = basis - 1.0;
	point = mix(point, edge * 2.0 - point + 1.0, step(edge, point));
	point = abs(point);
	vec2 u = (point - basis * 0.5) * scale;
	float r = length(u);
	float t = atan(u.y, u.x);
	step_warp(first, a, u, r, t);
	if (second >= 0) {
		step_warp(second, b, u, r, t);
	}
	vec2 source = vec2(cos(t), sin(t)) * r / scale + basis * 0.5;
	vec3 color = vec3(0.0);
	if (frame >= 2 && source.x >= 0.0 && source.y >= 0.0 && source.x < basis.x && source.y < basis.y) {
		vec2 texel = source * resolution / basis - 0.5;
		vec2 corner = floor(texel);
		vec2 part = floor((texel - corner) * 256.0);
		ivec2 at = ivec2(corner);
		ivec2 top = ivec2(resolution) - 1;
		vec3 c00 = round(texelFetch(screen, clamp(at, ivec2(0), top), 0).rgb * 255.0);
		vec3 c10 = round(texelFetch(screen, clamp(at + ivec2(1, 0), ivec2(0), top), 0).rgb * 255.0);
		vec3 c01 = round(texelFetch(screen, clamp(at + ivec2(0, 1), ivec2(0), top), 0).rgb * 255.0);
		vec3 c11 = round(texelFetch(screen, clamp(at + ivec2(1, 1), ivec2(0), top), 0).rgb * 255.0);
		vec3 upper = floor(c00 + (c10 - c00) * part.x / 256.0);
		vec3 lower = floor(c01 + (c11 - c01) * part.x / 256.0);
		color = floor(upper + (lower - upper) * part.y / 256.0);
		color.b = max(color.b - fade, 0.0);
		color /= 255.0;
	}
	COLOR = vec4(color, 1.0);
}
