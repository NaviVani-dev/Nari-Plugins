shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D scene_image : filter_linear, repeat_disable;
uniform sampler2D glow : filter_linear, repeat_disable;
uniform float scene_weight = 1.0;
uniform float glow_weight = 1.0;

void fragment() {
	COLOR = vec4(texture(scene_image, UV).rgb * scene_weight + texture(glow, UV).rgb * glow_weight, 1.0);
}
