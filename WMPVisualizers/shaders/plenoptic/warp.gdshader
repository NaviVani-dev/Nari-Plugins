shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec2 resolution = vec2(256.0, 192.0);
uniform float zoom = 1.0;

void fragment() {
	vec2 half_size = floor(resolution * 0.5);
	vec2 pixel = floor(SCREEN_UV * resolution) - half_size;
	vec2 spot = floor(pixel / zoom + 0.5) + half_size;
	COLOR = vec4(texture(screen, (clamp(spot, vec2(0.0), resolution - 1.0) + 0.5) / resolution).rgb, 1.0);
}
