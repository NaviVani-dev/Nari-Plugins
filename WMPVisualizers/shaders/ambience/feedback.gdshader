shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int frame = 0;
uniform vec2 resolution = vec2(384.0, 288.0);
uniform int warp = 0;
uniform float rot = 0.0;
uniform float amount = 0.0;
uniform bool blur_first = false;
uniform bool fade = true;
uniform float fade_low = 2.0;
uniform float fade_high = 2.0;

float index_at(vec2 pixel) {
	vec2 clamped = clamp(pixel, vec2(0.0), resolution - 1.0);
	return floor(texture(screen, (clamped + 0.5) / resolution).r * 255.0 + 0.5);
}

vec2 source(vec2 pixel) {
	vec2 center = floor(resolution * 0.5);
	vec2 delta = center - pixel;
	float radius = length(delta);
	float angle = atan(delta.y, delta.x);
	float reach = length(resolution) * 0.5;
	float next = radius;
	if (warp == 0) {
		return pixel;
	} else if (warp == 1) {
		next = radius - amount;
		angle += rot;
	} else if (warp == 2) {
		next = radius - radius / reach * amount;
		angle += rot;
	} else if (warp == 3) {
		angle += rot * abs(delta.x) / center.x * sign(delta.x * delta.y + 0.0001);
		next = radius - radius / reach * amount;
	} else if (warp == 10) {
		angle -= rot * abs(delta.x) / reach;
		next = radius - radius / reach * amount;
	} else if (warp == 4) {
		float rim = center.y - 10.0;
		if (radius > rim) {
			return pixel;
		}
		float t = radius / rim;
		float pulled = max(radius - max(rim * t * t * t, 1.0), 0.0);
		return resolution - center - trunc(pulled * vec2(cos(angle + rot), sin(angle + rot)));
	} else if (warp == 5) {
		float t = max(1.0 - radius * radius / dot(center, center), 0.05);
		angle += t * rot;
		next = radius + (1.0 - t) * radius * t * t * t * t * t;
	} else if (warp == 6) {
		float t = abs(delta.x) / center.x;
		float rise = trunc(t * t * t * resolution.y * 0.06);
		float pull = trunc((1.0 - t) * resolution.y * 0.025);
		if (pixel.x > center.x) {
			pull = -pull;
		}
		return clamp(pixel + vec2(-pull, rise), vec2(0.0), resolution - 1.0);
	} else if (warp == 7) {
		float t = radius / reach;
		next = radius - amount;
		angle += rot * (1.0 + t * t);
	} else if (warp == 8) {
		float k = radius > 1.0 ? 1.0 - 1.0 / radius : 0.0;
		next = radius + amount * k * 0.08;
		angle += rot * k;
	} else if (warp == 9) {
		float ring = amount;
		float t = clamp((radius - ring) / max(center.y - ring, 1.0), -1.0, 1.0);
		next = radius - t * t * t * 6.0 - 1.0;
		angle += rot;
	}
	if (next <= 0.0) {
		return pixel;
	}
	vec2 result = resolution - center - trunc(next * vec2(cos(angle), sin(angle)));
	if (result.x < 0.0 || result.y < 0.0 || result.x >= resolution.x || result.y >= resolution.y) {
		return pixel;
	}
	return result;
}

float fade_index(float value) {
	if (!fade) {
		return clamp(value, 1.0, 254.0);
	}
	float step = value < 128.0 ? fade_low : fade_high;
	return clamp(value - step, 1.0, 254.0);
}

float blurred(vec2 pixel) {
	float total = index_at(pixel) + index_at(pixel + vec2(1.0, 0.0)) + index_at(pixel - vec2(1.0, 0.0))
		+ index_at(pixel + vec2(0.0, 1.0)) + index_at(pixel - vec2(0.0, 1.0));
	return fade_index(floor(total / 5.0));
}

float warped(vec2 pixel) {
	return index_at(source(pixel));
}

void fragment() {
	vec2 pixel = floor(SCREEN_UV * resolution);
	float value;
	bool edge = pixel.x < 1.0 || pixel.y < 1.0 || pixel.x > resolution.x - 2.0 || pixel.y > resolution.y - 2.0;
	if (blur_first) {
		value = blurred(source(pixel));
	} else if (edge) {
		value = fade_index(warped(pixel));
	} else {
		float total = warped(pixel) + warped(pixel + vec2(1.0, 0.0)) + warped(pixel - vec2(1.0, 0.0))
			+ warped(pixel + vec2(0.0, 1.0)) + warped(pixel - vec2(0.0, 1.0));
		value = fade_index(floor(total / 5.0));
	}
	COLOR = vec4((frame < 2 ? 1.0 : value) / 255.0, 0.0, 0.0, 1.0);
}
