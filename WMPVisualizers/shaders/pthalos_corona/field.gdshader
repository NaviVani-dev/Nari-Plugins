shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec2 resolution = vec2(640.0, 384.0);
uniform vec4 map_old = vec4(0.5, 0.5, 0.0, 1.0);
uniform vec4 map_new = vec4(0.5, 0.5, 0.0, 1.0);
uniform float progress = 1.0;
uniform float time = 0.0;
uniform int frame = 0;

float hash(vec2 p, float s) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + s) * 43758.5453);
}

vec2 mirror(vec2 p) {
	p = abs(p);
	return min(p, 2.0 * resolution - p - 1.0);
}

float field(vec2 p) {
	vec2 uv = (p + 0.5) / resolution;
	return texture(screen, vec2(uv.x, 1.0 - uv.y)).r;
}

void fragment() {
	vec2 cell = floor(vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y) * resolution);
	float pick = hash(cell, 1.0);
	vec4 map = pick < progress ? map_new : map_old;
	vec2 delta = cell / resolution - map.xy;
	float square = dot(delta, delta);
	float angle = atan(delta.y, delta.x) + map.z / (square + 0.01);
	vec2 moved = (vec2(cos(angle), sin(angle)) * map.w * sqrt(square) - delta) * resolution;
	float bucket = floor(time * 0.3 + pick);
	vec2 jitter = floor(vec2(hash(cell, 2.0 + bucket), hash(cell, 3.0 + bucket)) * 5.0) - 2.0;
	vec2 target = floor(moved + 0.5) + jitter + cell;
	float near = field(cell + vec2(1.5, 0.5)) + field(cell - vec2(1.5, 0.5)) + field(cell + vec2(-0.5, 1.5)) + field(cell - vec2(-0.5, 1.5));
	float far = field(mirror(target + vec2(1.5, 0.5))) + field(mirror(target - vec2(1.5, 0.5))) + field(mirror(target + vec2(-0.5, 1.5))) + field(mirror(target - vec2(-0.5, 1.5)));
	float value = (near + far) * 0.125 - 1.9 / 255.0;
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(vec3(value), 1.0);
}
