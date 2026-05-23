shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0, 0, 0, 1);
uniform float outline_width : hint_range(0, 10.0) = 2.0;

void vertex() {
	// 將頂點轉換到剪裁空間 (Clip Space)
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	// 將法線轉換到剪裁空間
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	
	// 根據螢幕解析度計算位移量，確保邊線在螢幕上是等寬的
	vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE.xy * clip_position.w * outline_width * 2.0;
	clip_position.xy += offset;
	
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
