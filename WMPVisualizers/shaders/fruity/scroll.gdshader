shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec4 first = vec4(0.0);
uniform vec4 second = vec4(0.0);
uniform float shift = 0.0;
uniform float fade = 1.0;
uniform int frame = 0;

bool inside(vec2 uv, vec4 box) {
	return uv.x >= box.x && uv.y >= box.y && uv.x <= box.z && uv.y <= box.w;
}

void fragment() {
	vec3 color = vec3(0.0);
	if (frame >= 2 && (inside(SCREEN_UV, first) || inside(SCREEN_UV, second))) {
		color = texture(screen, SCREEN_UV - vec2(shift, 0.0)).rgb * fade;
	}
	COLOR = vec4(color, 1.0);
}
