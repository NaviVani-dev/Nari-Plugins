shader_type canvas_item;
render_mode blend_add, skip_vertex_transform;

uniform sampler2D data : filter_nearest, repeat_disable;
uniform float time = 0.0;
uniform vec4 eye = vec4(0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec2 resolution = vec2(640.0, 480.0);

varying vec3 tint;

const float SIZE = 0.03;
const float SCALE = 0.8;
const vec2 FOCAL = vec2(1.8106601, 2.4142135);

vec2 screen_of(vec3 world) {
	vec3 point = (world - eye.xyz) * SCALE;
	vec3 view = vec3(dot(point, right.xyz), dot(point, above.xyz), dot(point, back.xyz));
	float depth = max(-view.z, 0.1);
	vec2 ndc = view.xy * FOCAL / depth;
	return vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5) * resolution;
}

void vertex() {
	int mode = INSTANCE_ID % 3;
	int row = INSTANCE_ID / 3;
	vec4 place = texelFetch(data, ivec2(0, row), 0);
	vec4 speed = texelFetch(data, ivec2(1, row), 0);
	vec4 first = texelFetch(data, ivec2(2, row), 0);
	vec4 last = texelFetch(data, ivec2(3, row), 0);
	float age = time - place.w;
	vec3 at = place.xyz + speed.xyz * age;
	float life = speed.w - age * first.w;
	tint = clamp((first.rgb - last.rgb) * life + last.rgb, 0.0, 1.0);
	vec2 corner = UV * 2.0 - 1.0;
	vec2 result;
	if (last.w < 0.5) {
		result = vec2(-100000.0);
	} else if (mode == 0) {
		float reach = max(at.y, 0.0) * 0.25 + SIZE;
		result = screen_of(vec3(at.x + corner.x * reach, 0.0, at.z + corner.y * reach));
	} else {
		vec3 center = mode == 1 ? at : vec3(at.x, -at.y, at.z);
		vec3 point = (center - eye.xyz) * SCALE;
		vec3 view = vec3(dot(point, right.xyz), dot(point, above.xyz), dot(point, back.xyz));
		view.xy += vec2(corner.x, -corner.y) * SIZE;
		float depth = max(-view.z, 0.1);
		vec2 ndc = view.xy * FOCAL / depth;
		result = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5) * resolution;
	}
	VERTEX = result;
}

void fragment() {
	COLOR = vec4(texture(TEXTURE, UV).rgb * tint, 1.0);
}
