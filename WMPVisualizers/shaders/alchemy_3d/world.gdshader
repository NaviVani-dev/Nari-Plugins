shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D rt : filter_linear;
uniform float crop = 1.0;

vec4 stage_at(vec2 uv) {
	return texture(rt, 0.5 + (uv - 0.5) * crop);
}

uniform float time = 0.0;

varying flat mat3 root;
varying flat mat3 small;

mat3 about_y(float a) {
	return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
}

mat3 about_x(float a) {
	return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(a), sin(a)), vec3(0.0, -sin(a), cos(a)));
}

float stars(vec2 uv) {
	vec2 cell = floor(uv * vec2(320.0, 240.0));
	float n = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	return n > 0.986 ? 0.75 : 0.0;
}

float ball(vec3 from, vec3 ray, float radius) {
	float a = dot(ray, ray);
	float b = dot(from, ray);
	float h = b * b - a * (dot(from, from) - radius * radius);
	return h < 0.0 ? -1.0 : (-b - sqrt(h)) / a;
}

void vertex() {
	float t = mod(time * 10.0, 3600.0) * 0.0174533;
	root = about_x(t);
	small = about_y(-t * 2.0);
}

void fragment() {
	vec3 ray = vec3((UV.x - 0.5) * 2.0 * 0.41421 * 1.33333, (0.5 - UV.y) * 2.0 * 0.41421, 1.0);
	vec3 eye = vec3(0.0, -2.0, -10.0);
	vec3 color = vec3(stars(UV));
	vec3 light = normalize(vec3(2.0, 2.0, -1.0));
	ray = vec3(ray.x, ray.y * 0.9806 + 0.1961, ray.z * 0.9806 - ray.y * 0.1961);
	vec3 world_eye = eye * root;
	vec3 world_ray = ray * root;
	float big = ball(world_eye, world_ray, 2.5);
	vec3 moon_eye = (world_eye - vec3(0.0, 0.0, 4.0)) * small;
	vec3 moon_ray = world_ray * small;
	float little = ball(moon_eye, moon_ray, 0.5);
	float nearest = 1000.0;
	if (big > 0.0) {
		nearest = big;
		vec3 at = (world_eye + world_ray * big) / 2.5;
		vec3 normal = root * at;
		vec2 map = vec2(atan(at.z, at.x) / 6.2831853 + 0.5, acos(clamp(at.y, -1.0, 1.0)) / 3.1415927) * vec2(3.0);
		vec3 skin = stage_at(abs(fract(map * 0.5) * 2.0 - 1.0)).rgb;
		float diffuse = max(dot(normal, light), 0.0);
		color = skin * (0.35 + diffuse * 0.8) + vec3(1.0) * pow(max(dot(normal, normalize(light + vec3(0.0, 0.0, -1.0))), 0.0), 5.8) * 0.7;
	}
	if (little > 0.0 && little < nearest) {
		vec3 at = (moon_eye + moon_ray * little) / 0.5;
		vec3 normal = root * (small * at);
		float diffuse = max(dot(normal, light), 0.0);
		color = vec3(0.5, 0.2, 0.2) * (0.5 + diffuse) + vec3(0.8, 0.2, 0.2) * diffuse + vec3(0.6) * pow(max(dot(normal, normalize(light + vec3(0.0, 0.0, -1.0))), 0.0), 5.8);
	}
	COLOR = vec4(color, 1.0);
}
