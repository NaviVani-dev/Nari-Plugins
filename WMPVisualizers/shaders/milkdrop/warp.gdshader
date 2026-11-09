shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform sampler2D mesh : filter_linear;
uniform float decay = 0.98;
uniform bool wrap = true;
uniform bool darken_center = false;
uniform int frame = 0;
uniform vec2 mesh_size = vec2(25.0, 19.0);
uniform vec2 resolution = vec2(640.0, 360.0);

void fragment() {
	vec2 source = texture(mesh, SCREEN_UV * (mesh_size - 1.0) / mesh_size + 0.5 / mesh_size).rg;
	if (wrap) {
		source = fract(source);
	}
	vec3 color = texture(screen, clamp(source, vec2(0.0), vec2(1.0))).rgb * floor(decay * 255.0) / 255.0;
	if (darken_center) {
		vec2 delta = (SCREEN_UV - 0.5) * vec2(resolution.x / resolution.y, 1.0);
		color *= mix(0.93, 1.0, smoothstep(0.0, 0.08, length(delta)));
	}
	COLOR = frame < 2 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(color, 1.0);
}
