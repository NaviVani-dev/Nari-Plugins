shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform float fall = 0.04;
uniform int frame = 0;

void fragment() {
	vec2 texel = vec2(480.0 / resolution.y) * 1.0 / resolution;
	vec3 color = texture(screen, SCREEN_UV).rgb * 0.25;
	color += texture(screen, SCREEN_UV + vec2(texel.x, texel.y)).rgb * 0.1875;
	color += texture(screen, SCREEN_UV + vec2(-texel.x, texel.y)).rgb * 0.1875;
	color += texture(screen, SCREEN_UV + vec2(texel.x, -texel.y)).rgb * 0.1875;
	color += texture(screen, SCREEN_UV + vec2(-texel.x, -texel.y)).rgb * 0.1875;
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color - fall, 1.0);
}
