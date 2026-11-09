shader_type canvas_item;
render_mode blend_disabled;

uniform int frame = 0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + float(frame % 113)) * 43758.5453);
}

void fragment() {
	if (COLOR.a < 0.999 && hash(FRAGCOORD.xy) >= COLOR.a) {
		discard;
	}
	COLOR = vec4(vec3(254.0 / 255.0), 1.0);
}
