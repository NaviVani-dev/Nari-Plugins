shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int frame = 0;
uniform vec2 resolution = vec2(384.0, 288.0);
uniform int shift = 0;
uniform vec4 shape = vec4(0.0);
uniform int shift_from = 0;
uniform vec4 shape_from = vec4(0.0);
uniform float morph = 1.0;
uniform float seed = 0.0;

const int LINEAR = 1;
const int THINGUS = 2;
const int ZOOM = 3;
const int RING_SPIN = 4;
const int STRETCH = 5;
const int TILE = 6;
const int TRIG = 7;
const int SIN_SHIMMER = 8;
const int EDGE_FALLOFF = 9;
const int STARBURST = 10;
const int SWIRL = 11;
const int TWIRLOCITY = 12;
const int SHIITAKE = 13;
const int TRIG_STRETCH = 14;

float noise(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233)) + seed) * 43758.5453);
}

vec2 back(vec2 center, float angle, float radius) {
	return resolution - center - trunc(vec2(cos(angle), sin(angle)) * radius);
}

vec2 source(int kind, vec4 p, vec2 pixel, out bool keep) {
	keep = true;
	vec2 center = floor(resolution * 0.5);
	vec2 delta = center - pixel;
	float radius = length(delta);
	float angle = atan(delta.y, delta.x);
	float half_width = floor(resolution.x * 0.5);
	float half_height = floor(resolution.y * 0.5);
	float reach = length(resolution) * 0.5;
	if (kind == LINEAR) {
		return pixel + trunc(p.xy);
	} else if (kind == THINGUS) {
		float t = (floor(resolution.x * 0.25) - radius) / (half_width + floor(resolution.x * 0.25));
		return back(center, angle + t * p.x, resolution.x * p.y * t + radius);
	} else if (kind == ZOOM) {
		keep = false;
		return back(center, angle + p.x, radius - radius / reach * resolution.x * p.y);
	} else if (kind == RING_SPIN) {
		keep = false;
		float width = half_height * p.y;
		float rest = radius - trunc(radius / width) * width;
		return back(center, angle + p.x, radius - rest / width * rest);
	} else if (kind == STRETCH) {
		keep = false;
		float t = radius / half_width;
		return back(center, angle + t * p.x, radius - trunc(resolution.y * p.y) * t * t * t);
	} else if (kind == TILE) {
		float size = resolution.y * p.x;
		vec2 inside = pixel - trunc(pixel / size) * size;
		vec2 t = inside / size;
		return pixel - trunc(t * t * t * inside);
	} else if (kind == TRIG || kind == TRIG_STRETCH) {
		keep = kind != TRIG_STRETCH;
		float wave = 1.0;
		if (p.z < 0.5 || (p.z > 1.5 && mod(pixel.x, 2.0) < 0.5)) {
			wave = cos(angle) * 0.63694268;
		} else {
			wave = sin(angle) * 0.63694268;
		}
		float pulled = radius - radius / (reach) * resolution.x * p.y * wave;
		if (kind == TRIG) {
			return back(center, angle + p.x, pulled);
		}
		float t = radius / half_width;
		float final_radius = radius - trunc(resolution.y * p.w) * t * t * t;
		return back(center, (t * p.x + angle + (angle + p.x) * 2.0) * 0.33333333, final_radius);
	} else if (kind == SIN_SHIMMER) {
		float wave = (sin(pixel.y * p.y) + sin(pixel.x * p.y)) * p.x;
		if (p.z < 0.5) {
			return vec2(pixel.x, trunc(pixel.y - wave));
		}
		return vec2(trunc(pixel.x - wave), pixel.y);
	} else if (kind == EDGE_FALLOFF) {
		keep = false;
		float mode = trunc(p.y);
		float scale = p.x + 1.0;
		if (mode < 0.5) {
			return vec2(trunc(pixel.x * scale), pixel.y);
		} else if (mode < 1.5) {
			return vec2(pixel.x, trunc(pixel.y * scale));
		} else if (mode < 2.5) {
			float rest = resolution.x - pixel.x - 1.0;
			return vec2(pixel.x - trunc(scale * rest - rest), pixel.y);
		}
		float rest = resolution.y - pixel.y - 1.0;
		return vec2(pixel.x, pixel.y - trunc(scale * rest - rest));
	} else if (kind == STARBURST) {
		float strength = trunc(resolution.y * p.y);
		float t = radius / half_width;
		float grown = radius;
		if (p.w == 0.0) {
			t = sin(trunc(p.z) * angle) * t;
			grown = radius + strength * t * t * t;
		} else if (mod(abs(trunc(angle / (6.28 / p.z))), 2.0) < 0.5) {
			grown = radius - strength * t * t * t;
		} else {
			grown = radius + strength * t * t * t;
		}
		return back(center, angle + t * p.x, grown);
	} else if (kind == SWIRL) {
		vec2 moved = pixel + trunc(vec2(sin(p.z * 6.28 / resolution.y * pixel.y), cos(p.z * 6.28 / resolution.x * pixel.x)) * p.y);
		vec2 offset = center - moved;
		float spin = atan(offset.y, offset.x) + p.x;
		vec2 result = back(center, spin, length(offset) - sin(spin * p.z) * p.y);
		float wobble = floor(noise(pixel) * 4.0) - 2.0;
		result.x += pixel.x < center.x ? -wobble : wobble;
		result.y += pixel.y < center.y ? -wobble : wobble;
		return result;
	} else if (kind == TWIRLOCITY) {
		float scale = resolution.y * 0.5;
		float f = 0.0;
		if (p.z == 0.0) {
			f = radius / scale;
		} else if (radius != 0.0) {
			f = scale / radius;
		}
		return back(center, angle + cos(f * 3.1415927 * p.x) * p.y, radius);
	} else if (kind == SHIITAKE) {
		float grown = radius + p.x;
		float ring = half_height != 0.0 ? grown * 6.2831855 / half_height : grown;
		return back(center, angle + ring * p.z + cos(ring * p.w) * p.y, grown);
	}
	return pixel;
}

vec2 resolved(int kind, vec4 p, vec2 pixel) {
	bool keep;
	vec2 at = source(kind, p, pixel, keep);
	if (at.x < 0.0 || at.x >= resolution.x) {
		at.x = keep ? pixel.x : 0.0;
	}
	if (at.y < 0.0 || at.y >= resolution.y) {
		at.y = keep ? pixel.y : 0.0;
	}
	return at;
}

void fragment() {
	vec2 pixel = floor(SCREEN_UV * resolution);
	vec2 at = resolved(shift, shape, pixel);
	if (morph < 1.0) {
		vec2 from = resolved(shift_from, shape_from, pixel);
		at = from + trunc((at - from) * morph);
	}
	float value = texture(screen, (at + 0.5) / resolution).r;
	COLOR = vec4(frame < 2 ? 0.0 : value, 0.0, 0.0, 1.0);
}
