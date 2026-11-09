shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform sampler2D heights : filter_nearest;
uniform sampler2D sprites : filter_nearest;
uniform int frame = 0;
uniform bool solid = true;
uniform int sprite = 0;
uniform int roll = 0;
uniform int mode = 0;
uniform int count = 350;
uniform int bits = 0;
uniform int reach = 0;
uniform float amount = 0.0;
uniform vec4 tint = vec4(0.0);
uniform int hue = 0;
uniform bool trail = false;
uniform bool smear = false;
uniform float fade = 0.0;
uniform ivec2 shift = ivec2(0);
uniform bool warped = false;
uniform vec2 center = vec2(175.0, 160.0);
uniform vec4 angle = vec4(0.0);
uniform vec4 axes = vec4(0.0);
uniform float twist = 0.0;
uniform bool frost = false;
uniform vec4 frost_color = vec4(1.0);

const float RADIANS = 0.0174532925;

int bar(int x) {
	return int(texelFetch(heights, ivec2(x, 0), 0).r * 255.0 + 0.5);
}

int start(int h) {
	if (mode == 3) {
		return 320 - h;
	}
	if (mode == 4) {
		return h + 64;
	}
	if (mode == 5) {
		return h;
	}
	return h - 255;
}

vec3 rotated(vec3 color) {
	if (hue == 0) {
		return color;
	}
	vec3 c = color;
	if (hue < -179 || hue > 89) {
		c = color.gbr;
	} else if (hue < -89) {
		c = color.brg;
	}
	int turn = abs(hue);
	while (turn > 90) {
		turn -= 90;
	}
	float k = cos(float(turn) * RADIANS);
	vec3 rest = c * (1.0 - k);
	return hue < 0 ? c * k + rest.brg : c * k + rest.gbr;
}

vec2 unwarp(vec2 at) {
	vec2 d = at - center;
	vec2 p = d;
	for (int step = 0; step < 2; step++) {
		float spin = trunc(dot(p, p)) * twist;
		float cx = axes.x > 0.5 ? cos((angle.x - trunc(spin)) * RADIANS) : 1.0;
		float cy = axes.y > 0.5 ? cos((angle.y - trunc(spin)) * RADIANS) : 1.0;
		vec2 q = vec2(d.x / max(abs(cy), 0.01) * sign(cy), d.y / max(abs(cx), 0.01) * sign(cx));
		if (axes.z > 0.5) {
			float z = (angle.z - trunc(spin)) * RADIANS;
			q = vec2(cos(z) * q.x - sin(z) * q.y, sin(z) * q.x + cos(z) * q.y);
		}
		p = q;
	}
	return p + center;
}

vec4 past(int x, int y) {
	vec2 at = vec2(float(x), float(y)) + 0.5;
	if (warped) {
		at = unwarp(at);
	}
	ivec2 from = ivec2(floor(at)) - shift;
	vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
	if (from.x >= 0 && from.y >= 0 && from.x < 350 && from.y < 320) {
		value = texture(screen, (vec2(float(from.x), float(319 - from.y)) + 0.5) / vec2(350.0, 320.0));
	}
	if (smear && value.a >= 1.0) {
		value = texture(screen, (vec2(float(x), float(319 - y)) + 0.5) / vec2(350.0, 320.0));
	}
	return value;
}

void fragment() {
	int x = int(UV.x * 350.0);
	int y = 319 - int(UV.y * 320.0);
	vec4 result = vec4(0.0, 0.0, 0.0, 1.0);
	if (trail && frame > 1) {
		result = past(x, y);
		result.a += fade;
		if (result.a >= 0.999) {
			result = vec4(0.0, 0.0, 0.0, 1.0);
		}
	}
	if (solid) {
		int top = -1;
		int low = 320;
		bool found = false;
		vec3 color = vec3(0.0);
		ivec2 runs = ivec2(255);
		for (int c = 0; c < 3; c++) {
			int column = x - c;
			if (column < 0 || column >= count) {
				continue;
			}
			int first = start(bar(column));
			top = max(top, min(first + 255, 319));
			low = min(low, max(first, 0));
			if (found || y < first || y > first + 255) {
				continue;
			}
			int row = (first + 255 - y + roll) % 256;
			vec3 pixel = texelFetch(sprites, ivec2(sprite * 6 + c, row), 0).rgb;
			if (pixel != vec3(0.0)) {
				found = true;
				color = pixel;
				vec2 run = texelFetch(sprites, ivec2(sprite * 6 + 3 + c, row), 0).rg * 255.0 + 0.5;
				runs = ivec2(run);
			}
		}
		if (frost && y == 0 && x < 255 && bar(x) == 0) {
			found = true;
			color = frost_color.rgb;
		}
		if (found) {
			color = rotated(color);
			float alpha = 0.0;
			if (bits != 0 && reach > 0) {
				int near = 1000;
				if ((bits & 1) != 0) {
					near = min(near, min(top - y + 1, runs.x));
				}
				if ((bits & 2) != 0) {
					near = min(near, min(y - low + 1, runs.y));
				}
				if ((bits & 8) != 0) {
					int side = 1;
					for (int k = 1; k < reach; k++) {
						int column = x - k;
						if (column < 0) {
							break;
						}
						int first = start(bar(column));
						if (y < first || y > first + 255) {
							break;
						}
						side += 1;
					}
					near = min(near, side);
				}
				if (near <= reach) {
					alpha = min(amount - float(near) * amount / float(reach), 255.0) / 255.0;
					if (tint.rgb != vec3(0.0)) {
						color = mix(color, tint.rgb, 1.0 - float(near - 1) / float(reach));
					}
				}
			}
			result = vec4(color, alpha);
		}
	}
	COLOR = frame < 2 && !solid ? vec4(0.0, 0.0, 0.0, 1.0) : result;
}
