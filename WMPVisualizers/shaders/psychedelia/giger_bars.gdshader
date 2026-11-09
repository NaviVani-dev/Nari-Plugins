shader_type spatial;
render_mode unshaded, blend_add, skip_vertex_transform, cull_back, depth_test_disabled, depth_draw_never;

uniform sampler2D heights : filter_nearest, repeat_disable;
uniform vec4 eye = vec4(0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform float spin = 0.0;
uniform float wobble = 0.0;
uniform float size = 1.0;
uniform float deep = 1.0;
uniform bool ring = true;
uniform int head = 0;
uniform int fade = 0;
uniform bool plain = false;
uniform bool same = false;
uniform float tall = 1.0;

varying vec3 tint;

void vertex() {
	int bar = INSTANCE_ID % 50;
	int row = INSTANCE_ID / 50;
	float level = texelFetch(heights, ivec2(bar, same ? head : row), 0).r;
	float age = float((row - head + 50) % 50);
	if (fade == 1) {
		level *= pow(0.99, age);
	} else if (fade == 2) {
		level -= age;
	}
	float across = plain || wobble > 0.0 && wobble < 0.5 ? deep : float(bar) * 2.0 * deep / 50.0;
	vec3 local = vec3(float(bar) * 6.0 + VERTEX.x * size, VERTEX.y * across * 2.0, VERTEX.z * 2.0 * level * tall);
	if (abs(level) < 0.5 && level >= 0.0) {
		local.x = 1000000.0;
	}
	float roll = spin;
	float pitch = 0.0;
	float yaw = 0.0;
	if (ring) {
		float around = float(row) * 6.28 / 50.0;
		if (wobble > 0.0) {
			float wide = around * 5.0;
			roll = (wide + spin) * wobble;
			pitch = wobble * 1.3 * wide + wobble * 0.1 * spin;
			yaw = wobble * 0.213 * spin + wobble * 0.154 * wide;
		} else {
			roll = around + spin;
		}
	}
	float cz = cos(roll), sz = sin(roll), cx = cos(pitch), sx = sin(pitch), cy = cos(yaw), sy = sin(yaw);
	vec3 a = vec3(local.x * cz - local.y * sz, local.x * sz + local.y * cz, local.z);
	vec3 b = vec3(a.x, a.y * cx - a.z * sx, a.y * sx + a.z * cx);
	vec3 world = vec3(b.x * cy + b.z * sy, b.y, -b.x * sy + b.z * cy) - eye.xyz;
	VERTEX = vec3(-dot(world, right.xyz), dot(world, above.xyz), dot(world, back.xyz));
	float high = level < 0.0 ? 1.0 : clamp(floor(level + 0.5) / 255.0, 0.0, 1.0);
	tint = plain ? vec3(high * 0.5, (1.0 - high) * 0.125, (1.0 - high) * 0.25) : vec3(high * 0.25, high * 0.0625, (1.0 - high) * 0.125);
}

void fragment() {
	ALBEDO = tint;
}
