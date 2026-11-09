shader_type canvas_item;
render_mode blend_add, skip_vertex_transform;

uniform sampler2D spine : filter_nearest, repeat_disable;
uniform int head = 0;
uniform vec4 eye = vec4(0.0, 0.0, 10.0, 0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec2 focal = vec2(1.0, 1.0);
uniform vec2 resolution = vec2(640.0, 480.0);

varying vec3 tint;

const float NEAR = 0.1;

void vertex() {
	int row = int(round(UV.y * 50.0));
	int side = int(round(UV.x));
	vec3 point = texelFetch(spine, ivec2((head + row) % 51 * 2 + side, INSTANCE_ID), 0).xyz - eye.xyz;
	vec3 view = vec3(dot(point, right.xyz), dot(point, above.xyz), dot(point, back.xyz));
	float depth = max(-view.z, NEAR);
	vec2 ndc = view.xy * focal / depth;
	VERTEX = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5) * resolution;
	tint = side == 0 ? COLOR.rgb : INSTANCE_CUSTOM.rgb;
	float along = float(row) / 50.0 * 2.0 - 1.0;
	UV = vec2((along * along * along + 1.0) * 0.5, float(side));
}

void fragment() {
	COLOR = vec4(texture(TEXTURE, UV).rgb * tint, 1.0);
}
