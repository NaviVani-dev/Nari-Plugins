shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D cover : filter_linear, repeat_disable;
uniform int columns = 1;
uniform int rows = 1;
uniform vec2 origin = vec2(0.0);
uniform int stride = 1;
uniform vec2 center_shift = vec2(0.0);
uniform vec2 wave_rate = vec2(0.0);
uniform vec2 wave_phase = vec2(0.0);
uniform float wave_lift = 0.0;
uniform float bend = 0.0;
uniform int wave_shape = 0;
uniform vec3 turn = vec3(0.0);
uniform float twist = 0.0;
uniform vec3 pull = vec3(0.0);
uniform float slide = 0.0;
uniform float fade = 0.0;
uniform float edge_amount = 0.0;
uniform float edge_reach = 0.0;
uniform int edge_sides = 0;
uniform float glow_low = 0.0;
uniform float glow_high = 0.0;
uniform bool lit = false;
uniform float spot = 0.0;
uniform float spot_soft = 0.0;
uniform float wedge = 0.0;
uniform float light_base = 0.0;
uniform float light_phase = 0.0;
uniform float ring = 0.0;
uniform float square = 0.0;
uniform float scatter = 0.0;

varying vec4 tint;

float cosd(float degrees_in) {
	return cos(radians(degrees_in));
}

float spiral(float dx, float dy) {
	float n = max(abs(dx), abs(dy));
	float last = (2.0 * n + 1.0) * (2.0 * n + 1.0) - 1.0;
	if (dy == n) {
		return last - (n - dx);
	}
	if (dx == -n) {
		return last - 2.0 * n - (n - dy);
	}
	if (dy == -n) {
		return last - 4.0 * n - (dx + n);
	}
	return last - 6.0 * n - (dy + n);
}

void vertex() {
	float w = float(columns);
	float h = float(rows);
	int across = columns / stride;
	float x = float((INSTANCE_ID % across) * stride);
	float top = float((INSTANCE_ID / across) * stride);
	vec2 corner = VERTEX;
	float y = h - 1.0 - top;
	vec3 color = textureLod(cover, (vec2(x, top) + 0.5) / vec2(w, h), 0.0).rgb;
	vec2 middle = floor(vec2(w, h) * 0.5) + center_shift;
	vec2 at = vec2(x, y) - middle;
	if (wave_rate != vec2(0.0) || wave_lift != 0.0 || bend != 0.0) {
		vec2 s = at;
		float lift_a = s.y * s.y * bend * 0.001 + wave_lift;
		float lift_b = lift_a;
		int shape = wave_shape;
		if (shape > 12) {
			shape -= 13;
			lift_a = s.x * s.y * bend * 0.001 + wave_lift;
		}
		vec2 p = s;
		if (shape == 1 || shape == 3) p.x = s.x * 0.5;
		if (shape == 2 || shape == 3) p.y = s.y * 0.5;
		if (shape == 4 || shape == 6) p.x = s.x * s.x;
		if (shape == 5 || shape == 6) p.y = s.y * s.y;
		if (shape == 7 || shape == 9) p.x = s.x * s.y;
		if (shape == 8 || shape == 9) p.y = s.x * s.y;
		if ((shape == 10 || shape == 12) && s.x != 0.0) p.y = s.y * s.y / s.x;
		if ((shape == 11 || shape == 12) && s.y != 0.0) p.x = s.x * s.x / s.y;
		if (wave_rate.x != 0.0) {
			at.x += cosd(floor(abs(p.y) * wave_rate.x + wave_phase.x)) * lift_a;
		}
		if (wave_rate.y != 0.0) {
			at.y += cosd(floor(abs(p.x) * wave_rate.y + wave_phase.y)) * lift_b;
		}
	}
	if (pull.x != 0.0) {
		float reach = floor(dot(at, at));
		float k = pull.y - reach * pull.z * 0.0001;
		float f = fract(abs(k));
		if (k < 0.0) {
			f = 1.0 - f;
		}
		at -= trunc(at * f);
	}
	if (turn != vec3(0.0) || twist != 0.0) {
		float reach = floor(dot(at, at));
		float swing = trunc(reach * twist * 0.1);
		if (turn.z != 0.0) {
			float a = radians(mod(floor(turn.z - swing), 360.0));
			at = vec2(cos(a) * at.x - sin(a) * at.y, sin(a) * at.x + cos(a) * at.y);
		}
		if (turn.x != 0.0) {
			at.y *= cosd(mod(floor(turn.x - swing), 360.0));
		}
		if (turn.y != 0.0) {
			at.x *= cosd(mod(floor(turn.y - swing), 360.0));
		}
	}
	vec2 spot_at = trunc(at) + middle;
	bool shown = spot_at.x >= 0.0 && spot_at.y >= 0.0 && spot_at.x < w && spot_at.y < h;
	spot_at.y += trunc(slide);
	float alpha = fade;
	if (edge_amount != 0.0 && edge_reach > 0.0) {
		float reach = 1000000.0;
		int sides = edge_sides == 0 ? 15 : edge_sides;
		if ((sides & 8) != 0) reach = min(reach, x + 1.0);
		if ((sides & 4) != 0) reach = min(reach, w - x);
		if ((sides & 2) != 0) reach = min(reach, y + 1.0);
		if ((sides & 1) != 0) reach = min(reach, h - y);
		if (reach <= edge_reach) {
			alpha += edge_amount - reach * edge_amount / edge_reach;
		}
	}
	if (glow_high != 0.0 || glow_low != 0.0) {
		float level = (color.r + color.g + color.b) * 85.0;
		alpha += max(level + glow_low - 255.0, 0.0) * glow_high / 255.0;
	}
	if (lit) {
		vec2 from = vec2(x, y) - floor(vec2(w, h) * 0.5);
		float reach = dot(from, from);
		bool dark = false;
		if (wedge != 0.0 && from.x != 0.0 && from.y != 0.0) {
			float big = max(abs(from.x), abs(from.y));
			float small = min(abs(from.x), abs(from.y));
			float q = small / big;
			if (q > wedge && 1.0 - q > wedge) {
				dark = true;
			}
		}
		if (spot > 0.0 && reach > spot * spot * 2.0) {
			dark = true;
		}
		float bright = 1.0;
		if (spot_soft != 0.0 && spot > 0.0) {
			bright += reach * spot_soft / (spot * spot * 2.0);
		}
		float angle = light_phase + trunc(mod(reach * ring + spiral(from.x, from.y) * square + float(INSTANCE_ID) * scatter * 0.001 * reach, 360.0));
		bright *= light_base + cosd(mod(abs(angle), 360.0));
		if (dark || bright <= 0.0) {
			alpha = 255.0;
		} else {
			alpha += 255.0 - min(bright * 255.0, 255.0);
		}
	}
	alpha = clamp(alpha, 0.0, 255.0);
	tint = vec4(color, 1.0 - alpha / 255.0);
	if (!shown || alpha >= 255.0) {
		VERTEX = vec2(-100.0);
	} else {
		VERTEX = origin + vec2(spot_at.x, h - 1.0 - spot_at.y) + 0.5 + corner;
	}
}

void fragment() {
	COLOR = tint;
}
