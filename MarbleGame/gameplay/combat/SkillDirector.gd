extends Node

@onready var combat_ui = get_parent()

var projectile_scene = preload("res://gameplay/combat/Projectile.tscn")
var damage_popup_scene = preload("res://gameplay/combat/DamagePopup.tscn")

# 播放手牌卡片縮放兩下的發動動畫
func play_card_zoom_animation(card_idx: int) -> void:
	if card_idx < 0 or card_idx >= combat_ui.food_card_widgets.size():
		return
		
	var card_widget = combat_ui.food_card_widgets[card_idx]
	await play_widget_zoom_animation(card_widget)

# 通用元件縮放動畫 (縮放兩下)
func play_widget_zoom_animation(widget: Control) -> void:
	if not widget:
		return
		
	# 將縮放中心點設在元件正中心
	widget.pivot_offset = widget.size / 2.0
	
	var zoom_tween = create_tween()
	var duration_up = 0.14
	var duration_down = 0.11
	var target_scale = Vector2(1.22, 1.22)
	var normal_scale = Vector2(1.0, 1.0)
	
	# 第一次縮放
	zoom_tween.tween_property(widget, "scale", target_scale, duration_up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(widget, "scale", normal_scale, duration_down).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# 第二次縮放
	zoom_tween.tween_property(widget, "scale", target_scale, duration_up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(widget, "scale", normal_scale, duration_down).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await zoom_tween.finished

# 播放老奶奶攻擊敵人的表演
func play_player_attack(card: CardResource, damage: int, from_enemy_hp: int, to_enemy_hp: int, max_enemy_hp: int) -> void:
	var grandma_sprite = combat_ui.get_node("PlayerSide/GrandmaSprite")
	var enemy_sprite = combat_ui.enemy_sprite
	
	if not grandma_sprite or not enemy_sprite:
		return
	
	# 1. 獲取起點與終點位置 (使用大頭像中心點)
	var start_pos = grandma_sprite.global_position + grandma_sprite.size / 2.0
	var target_pos = enemy_sprite.global_position + enemy_sprite.size / 2.0
	
	# 2. 生成投擲球 (Projectile)
	var proj = projectile_scene.instantiate()
	combat_ui.add_child(proj)
	
	# 使用卡牌的 icon 作為投擲物外觀
	var proj_tween = proj.setup(start_pos, target_pos, card.animal_icon)
	
	# 3. 等待球飛到敵人身上
	await proj_tween.finished
	proj.queue_free()
	
	# 4. 擊中效果：若為中毒發動 (無直接傷害) 則閃紫，否則抖動閃紅
	if damage == 0:
		var original_color = enemy_sprite.self_modulate
		var poison_color = Color(0.73, 0.22, 1.0, 1.0)
		var flash_tween = create_tween()
		enemy_sprite.self_modulate = poison_color
		flash_tween.tween_property(enemy_sprite, "self_modulate", original_color, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		flash_and_shake(enemy_sprite, false)
		# 5. 彈出傷害飄字
		spawn_damage_popup(target_pos, damage, false, false)
	
	# 6. 平滑滑動扣血血條與文字更新
	await animate_hp_bar(combat_ui.enemy_hp_bar, combat_ui.enemy_hp_label, from_enemy_hp, to_enemy_hp, max_enemy_hp, "HP: ")

# 播放敵人反擊老奶奶的表演
func play_enemy_attack(item_name: String, item_icon: Texture2D, damage: int, from_player_hp: int, to_player_hp: int, max_player_hp: int) -> void:
	var grandma_sprite = combat_ui.get_node("PlayerSide/GrandmaSprite")
	var enemy_sprite = combat_ui.enemy_sprite
	
	if not grandma_sprite or not enemy_sprite:
		return
		
	# 尋找發動此技能的道具卡 Widget
	var active_widget: Control = null
	for widget in combat_ui.item_card_widgets:
		if widget.item_resource and widget.item_resource.item_name == item_name:
			active_widget = widget
			break
			
	# 如果找到道具卡，先播放縮放兩下的啟動動畫
	if active_widget:
		await play_widget_zoom_animation(active_widget)
	
	# 1. 獲取起點與終點位置 (固定從敵人身上丟出)
	var start_pos = enemy_sprite.global_position + enemy_sprite.size / 2.0
	var target_pos = grandma_sprite.global_position + grandma_sprite.size / 2.0
	
	# 2. 生成敵方投擲球
	var proj = projectile_scene.instantiate()
	combat_ui.add_child(proj)
	
	# 使用道具圖標發射
	var proj_tween = proj.setup(start_pos, target_pos, item_icon)
	
	# 3. 等待飛行結束
	await proj_tween.finished
	proj.queue_free()
	
	# 4. 擊中效果：若為中毒發動 (無直接傷害) 則閃紫，否則抖動閃紅
	if damage == 0:
		var original_color = grandma_sprite.self_modulate
		var poison_color = Color(0.73, 0.22, 1.0, 1.0)
		var flash_tween = create_tween()
		grandma_sprite.self_modulate = poison_color
		flash_tween.tween_property(grandma_sprite, "self_modulate", original_color, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		flash_and_shake(grandma_sprite, true)
		# 5. 彈出傷害飄字
		spawn_damage_popup(target_pos, damage, false, true)
	
	# 6. 平滑滑動老奶奶血條
	await animate_hp_bar(combat_ui.player_hp_bar, combat_ui.player_hp_label, from_player_hp, to_player_hp, max_player_hp, "HP: ")

# 播放治療表演
func play_heal_effect(amount: int, from_player_hp: int, to_player_hp: int, max_player_hp: int) -> void:
	var grandma_sprite = combat_ui.get_node("PlayerSide/GrandmaSprite")
	if not grandma_sprite:
		return
		
	var target_pos = grandma_sprite.global_position + grandma_sprite.size / 2.0
	
	# 1. 綠色閃爍提示
	var original_color = grandma_sprite.self_modulate
	var heal_color = Color(0.4, 1.0, 0.4, 1.0)
	var flash_tween = create_tween()
	grandma_sprite.self_modulate = heal_color
	flash_tween.tween_property(grandma_sprite, "self_modulate", original_color, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. 彈出治療飄字 (+N)
	spawn_damage_popup(target_pos - Vector2(0, 50), amount, true, true)
	
	# 3. 平滑滑動補血血條
	await animate_hp_bar(combat_ui.player_hp_bar, combat_ui.player_hp_label, from_player_hp, to_player_hp, max_player_hp, "HP: ")

# 輔助：受擊抖動與閃紅
func flash_and_shake(node: Control, is_player: bool) -> void:
	# 1. 閃紅
	var original_color = node.self_modulate
	var flash_color = Color(1.0, 0.4, 0.4, 1.0) if is_player else Color(1.0, 0.1, 0.1, 1.0)
	
	var flash_tween = create_tween()
	node.self_modulate = flash_color
	flash_tween.tween_property(node, "self_modulate", original_color, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. 抖動 (快速往復位移)
	var original_pos = node.position
	var shake_tween = create_tween()
	var shake_intensity = 18.0
	var shake_count = 6
	var shake_dur = 0.05
	
	for i in range(shake_count):
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if i == shake_count - 1:
			offset = Vector2.ZERO # 最後復位
		shake_tween.tween_property(node, "position", original_pos + offset, shake_dur)

# 播放中毒扣血的表演
func play_poison_tick_effect(is_player: bool, damage: int, from_hp: int, to_hp: int, max_hp: int) -> void:
	var target_sprite = combat_ui.get_node("PlayerSide/GrandmaSprite") if is_player else combat_ui.enemy_sprite
	var hp_bar = combat_ui.player_hp_bar if is_player else combat_ui.enemy_hp_bar
	var hp_label = combat_ui.player_hp_label if is_player else combat_ui.enemy_hp_label
	
	if not target_sprite or not hp_bar or not hp_label:
		return
		
	var target_pos = target_sprite.global_position + target_sprite.size / 2.0
	
	# 中毒受傷的紫色閃爍提示
	var original_color = target_sprite.self_modulate
	var poison_color = Color(0.73, 0.22, 1.0, 1.0) # 紫色
	
	var flash_tween = create_tween()
	target_sprite.self_modulate = poison_color
	flash_tween.tween_property(target_sprite, "self_modulate", original_color, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 彈出紫色傷害飄字
	spawn_damage_popup(target_pos, damage, false, is_player, true)
	
	# 平滑扣減血條
	await animate_hp_bar(hp_bar, hp_label, from_hp, to_hp, max_hp, "HP: ")

# 輔助：生成傷害數字飄字
func spawn_damage_popup(pos: Vector2, amount: int, is_heal: bool, is_player: bool, is_poison: bool = false) -> void:
	var popup = damage_popup_scene.instantiate()
	combat_ui.add_child(popup)
	popup.global_position = pos - Vector2(50, 20) # 微調置中
	popup.setup(amount, is_heal, is_player, is_poison)

# 輔助：平滑更新 ProgressBar 與 HPLabel 的數值
func animate_hp_bar(hp_bar: ProgressBar, label: Label, from_val: float, to_val: float, max_val: float, label_prefix: String) -> void:
	var hp_tween = create_tween()
	
	# 平滑遞減或增加血條 value
	hp_tween.tween_property(hp_bar, "value", to_val, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 同步平滑遞增/減 Label 上的數字
	hp_tween.parallel().tween_method(func(val: float):
		label.text = label_prefix + "%d / %d" % [int(val), int(max_val)]
	, from_val, to_val, 0.45)
	
	await hp_tween.finished
