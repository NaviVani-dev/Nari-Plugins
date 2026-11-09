shader_type canvas_item;

uniform sampler2D star : filter_nearest;
uniform sampler2D table : filter_nearest;
uniform vec4 backdrop = vec4(0.0);

void fragment() {
	int gray = int(texture(star, UV).r * 255.0 + 0.5);
	vec4 entry = texelFetch(table, ivec2(min(gray, 254), 0), 0);
	COLOR = vec4(mix(entry.rgb, backdrop.rgb, min(entry.a + float(gray) / 255.0, 1.0)), 1.0);
}
