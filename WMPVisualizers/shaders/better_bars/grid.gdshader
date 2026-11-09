shader_type canvas_item;

uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec2 pitch = vec2(10.0, 3.0);
uniform float bottom = 456.0;

void fragment() {
	vec2 pixel = UV * resolution;
	vec4 color = texture(TEXTURE, UV);
	if (pixel.y < bottom) {
		vec2 cell = mod(vec2(pixel.x, bottom - pixel.y), pitch);
		if (cell.x >= pitch.x - 1.0 || cell.y >= pitch.y - 1.0) {
			color.rgb = vec3(0.0);
		}
	}
	COLOR = color;
}
