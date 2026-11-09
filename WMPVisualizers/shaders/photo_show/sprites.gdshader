shader_type canvas_item;
render_mode skip_vertex_transform, blend_add;

uniform sampler2D table : filter_nearest;
uniform sampler2D spark : filter_linear;
uniform float now = 0.0;
uniform int trail = 10;
uniform vec3 rest_color = vec3(0.0);
uniform vec3 orbit = vec3(0.0);
uniform vec3 place = vec3(0.0);
uniform float camera = 25.96;
uniform float size = 0.6;
uniform float scale = 0.07;
uniform vec2 resolution = vec2(640.0, 480.0);

varying vec3 tint;

void vertex() {
	int slot = INSTANCE_ID / trail;
	int link = INSTANCE_ID % trail;
	ivec2 base = ivec2((slot % 64) * 4, slot / 64);
	vec4 a = texelFetch(table, base, 0);
	vec4 b = texelFetch(table, base + ivec2(1, 0), 0);
	vec4 c = texelFetch(table, base + ivec2(2, 0), 0);
	vec4 d = texelFetch(table, base + ivec2(3, 0), 0);
	float age = now - a.w;
	float life = d.x - d.y * age;
	vec2 corner = VERTEX;
	UV = UV;
	tint = vec3(0.0);
	VERTEX = vec2(-1000.0);
	if (d.x > 0.0 && age >= 0.0 && life > 0.0) {
		vec3 speed = vec3(b.x, b.y + b.w * age, b.z);
		vec3 p = a.xyz + b.xyz * age;
		p.y += 0.5 * b.w * age * age;
		float reach = 0.0;
		float term = 1.0;
		for (int i = 0; i < link; i++) {
			reach += term;
			term *= d.w;
		}
		p -= speed * d.z * reach;
		float cr = cos(orbit.z), sr = sin(orbit.z);
		p = vec3(cr * p.x - sr * p.y, sr * p.x + cr * p.y, p.z);
		float cp = cos(orbit.y), sp = sin(orbit.y);
		p = vec3(p.x, cp * p.y - sp * p.z, sp * p.y + cp * p.z);
		float cy = cos(orbit.x), sy = sin(orbit.x);
		p = vec3(cy * p.x + sy * p.z, p.y, -sy * p.x + cy * p.z);
		p += place;
		float c1 = cos(1.6), s1 = sin(1.6);
		p = vec3(p.x, c1 * p.y - s1 * p.z, s1 * p.y + c1 * p.z);
		p.z -= camera;
		float depth = -p.z;
		if (depth > 0.1 && depth < 2000.0) {
			float focal = resolution.y * 0.5 * 1.73205;
			float span = resolution.y * size / (sqrt(scale) * length(p));
			VERTEX = resolution * 0.5 + vec2(p.x, -p.y) * focal / depth + corner * min(span, 256.0);
			tint = mix(rest_color, c.rgb, min(life, 1.0));
		}
	}
}

void fragment() {
	COLOR = vec4(texture(spark, UV).rgb * tint, 1.0);
}
