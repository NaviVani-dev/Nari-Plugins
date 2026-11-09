shader_type canvas_item;
render_mode blend_add, skip_vertex_transform;

uniform sampler2D glow : filter_linear;
uniform sampler2D flake : filter_linear;
uniform float time = 0.0;
uniform vec2 resolution = vec2(640.0, 480.0);

varying float fade;
varying float big;

float hash(float seed) {
	return fract(sin(seed * 12.9898 + 4.1414) * 43758.5453);
}

void vertex() {
	float id = float(INSTANCE_ID);
	float age = time - id / 240.0;
	float angle = hash(id + 0.5) * 0.7853982;
	float fall = hash(id + 0.25) * 3.0 * cos(angle);
	float top = 67.2 + 16.0;
	float landing = (-fall + sqrt(fall * fall + 0.18 * top)) / 0.09;
	float span = min(30.0, landing);
	float cycle = floor(age / span);
	float local = age - cycle * span;
	float seed = id + cycle * 2048.0;
	float depth = floor(hash(seed + 0.125) * 32.0) - 16.0;
	float spin = hash(seed + 0.375) * 6.2831853;
	float x = floor(hash(seed + 0.625) * 64.0) - 32.0 + cos(spin) * 0.2 * sin(angle) * local;
	float y = 63.2 - depth - fall * local - 0.045 * local * local;
	float dead = step(age, 0.0) + step(y, -4.0);
	float view = 0.9379 * y + 0.3469 * depth - 21.2;
	float distance_to = 38.66 + 0.3469 * y - 0.9379 * depth;
	big = step(14.5, depth);
	float size = resolution.y * 0.7559 / distance_to * (1.0 + big);
	fade = clamp(18.0 - local * 0.6, 0.0, 1.0);
	vec2 center = vec2(1.732 * x / distance_to + 1.0, 1.0 - 1.732 * view / distance_to) * 0.5 * resolution;
	VERTEX = dead > 0.0 ? vec2(-100.0) : center + VERTEX * size;
}

void fragment() {
	float shape = big > 0.5 ? texture(flake, UV).a : texture(glow, UV).a;
	COLOR = vec4(vec3(shape * fade), 1.0);
}
