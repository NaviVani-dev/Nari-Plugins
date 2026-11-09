shader_type canvas_item;
render_mode blend_disabled, skip_vertex_transform;

uniform sampler2D heights : filter_nearest;
uniform sampler2D sprites : filter_nearest;
uniform int sprite = 0;
uniform int roll = 0;
uniform int count = 350;
uniform int reach = 90;
uniform float amount = 255.0;
uniform vec2 center = vec2(175.0, 372.0);
uniform float tilt = 15.0;
uniform float twist = -0.002;
uniform float swing = 7.12;
uniform float wave = 22.0;
uniform float bend = -0.00002;

varying float at_y;
varying float at_top;

const float RADIANS = 0.0174532925;

void vertex() {
	int column = INSTANCE_ID;
	int h = int(texelFetch(heights, ivec2(column, 0), 0).r * 255.0 + 0.5);
	float y = UV.y * float(h);
	at_y = y;
	at_top = float(h);
	vec2 place = vec2(-10.0);
	if (column < count) {
		vec2 d = vec2(float(column), y) - center;
		d.y += cos(mod(abs(trunc(abs(d.x) * swing)), 360.0) * RADIANS) * (d.x * d.x * bend + wave);
		float spin = trunc(trunc(dot(d, d)) * twist);
		d.x *= cos((tilt - spin) * RADIANS);
		vec2 to = d + center;
		place = vec2(to.x, 319.0 - to.y);
		VERTEX = vec2((UV.x - 0.5) * 8.0, 0.0) + place;
	} else {
		VERTEX = place;
	}
}

void fragment() {
	int row = (int(at_top - at_y) + roll) % 256;
	vec3 color = texelFetch(sprites, ivec2(sprite * 6, row), 0).rgb;
	float near = min(at_top - at_y + 1.0, at_y + 1.0);
	float alpha = near <= float(reach) ? (amount - near * amount / float(reach)) / 255.0 : 0.0;
	COLOR = vec4(color, alpha);
}
