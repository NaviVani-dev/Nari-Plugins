shader_type canvas_item;
render_mode blend_premul_alpha;

uniform vec4 fill = vec4(1.0);
uniform vec4 edge = vec4(1.0);
uniform float strength = 0.4;
uniform float radius = 10.0;

void fragment() {
	vec2 d = (UV * 2.0 - 1.0) * (radius + 3.2);
	float depth = (radius * radius - dot(d, d)) / radius;
	float body = 0.0;
	if (depth >= 1.0) {
		float t = depth / radius;
		body = cos(t * t * 1.5707963) * strength;
	}
	float ring = abs(depth) < 3.14 ? (cos(abs(depth)) + 1.0) * 0.5 : 0.0;
	COLOR = vec4(fill.rgb * body * (1.0 - ring) + edge.rgb * ring, 1.0 - (1.0 - body) * (1.0 - ring));
}
