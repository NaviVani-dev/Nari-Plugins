shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform sampler2D from_field : filter_linear;
uniform sampler2D to_field : filter_linear;
uniform float ratio = 0.0;
uniform float noise_from = 0.0;
uniform float noise_to = 0.0;
uniform int frame = 0;
uniform vec2 resolution = vec2(640.0, 480.0);
uniform vec2 grid = vec2(65.0, 49.0);

float random(vec2 at) {
	return fract(sin(dot(at, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 at = floor(SCREEN_UV * resolution);
	vec2 cell = (at / (resolution - 1.0) * (grid - 1.0) + 0.5) / grid;
	vec2 move = mix(texture(from_field, cell).rg, texture(to_field, cell).rg, ratio);
	float noise = mix(noise_from, noise_to, ratio);
	if (noise > 0.0) {
		move += noise * (vec2(random(at), random(at + 37.0)) - 0.5) / 50.0;
	}
	ivec2 p = ivec2(floor((at - move * resolution.x * 0.5) * 16.0));
	ivec2 limit = (ivec2(resolution) - 1) * 16;
	vec3 color = vec3(0.0);
	if (frame >= 2 && p.x >= 0 && p.y >= 0 && p.x < limit.x && p.y < limit.y) {
		ivec2 base = p >> 4;
		int fx = p.x & 15;
		int fy = p.y & 15;
		vec4 weight = vec4(255.0, 0.0, 0.0, 0.0);
		if (fx != 0 || fy != 0) {
			vec4 raw = vec4(float((16 - fx) * (16 - fy)), float(fx * (16 - fy)), float((16 - fx) * fy), float(fx * fy));
			weight = max(raw - 1.0, vec4(0.0));
		}
		vec3 sum = round(texelFetch(screen, base, 0).rgb * 255.0) * weight.x;
		sum += round(texelFetch(screen, base + ivec2(1, 0), 0).rgb * 255.0) * weight.y;
		sum += round(texelFetch(screen, base + ivec2(0, 1), 0).rgb * 255.0) * weight.z;
		sum += round(texelFetch(screen, base + ivec2(1, 1), 0).rgb * 255.0) * weight.w;
		sum = mix(sum, sum - 5.0, step(5.5, sum));
		color = floor(sum / 256.0) / 255.0;
	}
	COLOR = vec4(color, 1.0);
}
