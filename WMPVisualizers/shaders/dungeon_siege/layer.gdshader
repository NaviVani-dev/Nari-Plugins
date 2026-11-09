shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D mask : filter_nearest;
uniform float offset = 0.0;
uniform float radius = 0.0;
uniform float fade = 0.0;
uniform float gain_source = 0.0;
uniform float gain_dest = 0.0;

void fragment() {
	vec4 pixel = texture(TEXTURE, vec2(UV.x, fract(UV.y + offset)));
	float run = pixel.a * 255.0;
	if (run < 0.5) {
		discard;
	}
	float alpha = texture(mask, UV).r + fade;
	if (radius > 0.0 && run <= radius) {
		alpha += max(0.0, 256.0 - run * 256.0 / radius) / 255.0;
	}
	alpha = min(alpha, 1.0);
	COLOR = vec4(pixel.rgb * (1.0 - alpha + gain_source * step(alpha, 0.999)), 1.0 - min(alpha + gain_dest * step(alpha, 0.999), 1.0));
}
