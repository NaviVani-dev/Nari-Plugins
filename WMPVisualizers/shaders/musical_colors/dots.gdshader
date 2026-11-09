shader_type canvas_item;
render_mode blend_disabled, skip_vertex_transform;

uniform sampler2D heights : filter_nearest;
uniform sampler2D sprites : filter_nearest;
uniform int sprite = 0;
uniform int rows = 5;
uniform int mode = 4;
uniform int count = 350;
uniform int bits = 2;
uniform int reach = 4;
uniform float amount = 200.0;
uniform int scroll = 0;
uniform int base = 0;
uniform vec2 center = vec2(175.0, 160.0);
uniform vec4 angle = vec4(0.0);
uniform vec4 axes = vec4(0.0);
uniform float twist = 0.0;
uniform float wave = 0.0;
uniform float phase = 0.0;
uniform float swing = 0.0;

varying flat vec4 paint;

const float RADIANS = 0.0174532925;

void vertex() {
	int column = INSTANCE_ID % 350;
	int row = INSTANCE_ID / 350;
	int h = int(texelFetch(heights, ivec2(column, 0), 0).r * 255.0 + 0.5);
	int first = mode == 4 ? h + 64 : h;
	int size = min(h + 1, rows);
	vec2 place = vec2(-10.0);
	if (column < count && row < size && (mode != 5 || h >= 3)) {
		int index = max((h + 1) * 3 + 2 - 5 * row, 0);
		int source = (index / 3 - scroll + 256) % 256;
		vec3 color = texelFetch(sprites, ivec2(sprite * 6 + index % 3, source), 0).rgb;
		int near = 1000;
		if ((bits & 2) != 0) {
			near = min(near, row + 1);
		}
		if ((bits & 1) != 0) {
			near = min(near, size - row);
		}
		float alpha = near <= reach ? (amount - float(near) * amount / float(reach)) / 255.0 : 0.0;
		color *= 1.0 - alpha;
		paint = vec4(color, alpha > 0.0 ? color.r : 0.0);
		vec2 d = vec2(float(column), float(first + rows - 1 - row)) - center;
		if (swing != 0.0) {
			d.x += cos(mod(abs(trunc(abs(d.y) * swing + phase)), 360.0) * RADIANS) * wave;
		}
		float spin = trunc(trunc(dot(d, d)) * twist);
		if (axes.z > 0.5) {
			float z = (angle.z - spin) * RADIANS;
			d = vec2(cos(z) * d.x + sin(z) * d.y, cos(z) * d.y - sin(z) * d.x);
		}
		if (axes.x > 0.5) {
			d.y *= cos((angle.x - spin) * RADIANS);
		}
		if (axes.y > 0.5) {
			d.x *= cos((angle.y - spin) * RADIANS);
		}
		vec2 at = trunc(d) + center;
		place = vec2(at.x, 319.0 - at.y);
	} else {
		paint = vec4(0.0, 0.0, 0.0, 1.0);
	}
	VERTEX = place + UV;
}

void fragment() {
	COLOR = paint;
}
