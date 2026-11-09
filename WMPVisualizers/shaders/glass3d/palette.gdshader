shader_type canvas_item;

uniform float history[99];
uniform int cursor = 0;
uniform int acid = 0;

vec3 older(int age) {
	int at = (cursor - age + 33 * 3) % 33;
	return vec3(history[at * 3], history[at * 3 + 1], history[at * 3 + 2]);
}

void fragment() {
	float index = floor(texture(TEXTURE, UV).r * 255.0 + 0.5);
	float behind = 255.0 - index;
	int age = int(behind / 8.0);
	vec3 base = mix(older(age), older(age + 1), fract(behind / 8.0));
	vec3 color = max(base - behind, vec3(0.0));
	COLOR = vec4(min(color, vec3(index)) / 255.0, 1.0);
}
