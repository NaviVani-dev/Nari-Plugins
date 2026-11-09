shader_type canvas_item;
render_mode blend_disabled, skip_vertex_transform;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float simi[40];
uniform int nb = 2;
uniform int per_pair = 1;
uniform int increment = 1;
uniform vec2 half_size = vec2(320.0, 240.0);
uniform vec4 tint = vec4(1.0);

vec2 transform(int s, vec2 o) {
	int k = s * 8;
	vec2 c = vec2(simi[k], simi[k + 1]);
	float ct = simi[k + 2];
	float st = simi[k + 3];
	float ct2 = simi[k + 4];
	float st2 = simi[k + 5];
	vec2 a = (o - c) * simi[k + 6];
	vec2 b = vec2(a.x - c.x, -a.y - c.y) * simi[k + 7];
	return vec2(a.x * ct - a.y * st + b.x * ct2 - b.y * st2, a.x * st + a.y * ct + b.x * st2 + b.y * ct2) + c;
}

void vertex() {
	vec2 place = vec2(-10.0);
	if (INSTANCE_ID % increment == 0) {
		int pair = INSTANCE_ID / per_pair;
		int node = INSTANCE_ID % per_pair;
		int count = nb;
		int level = 1;
		while (node >= count) {
			node -= count;
			count *= nb;
			level += 1;
		}
		int cur = pair / (nb - 1);
		int other = pair % (nb - 1);
		if (other >= cur) {
			other += 1;
		}
		vec2 p = transform(other, vec2(simi[cur * 8], simi[cur * 8 + 1]));
		for (int k = 0; k < level; k++) {
			count /= nb;
			p = transform((node / count) % nb, p);
		}
		place = floor(half_size * vec2(1.0 + p.x * 0.5, 1.0 - p.y * 0.5));
	}
	VERTEX = place + UV;
}

void fragment() {
	COLOR = vec4(min(texture(screen, SCREEN_UV).rgb + tint.rgb, vec3(1.0)), 1.0);
}
