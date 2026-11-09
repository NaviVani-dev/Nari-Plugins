shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec4 fall = vec4(0.0);
uniform int frame = 0;

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb - fall.rgb;
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(max(color, vec3(0.0)), 1.0);
}
