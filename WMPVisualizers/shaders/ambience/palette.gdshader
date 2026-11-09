shader_type canvas_item;

uniform vec4 from_0 : source_color;
uniform vec4 from_1 : source_color;
uniform vec4 from_2 : source_color;
uniform vec4 from_3 : source_color;
uniform vec4 to_0 : source_color;
uniform vec4 to_1 : source_color;
uniform vec4 to_2 : source_color;
uniform vec4 to_3 : source_color;
uniform float blend = 1.0;

vec3 lookup(vec3 key_0, vec3 key_1, vec3 key_2, vec3 key_3, float index) {
	if (index < 0.5) {
		return vec3(0.0);
	}
	if (index > 254.5) {
		return vec3(1.0);
	}
	if (index < 127.5) {
		return mix(key_0, key_1, (index - 1.0) / 127.0);
	}
	return mix(key_2, key_3, (index - 128.0) / 127.0);
}

void fragment() {
	float index = floor(texture(TEXTURE, UV).r * 255.0 + 0.5);
	COLOR = vec4(mix(lookup(from_0.rgb, from_1.rgb, from_2.rgb, from_3.rgb, index), lookup(to_0.rgb, to_1.rgb, to_2.rgb, to_3.rgb, index), blend), 1.0);
}
