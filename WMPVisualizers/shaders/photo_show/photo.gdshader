shader_type canvas_item;

uniform sampler2D photo : filter_linear;
uniform sampler2D water : filter_linear, repeat_enable;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec2 half_size = vec2(255.0, 166.0);
uniform float edge = 0.02;
uniform vec3 angles = vec3(0.0);
uniform vec3 shift = vec3(0.0);
uniform float camera = 1.0;
uniform float fade = 0.0;
uniform float swell = 0.0;

varying vec2 surface;

void vertex() {
	float focal = resolution.y * 0.5 * 1.73205;
	vec2 rippled = UV;
	float height = 0.0;
	if (swell != 0.0) {
		float step_size = 1.0 / 64.0;
		height = textureLod(water, UV, 0.0).r;
		float dx = textureLod(water, UV + vec2(step_size, 0.0), 0.0).r - textureLod(water, UV - vec2(step_size, 0.0), 0.0).r;
		float dy = textureLod(water, UV + vec2(0.0, step_size), 0.0).r - textureLod(water, UV - vec2(0.0, step_size), 0.0).r;
		rippled = UV + vec2(dx, dy) * 0.02;
		height *= swell;
	}
	surface = rippled;
	vec3 p = vec3((UV.x - 0.5) * 2.0 * half_size.x, height, (UV.y - 0.5) * 2.0 * half_size.y);
	float cr = cos(angles.z), sr = sin(angles.z);
	p = vec3(cr * p.x - sr * p.y, sr * p.x + cr * p.y, p.z);
	float cp = cos(angles.y), sp = sin(angles.y);
	p = vec3(p.x, cp * p.y - sp * p.z, sp * p.y + cp * p.z);
	float cy = cos(angles.x), sy = sin(angles.x);
	p = vec3(cy * p.x + sy * p.z, p.y, -sy * p.x + cy * p.z);
	p += shift;
	float c1 = cos(1.6), s1 = sin(1.6);
	p = vec3(p.x, c1 * p.y - s1 * p.z, s1 * p.y + c1 * p.z);
	float depth = max((camera * focal - p.z) / focal, 0.02);
	VERTEX = resolution * 0.5 + vec2(p.x, -p.y) / depth;
}

void fragment() {
	float alpha = 1.0 - fade;
	vec2 inner = (surface - edge) / (1.0 - edge * 2.0);
	if (inner.x < 0.0 || inner.y < 0.0 || inner.x > 1.0 || inner.y > 1.0) {
		alpha *= 0.5;
	}
	COLOR = vec4(texture(photo, clamp(inner, vec2(0.0), vec2(1.0))).rgb, alpha);
}
