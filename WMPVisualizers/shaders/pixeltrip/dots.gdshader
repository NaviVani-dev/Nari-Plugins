shader_type canvas_item;
render_mode blend_premul_alpha, skip_vertex_transform;

uniform int shape = 0;
uniform int count_x = 2;
uniform int count_y = 2;
uniform int count_z = 2;
uniform vec4 size = vec4(100.0, 100.0, 100.0, 1.0);
uniform vec4 turn = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec2 center = vec2(320.0, 240.0);
uniform vec2 steps = vec2(0.2, 0.2);
uniform float radius = 100.0;
uniform float dot_radius = 1.0;
uniform float pixel = 1.0;
uniform int wire = 0;
uniform int flat_z = 0;
uniform int per_dot = 0;
uniform float hue_start = 0.0;
uniform int half_from = 1000000;
uniform vec4 tint = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 half_tint = vec4(1.0, 1.0, 1.0, 1.0);
uniform float solid = 1.0;

varying vec3 shade;
varying float span;

vec2 twist(vec2 q) {
	vec2 out_q = vec2(q.x * turn.x - q.y * turn.y, q.x * turn.y + q.y * turn.x);
	return turn.w > 0.5 ? out_q * vec2(cos(turn.z), sin(turn.z)) : out_q;
}

vec2 spot(int id) {
	vec3 q;
	if (shape == 1) {
		int row = id / count_x;
		int col = id - row * count_x;
		float phi = -1.5707963 + float(row) * steps.x;
		float theta = -3.1415927 + float(col) * steps.y;
		q = vec3(cos(theta) * cos(phi), sin(theta) * cos(phi), sin(phi)) * radius;
		if (flat_z == 1) {
			q.z *= 0.31831;
		}
	} else {
		int layer = id / (count_x * count_y);
		int rest = id - layer * count_x * count_y;
		int row = rest / count_x;
		int col = rest - row * count_x;
		q = vec3(floor(float(col) * size.x / float(count_x)) - floor(size.x * 0.5), floor(float(row) * size.y / float(count_y)) - floor(size.y * 0.5), floor(float(layer) * size.z / float(count_z)) - floor(size.z * 0.5));
	}
	if (shape == 2) {
		return center + twist(q.xy);
	}
	vec2 yz = twist(q.yz);
	vec2 xz = twist(vec2(q.x, yz.y));
	float z = xz.y;
	if (shape == 1 && flat_z == 0) {
		z *= 0.31831;
	}
	return center + vec2(xz.x, yz.x) + vec2(z, z);
}

vec3 hsv(float h) {
	return clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void vertex() {
	int id = INSTANCE_ID;
	bool half_copy = id >= half_from;
	if (half_copy) {
		id -= half_from;
	}
	vec2 a = spot(id);
	vec2 b = a;
	bool hidden = false;
	if (wire == 1 && shape == 1) {
		if (id % count_x == 0) {
			hidden = true;
		} else {
			b = spot(id - 1);
		}
	}
	if (half_copy) {
		a = (a + center) * 0.5;
		b = (b + center) * 0.5;
	}
	shade = half_copy ? half_tint.rgb : tint.rgb;
	if (per_dot == 1) {
		int total = count_x * count_y * (shape == 1 ? 1 : count_z);
		float n = float(max(total, 1));
		shade = hsv(mod(hue_start + float(INSTANCE_ID), n) / n);
	}
	vec2 mark = UV - 0.5;
	if (wire == 1 && shape == 1) {
		span = 0.0;
		vec2 along = b - a;
		vec2 side = normalize(vec2(-along.y, along.x) + vec2(0.0001, 0.0));
		VERTEX = ((a + b) * 0.5 + along * mark.x + side * mark.y) * pixel;
	} else {
		float wide = dot_radius * 2.0 + 1.0;
		span = wide;
		VERTEX = (floor(a) + 0.5 + mark * wide) * pixel;
	}
	if (hidden) {
		VERTEX = vec2(-100.0, -100.0);
	}
}

void fragment() {
	if (span > 0.0 && length((UV - 0.5) * span) > dot_radius + 0.26) {
		discard;
	}
	COLOR = vec4(shade, solid);
}
