shader_type spatial;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(1, 0.4, 0.4, 1);

void fragment() {
	ALBEDO = base_color.rgb;
}
