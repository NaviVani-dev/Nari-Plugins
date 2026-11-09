shader_type canvas_item;
render_mode blend_disabled;

uniform float curve1[65];
uniform float curve2[65];
uniform float curve3[65];

const vec3 CENTER = vec3(0.6039, 0.7176, 0.8706);
const vec3 EDGE = vec3(0.2902, 0.5333, 0.7569);

float boundary1(float x) {
	float at = clamp(x / 8.0, 0.0, 63.999);
	int low = int(at);
	return mix(curve1[low], curve1[low + 1], at - float(low));
}

float boundary2(float x) {
	float at = clamp(x / 8.0, 0.0, 63.999);
	int low = int(at);
	return mix(curve2[low], curve2[low + 1], at - float(low));
}

float boundary3(float x) {
	float at = clamp(x / 8.0, 0.0, 63.999);
	int low = int(at);
	return mix(curve3[low], curve3[low + 1], at - float(low));
}

vec3 band(vec3 back, vec2 p, float near, float far, float focus) {
	if (p.y < near) {
		return back;
	}
	float s = (512.0 - p.y) / (512.0 - far);
	float t = clamp((s - focus) / (1.0 - focus), 0.0, 1.0);
	return mix(CENTER, EDGE, t);
}

void fragment() {
	vec2 p = vec2(UV.x * 512.0, UV.y * 384.0 + 63.2);
	float t = clamp(p.y / 256.0, 0.0, 1.0);
	vec3 color = mix(vec3(0.0, 0.29, 0.57), mix(vec3(0.6078, 0.7569, 0.9686), vec3(0.2784, 0.5294, 0.7529), t), mix(0.8, 1.0, t));
	float y1 = boundary1(p.x);
	float x1 = 255.0 + (p.x - 255.0) * (512.0 - y1) / max(512.0 - p.y, 1.0);
	color = band(color, p, y1, boundary1(x1), 0.4968);
	float y2 = boundary2(p.x);
	float x2 = 255.0 + (p.x - 255.0) * (512.0 - y2) / max(512.0 - p.y, 1.0);
	color = band(color, p, y2, boundary2(x2), 0.5865);
	float y3 = boundary3(p.x);
	float x3 = 255.0 + (p.x - 255.0) * (512.0 - y3) / max(512.0 - p.y, 1.0);
	color = band(color, p, y3, boundary3(x3), 0.1564);
	COLOR = vec4(color, 1.0);
}
