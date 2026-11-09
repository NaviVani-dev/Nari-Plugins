shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform float heights[352];
uniform int count = 350;
uniform ivec2 source = ivec2(3, 320);
uniform int mode = 4;
uniform int place = 1;
uniform int strip = 256;
uniform int strip_roll = 0;
uniform int roll = 0;
uniform int edge_reach = 0;
uniform int edge_amount = 0;
uniform int edge_side = 0;
uniform int reach = 0;
uniform int amount = 0;
uniform int sides = 15;
uniform int bright = 0;
uniform bool hidden = false;

vec3 tone(int index) {
	int total = source.x * source.y;
	int at = clamp(index, 0, total - 1);
	int row = (at / source.x - roll) % source.y;
	if (row < 0) {
		row += source.y;
	}
	return texelFetch(palette, ivec2(at % source.x, row), 0).rgb;
}

int column_height(int x) {
	return x < count && x >= 0 ? int(heights[x]) : -1;
}

int side_run(int x, int line, int direction, int limit) {
	int run = 0;
	int at = x;
	while (run < limit) {
		int value = column_height(at + direction);
		int top = 319 - (160 - value / 2);
		if (value <= 0 || line > top || line <= top - value) {
			break;
		}
		at += direction;
		run += 1;
	}
	return run + 1;
}

void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	int x = int(UV.x * 352.0);
	int line = 319 - int(UV.y * 320.0);
	int value = column_height(x);
	bool drawn = !hidden && value >= 0 && !(place == 5 && value <= 2);
	int base = 0;
	int turn = strip_roll;
	if (place < 3) {
		base = value - 255;
	} else if (place == 6) {
		base = value - 268;
	} else if (place == 8) {
		turn = 160 - value / 2;
	}
	int slot = base + strip - 1 - line;
	drawn = drawn && slot >= 0 && slot < strip;
	if (drawn) {
		int row = (slot - turn) % strip;
		if (row < 0) {
			row += strip;
		}
		vec3 color = vec3(0.0);
		int shade = 0;
		int low = max(base, 0);
		int high = min(base + strip - 1, 319);
		if (mode == 4) {
			color = tone(source.x * value + 1 - row);
		} else if (mode == 2 || mode == 3) {
			if (row < value) {
				color = tone(row);
				if (mode == 3 && value > 2 && row >= value - 3) {
					shade = 128 >> (value - 1 - row);
				}
			} else {
				color = tone(source.x * 256);
			}
		} else if (mode == 5) {
			if (row >= value) {
				drawn = false;
			} else {
				int first = (value + 1) / 2;
				color = tone(row < first ? row : first - (row - first));
				high = 319 - turn;
				low = high - value + 1;
			}
		} else if (mode == 6) {
			int first = (value + 1) / 2;
			if (row < first) {
				color = tone(row);
				shade = first - row;
			} else if (row < value) {
				color = tone(first - (row - first));
				shade = (value - row) >> 2;
			} else {
				int rest = strip - value;
				int lead = (rest + 1) / 2;
				int into = row - value;
				if (into < lead) {
					color = tone(0);
					shade = into;
				} else {
					color = tone(200);
					shade = rest - into + 20;
				}
			}
			shade = shade & 255;
		}
		if (drawn && edge_reach > 0 && edge_amount > 0) {
			int gap = edge_side == 1 ? min(strip - row, 255) : min(row + 1, 255);
			if (gap <= edge_reach) {
				shade = min(edge_amount - gap * edge_amount / edge_reach, 255);
			}
		}
		if (drawn && shade < 255) {
			vec3 lit = color * 255.0 * (1.0 - float(shade) / 255.0);
			int gap = 65534;
			if ((sides & 1) != 0) {
				gap = min(gap, min(high - line + 1, 255));
			}
			if ((sides & 2) != 0) {
				gap = min(gap, min(line - low + 1, 255));
			}
			if ((sides & 12) != 0) {
				if (mode == 5) {
					int limit = min(min(reach, 255), gap);
					if ((sides & 8) != 0) {
						gap = min(gap, side_run(x, line, -1, limit));
						limit = min(limit, gap);
					}
					if ((sides & 4) != 0) {
						gap = min(gap, side_run(x, line, 1, limit));
					}
				} else {
					if ((sides & 8) != 0) {
						gap = min(gap, min(x + 1, 255));
					}
					if ((sides & 4) != 0) {
						gap = min(gap, min(count - x, 255));
					}
				}
			}
			int alpha = shade;
			if (reach > 0 && gap <= reach) {
				alpha = min(amount - gap * amount / reach, 255);
			}
			if (alpha < 255) {
				vec3 raised = min(floor(lit) + float(bright), vec3(255.0));
				COLOR.rgb = max(raised - float(alpha), vec3(0.0)) / 255.0;
			}
		}
	}
}
