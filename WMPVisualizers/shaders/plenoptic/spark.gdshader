shader_type canvas_item;
render_mode blend_add, skip_vertex_transform;

uniform sampler2D data : filter_nearest, repeat_disable;
uniform vec2 resolution = vec2(256.0, 192.0);
uniform float eye_y = -0.9;
uniform float yaw = 0.0;
uniform float flat_mirror = 0.0;

varying vec3 tint;

const float TAN_X = 2.5721516;
const float TAN_Y = 1.7433153;

vec2 project(vec3 point) {
	float c = cos(yaw);
	float s = sin(yaw);
	vec3 p = vec3(point.x * c + point.z * s, point.y, point.z * c - point.x * s);
	float depth = p.z - 1.0;
	if (depth > -0.02) {
		return vec2(-100000.0);
	}
	vec2 scaled = vec2(p.x * TAN_X, (p.y - eye_y) * TAN_Y) / depth;
	return vec2(0.5 + 0.5 * scaled.x, 0.5 - 0.5 * scaled.y) * resolution;
}

vec3 flame_color(float index) {
	vec3 yellow = vec3(1.0, 1.0, 0.0);
	vec3 red = vec3(1.0, 0.0, 0.0);
	if (index < 64.0) {
		return yellow * index / 64.0;
	}
	return mix(yellow, red, min((index - 64.0) / 64.0, 1.0));
}

void vertex() {
	int mirror = INSTANCE_ID % 2;
	vec4 point = texelFetch(data, ivec2(INSTANCE_ID / 2, 0), 0);
	vec3 place = point.xyz;
	float index = floor(point.w * 127.0);
	if (point.w < 0.0) {
		VERTEX = vec2(-100000.0);
		tint = vec3(0.0);
	} else {
		if (mirror == 1) {
			place.y = flat_mirror > 0.5 ? -0.94 - place.y : -place.y;
			tint = vec3(0.0, 0.0, min(index / 128.0, 1.0));
		} else {
			tint = flame_color(index);
		}
		vec2 corner = project(place);
		VERTEX = corner + UV * floor(resolution.x / 32.0);
	}
}

void fragment() {
	vec2 away = UV * 2.0 - 1.0;
	COLOR = vec4(tint * max(1.0 - length(away), 0.0), 1.0);
}
