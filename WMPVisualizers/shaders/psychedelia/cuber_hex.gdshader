shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled;

uniform sampler2D cells : filter_nearest, repeat_disable;
uniform sampler2D past : filter_linear, repeat_enable, hint_default_black;
uniform vec4 eye = vec4(0.0);
uniform vec4 right = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 above = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 back = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec4 lamp = vec4(0.0, 100.0, 0.0, 0.0);

varying vec3 tint;

void vertex() {
	vec4 cell = texelFetch(cells, ivec2(INSTANCE_ID, 0), 0);
	vec3 place = vec3(VERTEX.x + cell.x, max(VERTEX.y + cell.y, 0.0), VERTEX.z + cell.z);
	vec3 hue = INSTANCE_ID < 7 ? vec3(0.0, 0.0, 1.0) : (INSTANCE_ID < 19 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0));
	vec3 to_lamp = lamp.xyz - place;
	float reach = length(to_lamp);
	float lit = reach > 300.0 ? 0.0 : max(0.0, dot(NORMAL, to_lamp / reach));
	tint = min((hue * cell.w * 2.0 + 0.01) * lit + hue * cell.w * 0.00002, vec3(1.0));
	vec3 world = place - eye.xyz;
	VERTEX = vec3(-dot(world, right.xyz), dot(world, above.xyz), dot(world, back.xyz));
}

void fragment() {
	vec3 image = texture(past, UV).rgb * 0.5;
	ALBEDO = tint + image - tint * image;
}
