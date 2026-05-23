shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0, 0.4, 0.4, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.5, 0.2, 0.2, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	ALBEDO = albedo.rgb;
}

void light() {
	float dot_nl = dot(NORMAL, LIGHT);
	float shadow = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, dot_nl);
	vec3 final_color = mix(shadow_color.rgb, LIGHT_COLOR, shadow);
	DIFFUSE_LIGHT += final_color * ATTENUATION * ALBEDO;
	
	// Add a small specular highlight
	float specular = pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 32.0);
	SPECULAR_LIGHT += vec3(specular) * shadow * LIGHT_COLOR;
}
