shader_type canvas_item;

// 直接將不會裁切頂部的黃金參數設為代碼預設值，確保即便快取沒刷新也直接生效
uniform float pitch : hint_range(0.0, 1.0) = 0.35;
uniform float scale_x : hint_range(0.1, 2.0) = 1.0;
uniform float scale_y : hint_range(0.1, 2.0) = 1.0;
uniform float offset_y : hint_range(-1.0, 1.0) = 0.0;
uniform float antialiasing : hint_range(0.0, 0.1) = 0.005;

void fragment() {
	// 將 UV 移到中心點 [-0.5, 0.5]
	vec2 uv_centered = UV - vec2(0.5, 0.5);
	
	// 計算透視縮放 W 因子
	float w = 1.0 + uv_centered.y * pitch;
	
	if (w <= 0.0) {
		discard;
	}
	
	// 計算完美貼合邊界框的最佳縮放與偏移
	float w_top = 1.0 - 0.5 * pitch;
	float w_bottom = 1.0 + 0.5 * pitch;
	float optimal_scale_x = w_bottom;
	float optimal_scale_y = 1.0 / (0.5 / w_bottom + 0.5 / w_top);
	float optimal_offset_y = (0.5 / w_top) * optimal_scale_y - 0.5;
	
	// 套用逆透視投影轉換
	vec2 uv_warped = uv_centered / w;
	
	// 套用完美貼合修正 (自動縮放讓最寬的底部和上下邊緣都不會被裁切)
	uv_warped.x *= optimal_scale_x;
	uv_warped.y *= optimal_scale_y;
	uv_warped.y += optimal_offset_y;
	
	// 套用使用者微調
	uv_warped.x *= scale_x;
	uv_warped.y *= scale_y;
	uv_warped.y += offset_y;
	
	// 將座標移回 [0, 1] 範圍
	vec2 uv_out = uv_warped + vec2(0.5, 0.5);
	
	// 邊緣裁剪與平滑抗鋸齒
	float border_mask = 1.0;
	border_mask *= smoothstep(0.0, antialiasing, uv_out.x);
	border_mask *= smoothstep(1.0, 1.0 - antialiasing, uv_out.x);
	border_mask *= smoothstep(0.0, antialiasing, uv_out.y);
	border_mask *= smoothstep(1.0, 1.0 - antialiasing, uv_out.y);
	
	if (uv_out.x >= 0.0 && uv_out.x <= 1.0 && uv_out.y >= 0.0 && uv_out.y <= 1.0) {
		vec4 tex_color = texture(TEXTURE, uv_out);
		COLOR = vec4(tex_color.rgb, tex_color.a * border_mask);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0); // 裁剪掉邊界外
	}
}
