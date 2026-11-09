shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float attenuation = 0.9;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform int frame = 0;

void fragment() {
	vec2 reach = vec2(resolution.y / 480.0) * 4.0 / resolution;
	vec3 color = texture(screen, SCREEN_UV).rgb * 0.2;
	color += texture(screen, SCREEN_UV + reach * vec2(1.0, 0.0)).rgb * 0.125;
	color += texture(screen, SCREEN_UV + reach * vec2(-1.0, 0.0)).rgb * 0.125;
	color += texture(screen, SCREEN_UV + reach * vec2(0.0, 1.0)).rgb * 0.125;
	color += texture(screen, SCREEN_UV + reach * vec2(0.0, -1.0)).rgb * 0.125;
	color += texture(screen, SCREEN_UV + reach * vec2(1.0, 1.0)).rgb * 0.075;
	color += texture(screen, SCREEN_UV + reach * vec2(-1.0, 1.0)).rgb * 0.075;
	color += texture(screen, SCREEN_UV + reach * vec2(1.0, -1.0)).rgb * 0.075;
	color += texture(screen, SCREEN_UV + reach * vec2(-1.0, -1.0)).rgb * 0.075;
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color * attenuation, 1.0);
}
