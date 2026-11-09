shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D scene_image : filter_linear, repeat_disable;
uniform vec2 reach = vec2(0.0);
uniform vec2 c0 = vec2(0.0, 0.0);
uniform vec2 c1 = vec2(1.0, 0.0);
uniform vec2 c2 = vec2(1.0, 1.0);
uniform vec2 c3 = vec2(0.0, 1.0);

void fragment() {
	vec2 at = mix(mix(c0, c1, UV.x), mix(c3, c2, UV.x), UV.y);
	vec3 soft = texture(scene_image, at - reach * 5.42).rgb * 0.10584 + texture(scene_image, at - reach * 1.48).rgb * 0.38416 + texture(scene_image, at + reach * 1.48).rgb * 0.38416 + texture(scene_image, at + reach * 5.42).rgb * 0.10584;
	vec3 sharp = texture(scene_image, UV * 0.99).rgb;
	vec3 a = min(sharp + soft, vec3(1.0));
	vec3 b = min(soft + a, vec3(1.0));
	vec3 c = min(a + b, vec3(1.0));
	COLOR = vec4(min(c + b, vec3(1.0)), 1.0);
}
