@tool
extends TextureRect

var is_dragging = false

func _gui_input(event: InputEvent):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventMouse:
		# 1. 取得 TextureRect 的實際大小
		var container_size = size
		if container_size.x <= 0.0 or container_size.y <= 0.0:
			return
			
		# 2. 將相對滑鼠位置轉為 0~1 的相對座標 (screen UV)
		var screen_uv = event.position / container_size
		
		# 3. 將 UV 移到中心點 [-0.5, 0.5]
		var uv_centered = screen_uv - Vector2(0.5, 0.5)
		
		# 4. 從材質中動態獲取 4 角座標
		var top_left = Vector2(0.0, 0.0)
		var top_right = Vector2(1.0, 0.0)
		var bottom_left = Vector2(0.0, 1.0)
		var bottom_right = Vector2(1.0, 1.0)
		
		if material and material is ShaderMaterial:
			var tl = material.get_shader_parameter("top_left")
			var tr = material.get_shader_parameter("top_right")
			var bl = material.get_shader_parameter("bottom_left")
			var br = material.get_shader_parameter("bottom_right")
			if tl != null: top_left = tl
			if tr != null: top_right = tr
			if bl != null: bottom_left = bl
			if br != null: bottom_right = br
			
		# 5. 計算前向投影矩陣 H 的係數
		var x0 = top_left.x;     var y0 = top_left.y
		var x1 = top_right.x;    var y1 = top_right.y
		var x2 = bottom_left.x;  var y2 = bottom_left.y
		var x3 = bottom_right.x; var y3 = bottom_right.y
		
		var dx1 = x1 - x3
		var dx2 = x2 - x3
		var sx = x0 - x1 - x2 + x3
		
		var dy1 = y1 - y3
		var dy2 = y2 - y3
		var sy = y0 - y1 - y2 + y3
		
		var det = dx1 * dy2 - dy1 * dx2
		
		var H = Basis()
		if abs(sx) < 0.0001 and abs(sy) < 0.0001:
			# 仿射變換
			H = Basis(
				Vector3(x1 - x0, y1 - y0, 0.0),
				Vector3(x2 - x0, y2 - y0, 0.0),
				Vector3(x0, y0, 1.0)
			)
		else:
			if abs(det) < 0.0001:
				accept_event()
				return
			var g = (sx * dy2 - sy * dx2) / det
			var h = (dx1 * sy - dy1 * sx) / det
			
			H = Basis(
				Vector3(x1 - x0 + g * x1, y1 - y0 + g * y1, g),
				Vector3(x2 - x0 + h * x2, y2 - y0 + h * y2, h),
				Vector3(x0, y0, 1.0)
			)
			
		if abs(H.determinant()) < 0.0001:
			accept_event()
			return
			
		var H_inv = H.inverse()
		var tex_coords = H_inv * Vector3(screen_uv.x, screen_uv.y, 1.0)
		
		if tex_coords.z <= 0.0:
			accept_event()
			return # 超出背面範圍，直接攔截捨棄
			
		# 10. 移回 [0, 1] 的彈珠台內部 UV 座標
		var inner_uv = Vector2(tex_coords.x / tex_coords.z, tex_coords.y / tex_coords.z)
		
		# 11. 判斷滑鼠是否在彈珠台內部有效區域
		var is_inside = inner_uv.x >= 0.0 and inner_uv.x <= 1.0 and inner_uv.y >= 0.0 and inner_uv.y <= 1.0
		
		# 12. 處理拖曳狀態追蹤
		if event is InputEventMouseButton:
			if event.pressed:
				if is_inside:
					is_dragging = true
			else:
				# 無論當前在哪裡放開，只要是放開滑鼠事件，就必須重置拖曳狀態
				is_dragging = false
		
		# 13. 如果在內部、或者正在拖曳中、或者是放開滑鼠的瞬間，都必須將事件安全地傳遞給 SubViewport
		if is_inside or is_dragging or (event is InputEventMouseButton and not event.pressed):
			# 限制 UV 在 0~1 之間，防止超出邊界造成內部物理拖曳卡死或錯誤
			var clamped_uv = Vector2(
				clamp(inner_uv.x, 0.0, 1.0),
				clamp(inner_uv.y, 0.0, 1.0)
			)
			
			var sub_viewport = get_node_or_null("../TableViewport")
			if sub_viewport:
				# 將 0~1 UV 轉換為 SubViewport 內部實際的像素坐標 (457x854)
				var inner_pos = Vector2(
					clamped_uv.x * sub_viewport.size.x,
					clamped_uv.y * sub_viewport.size.y
				)
				
				var cloned_event = event.duplicate()
				cloned_event.position = inner_pos
				cloned_event.global_position = inner_pos
				
				sub_viewport.push_input(cloned_event)
				
			accept_event()
		else:
			# 點在透視形變產生的外部邊界（黑邊），且不是拖曳或放開事件，直接攔截並捨棄
			accept_event()
