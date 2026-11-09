shader_type canvas_item;

uniform float gamma = 1.0;
uniform float echo_alpha = 0.0;
uniform float echo_zoom = 1.0;
uniform int echo_orientation = 0;
uniform bool brighten = false;
uniform bool darken = false;
uniform bool solarize = false;
uniform bool invert = false;

void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb;
	if (echo_alpha > 0.001) {
		vec2 echo_uv = (UV - 0.5) / max(echo_zoom, 0.01) + 0.5;
		if (echo_orientation == 1 || echo_orientation == 3) {
			echo_uv.x = 1.0 - echo_uv.x;
		}
		if (echo_orientation == 2 || echo_orientation == 3) {
			echo_uv.y = 1.0 - echo_uv.y;
		}
		color = mix(color, texture(TEXTURE, echo_uv).rgb, clamp(echo_alpha, 0.0, 1.0));
	}
	color *= gamma;
	if (brighten) {
		color = clamp(color, 0.0, 1.0);
		color = 1.0 - (1.0 - color) * (1.0 - color);
	}
	if (darken) {
		color = color * color;
	}
	if (solarize) {
		color = color * (1.0 - color);
		color = color * color + color;
	}
	if (invert) {
		color = 1.0 - color;
	}
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
