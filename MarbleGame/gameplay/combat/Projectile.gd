extends TextureRect

func setup(start_pos: Vector2, target_pos: Vector2, texture_resource: Texture2D = null) -> Tween:
	# 設定預設大小與中心點
	custom_minimum_size = Vector2(48, 48)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	
	# 設定圖片
	if texture_resource:
		texture = texture_resource
	else:
		# 預設使用卡通彈珠貼圖
		texture = load("res://assets/textures/cartoon_marble.png")
	
	# 初始位置居中於起點
	global_position = start_pos - pivot_offset
	
	# 建立平行動畫
	var tween = create_tween().set_parallel(true)
	
	# 1. 飛行至終點
	var flight_duration = 0.5 # 飛行半秒鐘
	tween.tween_property(self, "global_position", target_pos - pivot_offset, flight_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. 飛行時微幅旋轉，增強動感
	var target_rot = rotation + (PI * 4 if randf() > 0.5 else -PI * 4) # 旋轉兩圈
	tween.tween_property(self, "rotation", target_rot, flight_duration).set_trans(Tween.TRANS_LINEAR)
	
	# 3. 飛行時淡入 (從稍微透明到完全不透明)
	modulate.a = 0.5
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	# 4. 在到達前稍微放大又縮小，營造拋物線立體感
	var scale_tween = create_tween()
	scale = Vector2(0.8, 0.8)
	scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), flight_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), flight_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	return tween
