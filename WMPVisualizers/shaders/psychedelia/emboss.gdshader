shader_type canvas_item;

uniform vec2 resolution = vec2(640.0, 480.0);

void fragment() {
	vec2 reach = 0.5 / resolution;
	vec3 color = texture(TEXTURE, UV + reach).rgb - texture(TEXTURE, UV - reach).rgb + 0.5;
	COLOR = vec4(color, 1.0);
}
