shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D history : filter_linear;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform int style = 0;
uniform float dots = 0.0;

varying vec3 tint;
varying vec2 grid;

vec3 rose(float y) {
	if (y < 0.001) {
		return vec3(0.0);
	} else if (y < 0.501) {
		return vec3(0.0, y, 0.0);
	} else if (y < 0.751) {
		return vec3(1.0, y, 0.0);
	}
	return vec3(y, max(0.5 - y, 0.0), 0.0);
}

vec3 city(float y) {
	if (y <= 0.001) {
		return vec3(0.0);
	} else if (y <= 0.2) {
		return vec3(0.0, 0.0, 1.0);
	} else if (y <= 0.5) {
		return vec3(0.0, 1.0, 0.0);
	}
	return vec3(1.0, 0.0, 0.0);
}

void vertex() {
	vec3 world = vec3((UV.x - 0.5) * 512.0, 0.0, (UV.y - 0.5) * 512.0);
	float height = textureLod(history, vec2(UV.x, UV.y), 0.0).r;
	tint = style == 0 ? rose(height) : city(height);
	world.y = height * 100.0;
	vec3 eye = vec3(146.0, 250.0, 508.5);
	vec3 forward = normalize(-eye);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
	vec3 up = cross(forward, right);
	vec3 view = world - eye;
	float depth = dot(view, forward);
	float focal = 1.0 / tan(0.3927);
	vec2 clip = vec2(dot(view, right) * focal * resolution.y / resolution.x, dot(view, up) * focal) / depth;
	VERTEX = vec2((clip.x * 0.5 + 0.5) * resolution.x, (0.5 - clip.y * 0.5) * resolution.y);
	grid = UV * 512.0;
}

void fragment() {
	if (dots > 0.5) {
		vec2 cell = abs(fract(grid) - 0.5);
		if (max(cell.x, cell.y) > 0.3) {
			discard;
		}
	}
	COLOR = vec4(tint, 1.0);
}
