shader_type canvas_item;

uniform float outline_width : hint_range(0, 5) = 2.0;
uniform vec4 outline_color : source_color = vec4(0, 0, 0, 1);
uniform float threshold : hint_range(0, 1) = 0.1;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = texture(TEXTURE, uv);
	
	// 採樣周圍像素
	vec2 ps = SCREEN_PIXEL_SIZE * outline_width;
	float a = texture(TEXTURE, uv + vec2(0, -ps.y)).a;
	float b = texture(TEXTURE, uv + vec2(0, ps.y)).a;
	float l = texture(TEXTURE, uv + vec2(-ps.x, 0)).a;
	float r = texture(TEXTURE, uv + vec2(ps.x, 0)).a;
	
	// 偵測 Alpha 通道的邊緣
	float edge = 4.0 * col.a - a - b - l - r;
	
	// 如果是邊緣，則混入黑邊
	if (col.a > 0.0) {
		if (abs(edge) > threshold) {
			COLOR = outline_color;
		} else {
			COLOR = col;
		}
	} else {
		// 背景保持透明或原本顏色
		COLOR = col;
	}
}
