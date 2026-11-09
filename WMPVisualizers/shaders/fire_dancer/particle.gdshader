shader_type canvas_item;
render_mode skip_vertex_transform, blend_mix;

uniform sampler2D bones : filter_nearest;
uniform float tick = 0.0;
uniform float floor_y = 0.0;
uniform vec2 scale_to = vec2(1.0);

varying float heat;
varying float cover;
varying vec2 local;

float roll(float seed, float index) {
	return fract(sin(seed * 12.9898 + index * 78.233) * 43758.5453);
}

void vertex() {
	float blob = INSTANCE_CUSTOM.x * 255.0;
	float id = INSTANCE_CUSTOM.y;
	float life = 5.0 + floor(roll(id, 1.0) * 27.0);
	float clock = tick - INSTANCE_CUSTOM.z * 255.0 + floor(roll(id, 2.0) * 256.0);
	float age = mod(clock, life) + 1.0;
	float seed = id + floor(clock / life) * 0.137;
	int row = int(blob);
	vec3 axis_x = texelFetch(bones, ivec2(0, row), 0).xyz;
	vec3 axis_y = texelFetch(bones, ivec2(1, row), 0).xyz;
	vec3 axis_z = texelFetch(bones, ivec2(2, row), 0).xyz;
	vec3 place = texelFetch(bones, ivec2(3, row), 0).xyz;
	vec3 center = texelFetch(bones, ivec2(4, row), 0).xyz;
	vec3 radius = texelFetch(bones, ivec2(5, row), 0).xyz;
	vec3 spread = radius * vec3(roll(seed, 3.0), roll(seed, 4.0), roll(seed, 5.0));
	float tilt = roll(seed, 6.0) * TAU;
	float turn = roll(seed, 7.0) * TAU;
	vec3 local_point = center + vec3(cos(turn) * spread.x * sin(tilt), sin(turn) * spread.y * sin(tilt), cos(tilt) * spread.z);
	vec3 world = local_point.x * axis_x + local_point.y * axis_y + local_point.z * axis_z + place;
	vec3 middle = center.x * axis_x + center.y * axis_y + center.z * axis_z + place;
	vec2 pull = vec2(middle.x + world.x, middle.z + world.z) / 3.5;
	vec2 speed = vec2((roll(seed, 8.0) - 0.5) / (floor(roll(seed, 9.0) * 1800.0) + 32.0), (roll(seed, 10.0) - 0.5) / (floor(roll(seed, 11.0) * 1800.0) + 32.0));
	float keep = pow(23.0 / 24.0, age);
	float glide = (23.0 / 24.0) * (keep - pow(7.0 / 8.0, age)) / (23.0 / 24.0 - 7.0 / 8.0);
	vec2 wander = (vec2(roll(seed, 12.0), roll(seed, 13.0)) - 0.5) * sqrt(age) / 100.0;
	vec2 flat_point = vec2(world.x, world.z) * keep + pull * (1.0 - keep) + speed * glide + wander;
	float rise = world.y - floor_y + age * (roll(seed, 14.0) - 0.5) / 112.5 + 0.00095 * age * (age - 1.0) * 0.5;
	float distance_to = length(vec2(flat_point.x - middle.x, rise - middle.y)) * 200.0;
	float depth = clamp(round(flat_point.y * 256.0), -256.0, 256.0);
	heat = clamp((255.0 - 2.0 * age - (128.0 - floor((depth + 256.0) / 4.0)) - round(distance_to)) * 1.3, 0.0, 255.0) / 255.0;
	float opacity = (32.0 - age) / 32.0;
	cover = (1.0 - pow(1.0 - opacity, 3.0)) * 0.25;
	local = UV;
	vec2 screen_point = vec2(round(flat_point.x * 200.0) + 160.0, round((1.0 - rise) * 200.0) + 120.0);
	VERTEX = (screen_point + (UV - vec2(0.5)) * vec2(11.0, 17.0)) * scale_to;
}

void fragment() {
	float t = (floor(local.y * 17.0) + 1.0) / 18.0;
	float s = 2.0 * t - 1.0;
	float half_width = 5.5 * sqrt(max(1.0 - s * s, 0.0)) * sqrt(t);
	if (abs(local.x - 0.5) * 11.0 > half_width) {
		discard;
	}
	COLOR = vec4(heat, heat, heat, cover);
}
