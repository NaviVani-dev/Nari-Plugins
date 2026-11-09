shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled;

uniform sampler2D art : filter_linear, repeat_enable;
uniform vec4 row0 = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 row1 = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 row2 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec4 place = vec4(0.0, 0.0, 0.0, 0.0);

const vec3 EYE = vec3(0.0, 0.0, 5.0);
const vec3 LAMP = vec3(0.0, 6.0, 3.0);

varying vec3 world;
varying vec3 facing;

void vertex() {
	world = row0.xyz * VERTEX.x + row1.xyz * VERTEX.y + row2.xyz * VERTEX.z + place.xyz;
	facing = row0.xyz * NORMAL.x + row1.xyz * NORMAL.y + row2.xyz * NORMAL.z;
	VERTEX = world - EYE;
}

void fragment() {
	vec3 view = normalize(world - EYE);
	vec3 light = normalize(world - LAMP);
	vec3 tex = texture(art, UV).rgb;
	vec3 normal = normalize(normalize(facing) + (tex - 0.5) * 0.4);
	vec3 color = tex * (dot(normal, -light) * 0.5 + 0.5);
	vec3 reflection = view - 2.0 * normal * dot(normal, view);
	float shine = dot(reflection, -light);
	if (shine > 0.0) {
		color += vec3(pow(shine, 8.0));
	}
	ALBEDO = color;
}
