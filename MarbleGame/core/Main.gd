extends Node2D

@onready var marble_table = $MarbleShaderPerspectiveView/TableViewport/MarbleTable
@onready var combat_ui = $CombatUI
@onready var combat_manager = $CombatManager

func _ready():
	print("LOG: Main Scene Ready.")
	
	# 連接彈珠台的槽位觸發與發射狀態信號
	marble_table.slot_hit.connect(_on_slot_hit)
	marble_table.launch_status_changed.connect(_on_launch_status_changed)
	
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
	combat_ui.surrender_clicked.connect(_on_surrender_clicked)
	
	# 初始化戰鬥
	combat_manager.reset_combat()
	# 手動觸發第一次狀態同步
	_on_hand_initialized(combat_manager.hand_cards)
	_on_card_selection_changed(combat_manager.selected_hand_idx)

var is_playing_animation: bool = false
var combat_run_id: int = 0

func _on_slot_hit(slot_idx):
	if is_playing_animation:
		return # 防抖防重複進洞同時觸發表演衝突
		
	# 安全防護：若有任一方已死亡，停止任何新的進攻與表演
	if combat_manager.player_hp <= 0 or combat_manager.active_enemy.hp <= 0:
		return
		
	var my_run_id = combat_run_id
	is_playing_animation = true
	
	# 1. 在執行邏輯與換牌之前，先播放當前選中卡牌縮放兩下的啟動動畫
	await combat_ui.skill_director.play_card_zoom_animation(combat_manager.selected_hand_idx)
	if my_run_id != combat_run_id:
		return
	
	# 2. 執行計算，取得戰鬥收據，並暫時不更新 UI 的 HP 條 (因為 is_playing_animation = true)
	var receipt = combat_manager.trigger_skill_from_slot(slot_idx)
	
	# A. 播放玩家中毒受傷演出 (如果本回合有受到中毒傷害)
	if receipt.player_poison_damage > 0:
		await combat_ui.skill_director.play_poison_tick_effect(
			true,
			receipt.player_poison_damage,
			receipt.old_player_hp,
			receipt.new_player_hp_after_poison,
			combat_manager.player_max_hp
		)
		if my_run_id != combat_run_id:
			return
		# 檢查玩家是否因為中毒死亡
		if receipt.new_player_hp_after_poison <= 0:
			_show_battle_result(false)
			return
	
	# B. 播放敵方中毒受傷演出 (如果本回合有受到中毒傷害)
	if receipt.enemy_poison_damage > 0:
		await combat_ui.skill_director.play_poison_tick_effect(
			false,
			receipt.enemy_poison_damage,
			receipt.old_enemy_hp,
			receipt.new_enemy_hp_after_poison,
			combat_manager.active_enemy.max_hp
		)
		if my_run_id != combat_run_id:
			return
		# 檢查敵人是否因為中毒死亡
		if receipt.new_enemy_hp_after_poison <= 0:
			_show_battle_result(true)
			return
	
	# C. 播放我方卡牌行動表演 (攻擊或治療)
	if receipt.damage_dealt > 0:
		# 由於敵人中毒已在此前演出並扣血完畢，因此玩家卡牌攻擊的起點血量是 new_enemy_hp_after_poison
		await combat_ui.skill_director.play_player_attack(
			receipt.card, 
			receipt.damage_dealt, 
			receipt.new_enemy_hp_after_poison, 
			receipt.new_enemy_hp_after_card, 
			combat_manager.active_enemy.max_hp
		)
		if my_run_id != combat_run_id:
			return
		# 檢查敵人是否因為我方卡牌攻擊死亡
		if receipt.new_enemy_hp_after_card <= 0:
			_show_battle_result(true)
			return
			
	elif receipt.heal_amount > 0:
		await combat_ui.skill_director.play_heal_effect(
			receipt.heal_amount, 
			receipt.new_player_hp_after_poison, 
			receipt.new_player_hp_after_card, 
			combat_manager.player_max_hp
		)
		if my_run_id != combat_run_id:
			return
		
	# D. 播放敵方道具卡反擊表演
	var current_player_hp = receipt.new_player_hp_after_card
	for attack in receipt.enemy_attacks:
		var next_player_hp = current_player_hp - attack.damage
		if next_player_hp < 0:
			next_player_hp = 0
			
		await combat_ui.skill_director.play_enemy_attack(
			attack.item_name,
			attack.item_icon,
			attack.damage,
			current_player_hp,
			next_player_hp,
			combat_manager.player_max_hp
		)
		if my_run_id != combat_run_id:
			return
		current_player_hp = next_player_hp
		# 檢查玩家是否因為敵人反擊死亡
		if current_player_hp <= 0:
			_show_battle_result(false)
			return
		
	# 4. 表演完畢，將 is_playing_animation 設為 false，並呼叫一次 emit_combat_signal 做最終的 HP 血條完全對齊
	is_playing_animation = false
	combat_manager.is_selection_locked = false
	combat_manager.emit_combat_signal()

func _show_battle_result(is_victory: bool):
	var dialog = AcceptDialog.new()
	dialog.title = "戰鬥結束"
	dialog.dialog_text = "恭喜過關" if is_victory else "你戰敗了"
	dialog.min_size = Vector2(250, 120)
	
	dialog.confirmed.connect(func():
		combat_run_id += 1 # 中斷仍在 await 的協程
		is_playing_animation = false # 開放鎖定
		combat_manager.reset_combat()
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		combat_run_id += 1 # 中斷仍在 await 的協程
		is_playing_animation = false
		combat_manager.reset_combat()
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _on_surrender_clicked():
	# 只要戰鬥尚未分出勝負（雙方血量都大於 0），隨時可以認輸
	if combat_manager.player_hp > 0 and combat_manager.active_enemy.hp > 0:
		_show_battle_result(false)

func _on_launch_status_changed(is_launched: bool):
	combat_manager.is_selection_locked = is_launched

func _on_combat_updated(p_hp, p_max, active_enemy, item_cards, t_idx, mult, p_poison_turns, e_poison_turns):
	combat_ui.update_ui(p_hp, p_max, active_enemy, item_cards, t_idx, mult, p_poison_turns, e_poison_turns, is_playing_animation)

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
