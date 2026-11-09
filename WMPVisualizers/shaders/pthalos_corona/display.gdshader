shader_type canvas_item;

uniform sampler2D palettes : filter_nearest;
uniform float palette_old = 0.0;
uniform float palette_new = 0.0;
uniform float fade = 0.0;

void fragment() {
	bool below = UV.y > 0.8;
	float row = below ? 1.0 - (UV.y - 0.8) / 0.8 : UV.y / 0.8;
	float index = texture(TEXTURE, vec2(UV.x, row)).r * 255.0 / 256.0 + 0.5 / 256.0;
	vec3 a = texture(palettes, vec2(index, (palette_old + 0.5) / 31.0)).rgb;
	vec3 b = texture(palettes, vec2(index, (palette_new + 0.5) / 31.0)).rgb;
	vec3 color = mix(a, b, fade);
	COLOR = vec4(below ? color * 0.7 : color, 1.0);
}
