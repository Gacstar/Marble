extends Label

func setup(amount: int, is_heal: bool = false, is_player: bool = false):
	if is_heal:
		text = "+" + str(amount)
		modulate = Color(0.2, 1.0, 0.2, 1.0) # 亮綠色
	else:
		text = "-" + str(amount)
		if is_player:
			modulate = Color(1.0, 0.4, 0.4, 1.0) # 亮橙紅 (老奶奶扣血)
		else:
			modulate = Color(1.0, 0.1, 0.1, 1.0) # 亮紅色 (敵人扣血)
	
	# 設定樣式覆寫
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	add_theme_font_size_override("font_size", 36)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 設定 pivot 至中心以供縮放動畫使用
	# 由於 Label 的大小可能在 _ready() 後才確定，我們先手動給予一個估計尺寸
	custom_minimum_size = Vector2(100, 40)
	pivot_offset = custom_minimum_size / 2.0
	
	# 初始化大小與縮放
	scale = Vector2(0.3, 0.3)
	
	# 建立平行動畫
	var tween = create_tween().set_parallel(true)
	
	# 1. 隨機微幅左右飄移並向上浮動
	var rand_x = randf_range(-40, 40)
	var rand_y = randf_range(-140, -100)
	var target_pos = position + Vector2(rand_x, rand_y)
	tween.tween_property(self, "position", target_pos, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. 淡出效果 (在前半秒維持不透明，後半秒淡出)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)
	
	# 3. 彈縮動畫 (獨立時序)
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
	# 播放完畢後自動銷毀
	scale_tween.finished.connect(func():
		# 確保淡出 tween 也完成了，或者直接交給主要 tween 銷毀
		pass
	)
	
	# 主要 tween 播放完後 queue_free
	tween.chain().tween_callback(queue_free)
