shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled;

uniform sampler2D note : filter_linear, repeat_enable;
uniform sampler2D waves : filter_nearest, repeat_disable;
uniform bool move = true;
uniform bool warp = true;
uniform vec4 eye = vec4(0.0, 0.0, 350.0, 0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);

varying float shade;
varying vec2 lookup;

vec3 place(vec3 p) {
	float c = cos(1.57), s = sin(1.57);
	p = vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
	p = vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
	c = cos(3.14);
	s = sin(3.14);
	p = vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
	return p + vec3(-100.0, 0.0, 0.0);
}

void vertex() {
	vec2 plane = vec2(161.0 - UV.x * 322.0, 159.0 - UV.y * 318.0);
	float height = 0.0;
	vec2 slope = vec2(0.0);
	float damp = dot(plane, plane) / 10000.0 + 1.0;
	for (int index = 0; index < 15; index++) {
		vec4 wave = texelFetch(waves, ivec2(index, 0), 0);
		float rise = wave.w * (0.9 + float(index / 10));
		float phase = dot(plane, wave.xy) * wave.z + wave.z + rise;
		height += rise * sin(phase) / damp;
		slope += -cos(phase) * rise * wave.z * wave.xy / damp;
	}
	if (!move) {
		height = 0.0;
	}
	shade = 0.99 - height / 40.0;
	lookup = warp ? UV + slope / 25.0 : UV;
	vec3 world = place(vec3(plane.x, height, plane.y)) - eye.xyz;
	VERTEX = vec3(-dot(world, right.xyz), dot(world, above.xyz), dot(world, back.xyz));
}

void fragment() {
	ALBEDO = texture(note, lookup).rgb * clamp(shade, 0.0, 1.0);
}
