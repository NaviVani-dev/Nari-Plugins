shader_type canvas_item;

uniform vec2 resolution = vec2(320.0, 384.0);
uniform vec4 main_color = vec4(128.0, 0.0, 0.0, 0.0);
uniform vec4 dim_color = vec4(0.0);

void fragment() {
	vec2 size = 1.0 / resolution;
	vec2 at = (floor(UV * resolution) + 0.5) * size;
	float value = texture(TEXTURE, at).r + texture(TEXTURE, at + vec2(0.0, size.y)).r + texture(TEXTURE, at + size).r + texture(TEXTURE, at + vec2(size.x, 0.0)).r;
	float index = floor(value * 255.0 / 4.0);
	vec3 shade;
	if (index < 128.0) {
		shade = main_color.rgb * 2.0 * index / 255.0;
	} else {
		float back = 255.0 - index;
		shade = (dim_color.rgb * (255.0 - 2.0 * back) + main_color.rgb * 2.0 * back) / 255.0;
	}
	COLOR = vec4(shade / 255.0, 1.0);
}
