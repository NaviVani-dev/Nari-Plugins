shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D scene_image : filter_linear, repeat_disable;
uniform sampler2D past : filter_linear, repeat_disable;
uniform float scene_weight = 0.0;
uniform float past_weight = 1.0;
uniform vec2 reach = vec2(0.0);
uniform vec2 c0 = vec2(0.0, 0.0);
uniform vec2 c1 = vec2(1.0, 0.0);
uniform vec2 c2 = vec2(1.0, 1.0);
uniform vec2 c3 = vec2(0.0, 1.0);

vec3 tap(vec2 at) {
	return min(texture(scene_image, at).rgb * scene_weight + texture(past, at).rgb * past_weight, vec3(1.0));
}

void fragment() {
	vec2 at = mix(mix(c0, c1, UV.x), mix(c3, c2, UV.x), UV.y);
	vec3 color = tap(at - reach * 5.42) * 0.10584 + tap(at - reach * 1.48) * 0.38416 + tap(at + reach * 1.48) * 0.38416 + tap(at + reach * 5.42) * 0.10584;
	COLOR = vec4(color, 1.0);
}
