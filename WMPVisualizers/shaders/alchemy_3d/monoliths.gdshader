shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D rt : filter_linear;
uniform float crop = 1.0;

vec4 stage_at(vec2 uv) {
	return texture(rt, 0.5 + (uv - 0.5) * crop);
}

uniform sampler2D logo : filter_linear;
uniform float time = 0.0;

varying flat mat3 root;
varying flat mat3 spin_a;
varying flat mat3 spin_b;
varying flat mat3 spin_c;

mat3 euler(float a) {
	float c = cos(a);
	float s = sin(a);
	mat3 x = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));
	mat3 y = mat3(vec3(c, 0.0, -s), vec3(0.0, 1.0, 0.0), vec3(s, 0.0, c));
	mat3 z = mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0));
	return y * z * x;
}

float stars(vec2 uv) {
	vec2 cell = floor(uv * vec2(320.0, 240.0));
	float n = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	return n > 0.986 ? 0.75 : 0.0;
}

vec4 box(vec3 from, vec3 ray, vec3 size) {
	vec3 inv = 1.0 / ray;
	vec3 near = (-size - from) * inv;
	vec3 far = (size - from) * inv;
	vec3 low = min(near, far);
	vec3 high = max(near, far);
	float enter = max(max(low.x, low.y), low.z);
	float leave = min(min(high.x, high.y), high.z);
	if (enter > leave || enter < 0.0) {
		return vec4(-1.0);
	}
	return vec4(step(vec3(enter), low) * sign(-ray), enter);
}

void vertex() {
	float t = mod(time * 10.0, 3600.0) * 0.0174533;
	root = euler(t);
	spin_a = euler(6.2831853 - t);
	spin_b = euler(3.1415927 - t);
	spin_c = euler(t);
}

void fragment() {
	vec3 ray = vec3((UV.x - 0.5) * 2.0 * 0.41421 * 1.33333, (0.5 - UV.y) * 2.0 * 0.41421, 1.0);
	vec3 eye = vec3(0.0, 0.0, -10.0);
	vec3 world_eye = eye * root;
	vec3 world_ray = ray * root;
	vec3 color = vec3(stars(UV));
	vec3 light = normalize(vec3(0.0, -1.0, 1.0));
	float nearest = 1000.0;
	for (int index = 0; index < 3; index++) {
		vec3 center = index == 0 ? vec3(0.0, 0.0, -2.0) : (index == 1 ? vec3(-2.0, -1.0, 2.0) : vec3(2.0, 1.0, 3.0));
		vec3 size = index == 0 ? vec3(1.5, 2.5, 0.075) : (index == 1 ? vec3(1.25, 1.25, 0.025) : vec3(0.75, 0.75, 0.025));
		mat3 spin = index == 0 ? spin_a : (index == 1 ? spin_b : spin_c);
		vec3 from = (world_eye - center) * spin;
		vec3 dir = world_ray * spin;
		vec4 hit = box(from, dir, size);
		if (hit.w > 0.0 && hit.w < nearest) {
			nearest = hit.w;
			vec3 at = (from + dir * hit.w) / size;
			vec2 face = abs(hit.x) > 0.5 ? at.zy : (abs(hit.y) > 0.5 ? at.xz : at.xy);
			vec2 map = vec2(face.x * 0.5 + 0.5, 0.5 - face.y * 0.5);
			vec3 normal = root * (spin * hit.xyz);
			float shade = 0.25 + max(dot(normal, -light), 0.0);
			if (index == 0) {
				color = stage_at(map).rgb * shade;
			} else if (index == 1) {
				color = vec3(shade) * (0.65 + 0.35 * map.y);
			} else {
				color = texture(logo, map).rgb * shade;
			}
		}
	}
	COLOR = vec4(color, 1.0);
}
