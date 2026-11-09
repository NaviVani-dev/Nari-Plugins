shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int frame = 0;
uniform vec4 kinds = vec4(0.0);
uniform vec4 inner = vec4(0.0);
uniform vec4 a0 = vec4(0.0);
uniform vec4 b0 = vec4(0.0);
uniform vec4 c0 = vec4(0.0);
uniform vec4 d0 = vec4(0.0);
uniform vec4 a1 = vec4(0.0);
uniform vec4 b1 = vec4(0.0);
uniform vec4 c1 = vec4(0.0);
uniform vec4 d1 = vec4(0.0);
uniform vec4 a2 = vec4(0.0);
uniform vec4 b2 = vec4(0.0);
uniform vec4 c2 = vec4(0.0);
uniform vec4 d2 = vec4(0.0);
uniform vec4 a3 = vec4(0.0);
uniform vec4 b3 = vec4(0.0);
uniform vec4 c3 = vec4(0.0);
uniform vec4 d3 = vec4(0.0);
uniform float stage = 1.0;

const float SIZE = 512.0;
const float CENTER = 256.0;

vec2 polar(vec2 p, vec4 a, vec4 b) {
	vec2 pivot = b.x > 0.5 ? b.yz : vec2(CENTER);
	vec2 d = p - pivot;
	float r = length(d);
	float share = r / a.z;
	float angle = atan(d.y, d.x);
	float reach = r - a.w * share * share * share;
	angle += a.x > 0.5 ? sin(a.y * share * PI) * b.w : share * b.w;
	return trunc(vec2(cos(angle), sin(angle)) * reach) + pivot;
}

vec2 weave(vec2 p, vec4 a) {
	float cell = a.x;
	float shift = a.y;
	vec2 m = mod(p, cell * 2.0);
	if (a.z > 0.5) {
		return vec2(p.x, p.y + (m.x <= cell ? -shift : shift));
	}
	if (m.y > cell) {
		if (SIZE - p.x < cell && m.x > m.y - cell) {
			return vec2(p.x, p.y + shift);
		}
		return vec2(p.x + shift, p.y);
	}
	if (p.x < cell && SIZE - p.x > m.y) {
		return vec2(p.x, p.y + shift);
	}
	return vec2(p.x - shift, p.y);
}

vec2 stretch(vec2 p, vec4 a, vec4 b) {
	vec2 q = p;
	if (a.x > 0.5) {
		int type = int(a.y);
		bool fx = type == 0 || type == 3 || type == 5 || type == 7;
		bool mx = type == 1 || type == 4 || type == 6;
		bool fy = type == 3 || type == 6 || type == 7;
		bool my = type == 2 || type == 4 || type == 5;
		vec2 grow = 1.0 + a.zw;
		vec2 flip = SIZE - p - 1.0;
		if (fx) {
			q.x = trunc(p.x * grow.x);
		}
		if (mx) {
			q.x = p.x - trunc(flip.x * grow.x - flip.x);
		}
		if (fy) {
			q.y = trunc(p.y * grow.y);
		}
		if (my) {
			q.y = p.y - trunc(flip.y * grow.y - flip.y);
		}
	} else {
		q = p + b.xy;
	}
	if (b.z > 1.5) {
		q.y += trunc(sin(p.x / SIZE * b.w * PI) * 3.0 * b.x);
	} else if (b.z > 0.5) {
		q.x += trunc(sin(p.y / SIZE * b.w * PI) * 3.0 * b.y);
	}
	return q;
}

vec2 single(int kind, vec2 p, vec4 a, vec4 b) {
	if (kind == 1) {
		return polar(p, a, b);
	}
	if (kind == 2) {
		return weave(p, a);
	}
	if (kind == 3) {
		return stretch(p, a, b);
	}
	return p;
}

vec2 mirror(int kind, vec2 p, vec4 a, vec4 b, vec4 c, vec4 d) {
	int mode = int(a.x);
	bool folded = false;
	vec2 q = p;
	if (mode == 0) {
		if (p.x > CENTER) {
			q.x = SIZE - p.x;
			folded = true;
		}
		if (p.y > CENTER) {
			q.y = SIZE - p.y;
			folded = true;
		}
	} else if (mode == 1) {
		if (SIZE * p.y < SIZE * p.x) {
			if (SIZE * p.y < (SIZE - p.x) * SIZE) {
				if (CENTER <= p.x) {
					q.x = CENTER * 2.0 - p.x;
					return q;
				}
				return single(kind, p, c, d);
			}
			q.x = (CENTER - p.x) + SIZE;
		} else {
			if ((SIZE - p.x) * SIZE <= SIZE * p.y) {
				q.y = SIZE - p.y;
				if (CENTER < p.x) {
					q.x = CENTER * 2.0 - p.x;
				}
				return q;
			}
			q.x = CENTER - p.x;
		}
		q.y = p.y < CENTER ? CENTER - p.y : p.y - CENTER;
		return q;
	} else if (mode == 2) {
		vec2 e = p - CENTER;
		float r = length(e);
		float band = SIZE * 0.3535;
		if (int(r / band) % 2 != 0) {
			float angle = atan(e.y, e.x);
			float mapped = r - (r - band * floor(r / band)) * 2.0;
			return trunc(vec2(cos(angle), sin(angle)) * mapped) + CENTER;
		}
		if (p.x > CENTER) {
			q.x = SIZE - p.x;
			folded = true;
		}
		if (p.y > CENTER) {
			q.y = SIZE - p.y;
			folded = true;
		}
	} else {
		if (length(p - CENTER) >= a.y) {
			return p + a.zw;
		}
	}
	if (folded) {
		return q;
	}
	return single(kind, p, c, d);
}

vec2 apply(int kind, int child, vec2 p, vec4 a, vec4 b, vec4 c, vec4 d) {
	if (kind == 4) {
		return mirror(child, p, a, b, c, d);
	}
	return single(kind, p, a, b);
}

vec2 guard(vec2 to, vec2 from) {
	return vec2(to.x < 0.0 || to.x >= SIZE ? from.x : to.x, to.y < 0.0 || to.y >= SIZE ? from.y : to.y);
}

vec2 pair_old(vec2 p) {
	vec2 q = guard(apply(int(kinds.x + 0.5), int(inner.x + 0.5), p, a0, b0, c0, d0), p);
	if (kinds.y > 0.5) {
		vec2 r = guard(apply(int(kinds.y + 0.5), int(inner.y + 0.5), q, a1, b1, c1, d1), q);
		return trunc((r + p) * 0.5);
	}
	return q;
}

vec2 pair_new(vec2 p) {
	vec2 q = guard(apply(int(kinds.z + 0.5), int(inner.z + 0.5), p, a2, b2, c2, d2), p);
	if (kinds.w > 0.5) {
		vec2 r = guard(apply(int(kinds.w + 0.5), int(inner.w + 0.5), q, a3, b3, c3, d3), q);
		return trunc((r + p) * 0.5);
	}
	return q;
}

vec3 fetch(vec2 at) {
	return floor(texture(screen, (clamp(at, vec2(0.0), vec2(SIZE - 1.0)) + 0.5) / SIZE).rgb * 255.0 + 0.5);
}

void fragment() {
	vec2 p = floor(UV * SIZE);
	vec2 to = pair_new(p);
	if (stage < 1.0) {
		to = trunc(mix(pair_old(p), to, stage));
	}
	vec3 center = fetch(to);
	vec3 side = floor((fetch(to + vec2(-1.0, 0.0)) + fetch(to + vec2(1.0, 0.0)) + fetch(to + vec2(0.0, -1.0)) + fetch(to + vec2(0.0, 1.0))) * 0.25);
	vec3 color = floor((center + side * 3.0) * 0.25) / 255.0;
	COLOR = vec4(frame < 2 ? vec3(0.0) : color, 1.0);
}
