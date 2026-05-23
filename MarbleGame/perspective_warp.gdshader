shader_type canvas_item;

uniform vec2 top_left = vec2(0.0, 0.0);
uniform vec2 top_right = vec2(1.0, 0.0);
uniform vec2 bottom_left = vec2(0.0, 1.0);
uniform vec2 bottom_right = vec2(1.0, 1.0);
uniform float antialiasing : hint_range(0.0, 0.1) = 0.005;

void fragment() {
	float x0 = top_left.x;     float y0 = top_left.y;
	float x1 = top_right.x;    float y1 = top_right.y;
	float x2 = bottom_left.x;  float y2 = bottom_left.y;
	float x3 = bottom_right.x; float y3 = bottom_right.y;
	
	float dx1 = x1 - x3;
	float dx2 = x2 - x3;
	float sx = x0 - x1 - x2 + x3;
	
	float dy1 = y1 - y3;
	float dy2 = y2 - y3;
	float sy = y0 - y1 - y2 + y3;
	
	float det = dx1 * dy2 - dy1 * dx2;
	
	mat3 H;
	if (abs(sx) < 0.0001 && abs(sy) < 0.0001) {
		// 仿射變換
		H = mat3(
			vec3(x1 - x0, y1 - y0, 0.0),
			vec3(x2 - x0, y2 - y0, 0.0),
			vec3(x0, y0, 1.0)
		);
	} else {
		if (abs(det) < 0.0001) {
			discard;
		}
		float g = (sx * dy2 - sy * dx2) / det;
		float h = (dx1 * sy - dy1 * sx) / det;
		
		H = mat3(
			vec3(x1 - x0 + g * x1, y1 - y0 + g * y1, g),
			vec3(x2 - x0 + h * x2, y2 - y0 + h * y2, h),
			vec3(x0, y0, 1.0)
		);
	}
	
	mat3 H_inv = inverse(H);
	vec3 tex_coords = H_inv * vec3(UV, 1.0);
	
	if (tex_coords.z <= 0.0) {
		discard;
	}
	
	vec2 uv_out = tex_coords.xy / tex_coords.z;
	
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
