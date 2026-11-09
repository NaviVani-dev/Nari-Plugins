shader_type canvas_item;

uniform float crop = 1.0;

void fragment() {
	vec2 at = (UV - 0.5) / crop + 0.5;
	bool inside = at.x >= 0.0 && at.y >= 0.0 && at.x <= 1.0 && at.y <= 1.0;
	COLOR = vec4(inside ? texture(TEXTURE, at).rgb : vec3(0.0), 1.0);
}
