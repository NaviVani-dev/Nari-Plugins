shader_type canvas_item;

uniform sampler2D palette : filter_linear, repeat_enable;
uniform float scroll = 0.0;
uniform float gain = 1.0;
uniform float floor = 0.0;
uniform float shift = 0.1;
uniform bool plain = false;

void fragment() {
	vec3 base = texture(TEXTURE, UV).rgb;
	float glow = clamp(base.r * gain - floor, 0.0, 1.0);
	vec3 tint = texture(palette, vec2(0.5, fract(scroll + glow * shift))).rgb;
	vec3 mixed = tint * smoothstep(0.0, 0.8, glow) + vec3(base.g * 0.5, base.g, base.b);
	COLOR = vec4(plain ? base : mixed, 1.0);
}
