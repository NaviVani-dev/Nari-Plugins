shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform sampler2D mask : filter_nearest;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform float strength = 0.5;
uniform int operation = 0;
uniform vec4 pen_a = vec4(0.0);
uniform vec4 fill_a = vec4(0.0);
uniform vec4 pen_b = vec4(0.0);
uniform vec4 fill_b = vec4(0.0);
uniform vec4 disc_fill = vec4(0.0);
uniform vec4 disc_pen = vec4(0.0);
uniform float disc_width = 0.0;
uniform bool many = false;
uniform vec4 colors[16];
uniform int frame = 0;

ivec3 apply(ivec3 target, vec4 color) {
	ivec3 value = ivec3(color.rgb);
	if (operation == 1) {
		return target | value;
	} else if (operation == 2) {
		return target ^ value;
	}
	return value;
}

void fragment() {
	float scale = 480.0 / resolution.y;
	vec2 space = resolution * scale;
	float far = length((SCREEN_UV - 0.5) * space);
	float shrink = far > 1.0 ? (1.0 - strength / far) * 0.98 + 0.01 : 0.0;
	vec2 from = (SCREEN_UV - 0.5) * shrink + 0.5;
	ivec3 bits = ivec3(texture(mask, from).rgb * 255.0 + 0.5);
	ivec3 now = ivec3(0);
	if (many) {
		int pack = bits.r | (bits.g << 8);
		for (int index = 0; index < 16; index++) {
			if (((pack >> index) & 1) == 1) {
				now = now ^ ivec3(colors[index].rgb);
			}
		}
	} else {
		if ((bits.r & 1) == 1) {
			now = apply(now, fill_a);
		}
		if (bits.g > 127) {
			now = apply(now, pen_a);
		}
		if ((bits.r & 2) == 2) {
			now = apply(now, fill_b);
		}
		if (bits.b > 127) {
			now = apply(now, pen_b);
		}
		if (disc_width > 0.0) {
			float reach = length((from - 0.5) * space);
			if (reach <= 20.0 + disc_width * 0.5) {
				now = ivec3(reach >= 20.0 - disc_width * 0.5 ? disc_pen.rgb : disc_fill.rgb);
			}
		}
	}
	if (frame < 2) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		ivec3 before = ivec3(texture(screen, from).rgb * 255.0);
		COLOR = vec4(vec3((before * 248 >> 8) + (now * 8 >> 8)) / 255.0, 1.0);
	}
}
