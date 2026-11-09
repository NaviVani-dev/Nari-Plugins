shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int frame = 0;

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	vec3 fall = step(vec3(0.63), color) * 0.188 + step(color, vec3(0.63)) * 0.125;
	color = max(color - fall, vec3(0.0));
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color, 1.0);
}
