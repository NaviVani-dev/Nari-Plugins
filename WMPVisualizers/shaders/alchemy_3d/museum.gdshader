shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D rt : filter_linear;
uniform float crop = 1.0;

vec4 stage_at(vec2 uv) {
	return texture(rt, 0.5 + (uv - 0.5) * crop);
}

uniform sampler2D paint1 : filter_linear;
uniform sampler2D paint2 : filter_linear;
uniform sampler2D paint3 : filter_linear;
uniform sampler2D paint4 : filter_linear;
uniform sampler2D paint5 : filter_linear;
uniform float time = 0.0;

varying flat mat3 root;

mat3 about_y(float a) {
	return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
}

float ball(vec3 from, vec3 ray, float radius) {
	float a = dot(ray, ray);
	float b = dot(from, ray);
	float h = b * b - a * (dot(from, from) - radius * radius);
	return h < 0.0 ? -1.0 : (-b - sqrt(h)) / a;
}

void vertex() {
	float t = mod(time * 10.0, 3600.0) * 0.0174533;
	root = about_y(t);
}

float panel(vec3 from, vec3 ray, float plane, int axis, float facing) {
	float d = axis == 0 ? ray.x : ray.z;
	if (d * facing >= 0.0) {
		return -1.0;
	}
	return (plane - (axis == 0 ? from.x : from.z)) / d;
}

void fragment() {
	vec3 ray = vec3((UV.x - 0.5) * 2.0 * 0.41421 * 1.33333, (0.5 - UV.y) * 2.0 * 0.41421, 1.0);
	vec3 from = vec3(0.0, 0.0, -10.0) * root;
	vec3 dir = ray * root;
	vec3 half_room = vec3(7.0, 3.5, 7.0);
	vec3 exits = (sign(dir) * half_room - from) / dir;
	float nearest = min(min(exits.x, exits.y), exits.z);
	vec3 at = from + dir * nearest;
	vec3 color;
	vec3 side = at / half_room;
	vec2 face = abs(side.y) > 0.999 ? side.xz : (abs(side.x) > 0.999 ? side.zy : side.xy);
	color = stage_at(vec2(face.x * 0.5 + 0.5, 0.5 - face.y * 0.5)).rgb * 0.5;
	if (dir.y < 0.0) {
		float floor_hit = (-3.4 - from.y) / dir.y;
		vec3 ground = from + dir * floor_hit;
		if (floor_hit > 0.0 && floor_hit < nearest && abs(ground.x) < 8.0 && abs(ground.z) < 8.0) {
			nearest = floor_hit;
			vec2 tile = floor(ground.xz + 0.5);
			color = vec3(mod(tile.x + tile.y, 2.0));
		}
	}
	for (int index = 0; index < 6; index++) {
		int axis = index < 2 || index == 4 ? 0 : 1;
		float plane = index < 2 ? 6.5 : (index == 4 ? -6.5 : (index == 5 ? 6.5 : -6.3));
		float center = index == 0 ? 3.0 : (index == 1 ? -3.0 : (index == 2 ? 3.0 : (index == 3 ? -3.0 : 0.0)));
		float hit = panel(from, dir, plane, axis, -sign(plane));
		if (hit > 0.0 && hit < nearest) {
			vec3 spot = from + dir * hit;
			float along = (axis == 0 ? spot.z : spot.x) - center;
			if (abs(along) < 2.0 && abs(spot.y) < 2.0) {
				vec2 map = vec2(along * -sign(plane) * (axis == 0 ? 1.0 : -1.0) * 0.25 + 0.5, 0.5 - spot.y * 0.25);
				if (index == 5) {
					color = vec3(0.1);
				} else {
					color = index == 0 ? texture(paint2, map).rgb : (index == 1 ? texture(paint1, map).rgb : (index == 2 ? texture(paint4, map).rgb : (index == 3 ? texture(paint5, map).rgb : texture(paint3, map).rgb)));
				}
				nearest = hit;
			}
		}
	}
	vec3 sphere_from = from - vec3(0.0, 4.2, 0.0);
	float hit = ball(sphere_from, dir, 1.2);
	if (hit > 0.0 && hit < nearest) {
		vec3 normal = (sphere_from + dir * hit) / 1.2;
		vec3 skin = stage_at(normal.xz * 0.5 + 0.5).rgb;
		color = skin * (0.5 + 0.5 * max(-normal.y, 0.0)) + vec3(1.0) * pow(max(dot(normal, normalize(vec3(0.0, -0.5, -1.0))), 0.0), 5.0) * 0.5;
	}
	COLOR = vec4(color, 1.0);
}
