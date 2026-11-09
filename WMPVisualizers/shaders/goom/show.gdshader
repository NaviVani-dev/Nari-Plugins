shader_type canvas_item;

uniform sampler2D overlay : filter_linear;
uniform float flash = 1.0;

void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb + texture(overlay, UV).rgb;
	COLOR = vec4(min(color * flash, vec3(1.0)), 1.0);
}
