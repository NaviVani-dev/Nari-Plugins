shader_type canvas_item;

uniform int rise = 0;
uniform bool overlay = false;
uniform bool quarter = false;
uniform int lift = 0;
uniform sampler2D heights : filter_nearest;
uniform sampler2D sprites : filter_nearest;
uniform int sprite = 0;
uniform int roll = 0;
uniform int count = 350;

void fragment() {
	vec2 at = UV + vec2(0.0, float(rise) / 320.0);
	if (quarter) {
		vec2 p = UV * vec2(350.0, 320.0);
		at = vec2(175.0 + p.y - 160.0, 160.0 - p.x + 175.0) / vec2(350.0, 320.0);
		if (at.x < 0.0 || at.x > 1.0 || at.y < 0.0) {
			at.y = 2.0;
		}
	}
	vec4 value = at.y < 1.0 ? texture(TEXTURE, at) : vec4(0.0, 0.0, 0.0, 1.0);
	vec3 color = max(value.rgb - value.a, vec3(0.0));
	if (overlay) {
		int x = int(UV.x * 350.0);
		int y = 319 - lift - int(UV.y * 320.0);
		for (int c = 0; c < 3; c++) {
			int column = x - c;
			if (column < 0 || column >= count || y < 0) {
				continue;
			}
			int h = int(texelFetch(heights, ivec2(column, 0), 0).r * 255.0 + 0.5);
			if (y <= h) {
				vec3 pixel = texelFetch(sprites, ivec2(sprite * 6 + c, (h - y + roll) % 256), 0).rgb;
				if (pixel != vec3(0.0)) {
					color = pixel;
					break;
				}
			}
		}
	}
	COLOR = vec4(color, 1.0);
}
