shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled;

uniform sampler2D stripes : filter_linear, repeat_enable;
uniform sampler2D rings : filter_nearest, repeat_disable;
uniform vec4 eye = vec4(0.0, 0.0, 350.0, 0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec4 lamp = vec4(0.0, 100.0, 0.0, 0.0);

varying vec3 tint;

vec3 turn(vec3 p, vec3 angle) {
	float cz = cos(angle.z), sz = sin(angle.z), cx = cos(angle.x), sx = sin(angle.x), cy = cos(angle.y), sy = sin(angle.y);
	p = vec3(p.x * cz - p.y * sz, p.x * sz + p.y * cz, p.z);
	p = vec3(p.x, p.y * cx - p.z * sx, p.y * sx + p.z * cx);
	return vec3(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
}


void vertex() {
	int ring = int(COLOR.r * 255.0 + 0.5);
	vec4 pose = texelFetch(rings, ivec2(ring, 0), 0);
	vec3 place = turn(VERTEX, pose.xyz);
	vec3 facing = turn(NORMAL, pose.xyz);
	vec3 light = texelFetch(rings, ivec2(ring, 1), 0).rgb;
	tint = min(light * (1.0 + max(0.0, dot(facing, normalize(lamp.xyz - place)))), vec3(1.0));
	vec3 world = place - eye.xyz;
	VERTEX = pose.w > 0.5 ? vec3(0.0, 0.0, 1.0) : vec3(-dot(world, right.xyz), dot(world, above.xyz), dot(world, back.xyz));
}

void fragment() {
	ALBEDO = tint * texture(stripes, UV).rgb;
}
