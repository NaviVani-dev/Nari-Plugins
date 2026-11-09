shader_type canvas_item;
render_mode blend_disabled;

uniform int kind1 = 0;
uniform vec4 a1 = vec4(0.0);
uniform vec4 b1 = vec4(0.0);
uniform vec4 c1 = vec4(-1.0, 0.0, 0.0, 0.0);
uniform int kind2 = -1;
uniform vec4 a2 = vec4(0.0);
uniform vec4 b2 = vec4(0.0);
uniform vec4 c2 = vec4(-1.0, 0.0, 0.0, 0.0);

const float W = 256.0;
const float H = 256.0;

vec2 inner(vec2 p, int kind, vec4 a, vec4 b) {
	if (kind == 0) {
		if (b.x < 0.5) {
			p += a.xy;
		} else {
			int dir = int(b.y);
			bool left = dir == 0 || dir == 4 || dir == 6;
			bool right = dir == 2 || dir == 5 || dir == 7;
			bool down = dir == 1 || dir == 4 || dir == 7;
			bool up = dir == 3 || dir == 5 || dir == 6;
			if (left) { p.x = floor((a.z + 1.0) * p.x); }
			if (right) { float e = W - p.x - 1.0; p.x = p.x - floor((a.z + 1.0) * e - e); }
			if (down) { p.y = floor((a.w + 1.0) * p.y); }
			if (up) { float e = H - p.y - 1.0; p.y = p.y - floor((a.w + 1.0) * e - e); }
		}
		if (b.z > 0.5 && b.z < 1.5) {
			p.x += floor(sin(p.y / H * b.w * PI) * a.y * 3.0);
		} else if (b.z > 1.5) {
			p.y += floor(sin(p.x / W * b.w * PI) * a.x * 3.0);
		}
		return p;
	}
	if (kind == 1) {
		vec2 d = p - b.xy;
		float r = length(d);
		float reach = length(vec2(W, H)) * 0.5;
		float t = r / reach;
		float r2 = r - reach * a.w * t * t * t;
		float angle = atan(d.y, d.x) + (a.y > 0.5 ? sin(a.z * t * PI * 0.5) : t) * a.x;
		return floor(b.xy + vec2(cos(angle), sin(angle)) * r2);
	}
	if (kind == 2) {
		float cell = a.x;
		float rowp = mod(p.y, cell * 2.0);
		float colp = mod(p.x, cell * 2.0);
		if (a.z < 0.5) {
			p.x += rowp > cell ? a.y : -a.y;
		} else {
			p.y += colp > cell ? -a.y : a.y;
		}
		return p;
	}
	if (kind == 3) {
		vec2 d = vec2(W, H) * 0.5 - p;
		float angle = atan(d.y, d.x) + a.x;
		float r = length(d);
		return floor(vec2(W, H) * 0.5 - vec2(cos(angle), sin(angle)) * r);
	}
	return p;
}

vec2 mapped(vec2 p, int kind, vec4 a, vec4 b, vec4 c) {
	int mode = int(c.x);
	vec2 half_size = vec2(W, H) * 0.5;
	if (mode == 0) {
		if (p.x > half_size.x) { p.x = W - p.x; }
		if (p.y > half_size.y) { p.y = H - p.y; }
	} else if (mode == 1) {
		bool first = W * p.y < H * p.x;
		bool second = W * p.y < (W - p.x) * H;
		if (first && second) {
			if (p.x >= half_size.x) { p.x = W - p.x; }
		} else if (first) {
			p.x = half_size.x - p.x + W;
			p.y = H - p.y;
			if (p.x > half_size.x) { p.x = W - p.x; }
		} else if (second) {
			p.x = half_size.x - p.x;
		} else {
			p.y = abs(p.y - half_size.y);
		}
	} else if (mode == 2) {
		vec2 d = p - half_size;
		float n = max(c.w, 2.0);
		float slice = 6.2831853 / n;
		float angle = mod(atan(d.y, d.x), slice);
		angle = abs(angle - slice * 0.5);
		p = half_size + vec2(cos(angle), sin(angle)) * length(d);
	} else if (mode == 3) {
		if (length(half_size - p) > c.y) {
			p = half_size - c.y + mod(p, c.z + 2.0) * (c.y * 2.0) / (c.z + 2.0);
		}
	} else if (mode == 4 && c.w > 0.0) {
		if (mod(floor(p.x / c.w), 2.0) > 0.5) { p.x = mod(p.x, c.w) * floor(W / c.w); }
		if (mod(floor(p.y / c.w), 2.0) > 0.5) { p.y = mod(p.y, c.w) * floor(H / c.w); }
	}
	return inner(p, kind, a, b);
}

void fragment() {
	vec2 p = floor(FRAGCOORD.xy);
	vec2 at = mapped(p, kind1, a1, b1, c1);
	if (kind2 >= 0) {
		at = floor((mapped(at, kind2, a2, b2, c2) + p) * 0.5);
	}
	if (at.x < 0.0 || at.y < 0.0 || at.x >= W || at.y >= H) {
		at = vec2(0.0);
	}
	COLOR = vec4(at, 0.0, 1.0);
}
