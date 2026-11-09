shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D water : filter_nearest, repeat_enable;
uniform vec2 resolution = vec2(640.0, 480.0);

varying vec2 tex;
varying vec3 shine;

void vertex() {
	ivec2 base = ivec2(floor(UV * 63.0 + 0.5));
	float h = texelFetch(water, base, 0).r;
	float dx = texelFetch(water, (base + ivec2(63, 0)) % 64, 0).r - texelFetch(water, (base + ivec2(1, 0)) % 64, 0).r;
	float dz = texelFetch(water, (base + ivec2(0, 63)) % 64, 0).r - texelFetch(water, (base + ivec2(0, 1)) % 64, 0).r;
	vec3 normal = normalize(vec3(dx, 0.4, dz));
	vec2 grid = vec2(base) * 64.0 / 63.0 - 32.0;
	vec3 world = vec3(grid.x, 0.98951 * h - 0.14449 * grid.y - 17.4, 0.14449 * h + 0.98951 * grid.y - 60.0);
	vec3 turned = vec3(normal.x, 0.98951 * normal.y - 0.14449 * normal.z, 0.14449 * normal.y + 0.98951 * normal.z);
	VERTEX = vec2(world.x * 6.4952 / -world.z * 0.5 + 0.5, 0.5 - world.y * 1.7321 / -world.z * 0.5) * resolution;
	tex = (grid + 32.0) / 64.0 - normal.xz * 0.103;
	vec3 half_way = normalize(normalize(-world) + vec3(-0.3333, 0.6667, -0.6667));
	float caustic = 0.03 + length(normal.xz) * 0.06;
	shine = vec3(0.5) * pow(max(dot(turned, half_way), 0.0), 20.0) + vec3(caustic);
}

void fragment() {
	vec2 inset = min(tex, 1.0 - tex);
	float alpha = clamp(min(inset.x, inset.y) * 4.267, 0.0, 1.0) - 0.1;
	vec3 color = vec3(0.0, tex.y, mix(0.4078, 1.0, tex.y));
	COLOR = vec4(color + shine, max(alpha, 0.0));
}
