shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled;

uniform sampler2D sky : filter_linear, repeat_enable;
uniform vec4 turn = vec4(0.0);
uniform vec4 eye = vec4(0.0, 0.0, 350.0, 0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform float widen = 0.48;

void vertex() {
	vec3 p = VERTEX;
	float c = cos(turn.x), s = sin(turn.x);
	p = vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
	float cy = cos(turn.y), sy = sin(turn.y);
	p = vec3(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
	p = vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
	vec3 world = p + vec3(0.0, -90.0, 0.0) - eye.xyz;
	VERTEX = vec3(-dot(world, right.xyz) * widen, dot(world, above.xyz) * widen, dot(world, back.xyz));
}

void fragment() {
	ALBEDO = texture(sky, UV).rgb * 0.5 + vec3(0.5);
}
