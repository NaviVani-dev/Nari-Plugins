shader_type canvas_item;

uniform sampler2D colors : filter_nearest;
uniform sampler2D previous : filter_nearest;
uniform float blend = 1.0;

void fragment() {
	float index = floor(texture(TEXTURE, UV).r * 255.0 + 0.5);
	vec2 at = vec2((index + 0.5) / 256.0, 0.5);
	COLOR = vec4(mix(texture(previous, at).rgb, texture(colors, at).rgb, blend), 1.0);
}
