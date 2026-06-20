extends Node2D

@onready var marble_table = $MarbleShaderPerspectiveView/TableViewport/MarbleTable
@onready var combat_ui = $CombatUI
@onready var combat_manager = $CombatManager

func _ready():
	print("LOG: Main Scene Ready.")
	
	# 連接彈珠台的槽位觸發信號
	marble_table.slot_hit.connect(_on_slot_hit)
	
	# 連接戰鬥管理器的信號
	combat_manager.combat_updated.connect(_on_combat_updated)
	combat_manager.enemy_attacked.connect(_on_enemy_attacked)
	combat_manager.hand_initialized.connect(_on_hand_initialized)
	combat_manager.card_swapped.connect(_on_card_swapped)
	combat_manager.selection_changed.connect(_on_card_selection_changed)
	combat_manager.player_healed.connect(_on_player_healed)
	combat_manager.clear_slot_requested.connect(_on_clear_slot_requested)
	
	# 連接 UI 的點擊信號
	combat_ui.card_selected_bubbled.connect(_on_card_ui_selected)
	combat_ui.enemy_selected_bubbled.connect(_on_enemy_ui_selected)
	
	# 初始化戰鬥
	combat_manager.reset_combat()
	# 手動觸發第一次狀態同步
	_on_hand_initialized(combat_manager.hand_cards)
	_on_card_selection_changed(combat_manager.selected_hand_idx)

var is_playing_animation: bool = false

func _on_slot_hit(slot_idx):
	if is_playing_animation:
		return # 防抖防重複進洞同時觸發表演衝突
		
	is_playing_animation = true
	
	# 1. 在執行邏輯與換牌之前，先播放當前選中卡牌縮放兩下的啟動動畫
	await combat_ui.skill_director.play_card_zoom_animation(combat_manager.selected_hand_idx)
	
	# 2. 執行計算，取得戰鬥收據，並暫時不更新 UI 的 HP 條 (因為 is_playing_animation = true)
	var receipt = combat_manager.trigger_skill_from_slot(slot_idx)
	
	# 2. 播放我方行動表演 (攻擊或治療)
	if receipt.damage_dealt > 0:
		await combat_ui.skill_director.play_player_attack(
			receipt.card, 
			receipt.damage_dealt, 
			receipt.old_enemy_hp, 
			receipt.new_enemy_hp, 
			combat_manager.active_enemy.max_hp
		)
	elif receipt.heal_amount > 0:
		await combat_ui.skill_director.play_heal_effect(
			receipt.heal_amount, 
			receipt.old_player_hp, 
			receipt.new_player_hp, 
			combat_manager.player_max_hp
		)
		
	# 3. 播放敵方反擊表演
	var current_player_hp = receipt.old_player_hp
	if receipt.heal_amount > 0:
		current_player_hp = receipt.new_player_hp
		
	for attack in receipt.enemy_attacks:
		var next_player_hp = current_player_hp - attack.damage
		if next_player_hp < 0:
			next_player_hp = 0
			
		await combat_ui.skill_director.play_enemy_attack(
			attack.item_name,
			attack.damage,
			current_player_hp,
			next_player_hp,
			combat_manager.player_max_hp
		)
		current_player_hp = next_player_hp
		
	# 4. 表演完畢，將 is_playing_animation 設為 false，並呼叫一次 emit_combat_signal 做最終的 HP 血條完全對齊
	is_playing_animation = false
	combat_manager.emit_combat_signal()

func _on_combat_updated(p_hp, p_max, active_enemy, item_cards, t_idx, mult):
	combat_ui.update_ui(p_hp, p_max, active_enemy, item_cards, t_idx, mult, is_playing_animation)

func _on_enemy_attacked(m_name, dmg):
	combat_ui.show_damage_effect(m_name, dmg)

func _on_player_healed(amount):
	combat_ui.show_damage_effect("PlayerHeal", amount)

func _on_clear_slot_requested(slot_idx):
	marble_table.clear_slot_marbles(slot_idx)

func _on_hand_initialized(cards):
	combat_ui.initialize_cards(cards)

func _on_card_swapped(idx, new_card):
	combat_ui.update_card_at_index(idx, new_card)
	# 換牌後需要更新槽位指示燈，因為當前選中的卡牌換了
	var card = combat_manager.hand_cards[combat_manager.selected_hand_idx]
	marble_table.update_slot_indicators(card)

func _on_card_selection_changed(idx):
	combat_ui.update_selection(idx)
	var card = combat_manager.hand_cards[idx]
	marble_table.update_slot_indicators(card)

func _on_card_ui_selected(idx):
	combat_manager.select_card(idx)

func _on_enemy_ui_selected(idx):
	combat_manager.select_enemy(idx)
