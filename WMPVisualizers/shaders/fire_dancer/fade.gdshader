shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int frame = 0;

void fragment() {
	vec4 before = texture(screen, SCREEN_UV);
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(floor(before.rgb * 255.0 * 0.75) / 255.0, 1.0);
}
