shader_type canvas_item;
render_mode blend_disabled;

uniform vec4 background : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	COLOR = background;
}
