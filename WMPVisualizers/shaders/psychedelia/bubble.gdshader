shader_type canvas_item;

uniform sampler2D specular : filter_linear, repeat_disable;
uniform sampler2D diffuse : filter_linear, repeat_disable;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 shine = texture(specular, UV);
	vec3 base = texture(TEXTURE, UV).rgb;
	if (tint.a < 0.5) {
		base *= texture(diffuse, UV).rgb;
	} else {
		base *= tint.rgb;
	}
	COLOR = vec4(base + shine.rgb, shine.a);
}
