shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D sky : filter_linear, repeat_disable;
uniform sampler2D cloud1 : filter_linear_mipmap, repeat_disable;
uniform sampler2D cloud2 : filter_linear_mipmap, repeat_disable;
uniform vec4 place[8];
uniform float pitch[8];
uniform float fade[8];

vec3 over(vec3 back, sampler2D tex, vec2 ray, int index) {
	if (fade[index] >= 1.0) {
		return back;
	}
	float c = cos(pitch[index]);
	float s = sin(pitch[index]);
	vec3 q = place[index].xyz;
	float t = (c / s * q.y + q.z - 61.0) / (c / s * ray.y - 1.0);
	if (t <= 0.0) {
		return back;
	}
	vec2 plane = vec2(t * ray.x - q.x, (t * ray.y - q.y) / -s);
	vec2 uv = (plane + 32.0) / 64.0;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return back;
	}
	vec3 tint = texture(tex, uv).rgb;
	float r = tint.r >= 0.55 ? min(tint.r * 1.08, 1.0) : tint.r;
	return mix(back, tint, max(r * r * r * r - fade[index], 0.0));
}

void fragment() {
	vec3 color = texture(sky, (UV - 0.5) / 1.05 + 0.5).rgb;
	float band = clamp((UV.y - 0.728) / 0.272, 0.0, 1.0);
	color = mix(color, vec3(1.0), (1.0 - pow(1.0 - band, 1.7)) * 0.95);
	vec2 ray = vec2((UV.x * 2.0 - 1.0) / 1.299, (1.0 - UV.y * 2.0) / 1.7321);
	color = over(color, cloud1, ray, 0);
	color = over(color, cloud2, ray, 1);
	color = over(color, cloud2, ray, 2);
	color = over(color, cloud1, ray, 3);
	color = over(color, cloud1, ray, 4);
	color = over(color, cloud2, ray, 5);
	color = over(color, cloud2, ray, 6);
	color = over(color, cloud1, ray, 7);
	COLOR = vec4(color, 1.0);
}
