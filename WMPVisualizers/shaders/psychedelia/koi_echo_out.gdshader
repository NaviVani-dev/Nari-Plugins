shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D glow : filter_linear, repeat_disable;

void fragment() {
	COLOR = vec4(texture(glow, UV * 0.65).rgb, 1.0);
}
