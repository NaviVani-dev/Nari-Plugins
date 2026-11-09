shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform vec2 resolution = vec2(640.0, 360.0);
uniform vec2 drift = vec2(0.0);
uniform float zoom = 1.0;
uniform float spin = 0.0;
uniform vec4 fade = vec4(0.9);
uniform float spread = 0.0;
uniform float wobble = 0.0;
uniform float time = 0.0;
uniform vec2 pivot = vec2(0.5);
uniform int frame = 0;

void fragment() {
	vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
	vec2 point = (SCREEN_UV - pivot) * aspect;
	point = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * point / zoom;
	vec2 uv = point / aspect + pivot + drift / resolution;
	uv.x += sin(uv.y * 23.0 + time * 3.0) * wobble / resolution.x;
	vec2 texel = spread / resolution;
	vec3 color = texture(screen, uv).rgb * 0.4;
	color += texture(screen, uv + vec2(texel.x, 0.0)).rgb * 0.15;
	color += texture(screen, uv - vec2(texel.x, 0.0)).rgb * 0.15;
	color += texture(screen, uv + vec2(0.0, texel.y)).rgb * 0.15;
	color += texture(screen, uv - vec2(0.0, texel.y)).rgb * 0.15;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		color = vec3(0.0);
	}
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color * fade.rgb, 1.0);
}
