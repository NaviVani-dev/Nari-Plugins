shader_type canvas_item;

uniform vec2 box = vec2(80.0);
uniform float near = 9.0;
uniform float near_amount = 100.0;
uniform float far = 30.0;
uniform float far_amount = 100.0;
uniform bool subtract = false;

void fragment() {
	vec2 edge = min(UV, 1.0 - UV) * box;
	float run = floor(min(edge.x, edge.y)) + 1.0;
	float alpha = 0.0;
	if (run <= near) {
		alpha = near_amount * (1.0 - run / near);
	} else if (run <= far) {
		alpha = far_amount * (1.0 - run / far);
	}
	alpha = min(alpha / 255.0, 1.0);
	if (subtract) {
		COLOR = vec4(max(COLOR.rgb - alpha, vec3(0.0)), 1.0);
	} else {
		COLOR.a = 1.0 - alpha;
	}
}
