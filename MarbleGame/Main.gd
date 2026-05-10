extends Node2D

@onready var marble_table = $MarblePerspectiveView/SubViewport/WorldRoot/MarbleTable3D
@onready var combat_ui = $CombatUI
@onready var combat_manager = $CombatManager

func _ready():
	print("LOG: Main Scene Ready.")
	
	# 連接彈珠台的槽位觸發信號
	marble_table.slot_hit.connect(_on_slot_hit)
	
	# 連接戰鬥管理器的信號
	combat_manager.combat_updated.connect(_on_combat_updated)
	combat_manager.monster_attacked.connect(_on_monster_attacked)
	combat_manager.hand_initialized.connect(_on_hand_initialized)
	combat_manager.card_swapped.connect(_on_card_swapped)
	combat_manager.selection_changed.connect(_on_card_selection_changed)
	combat_manager.player_healed.connect(_on_player_healed)
	combat_manager.clear_slot_requested.connect(_on_clear_slot_requested)
	
	# 連接 UI 的點擊信號
	combat_ui.card_selected_bubbled.connect(_on_card_ui_selected)
	combat_ui.monster_selected_bubbled.connect(_on_monster_ui_selected)
	
	# 初始化戰鬥
	combat_manager.reset_combat()
	# 手動觸發第一次狀態同步
	_on_hand_initialized(combat_manager.hand_cards)
	_on_card_selection_changed(combat_manager.selected_hand_idx)

func _on_slot_hit(slot_idx):
	combat_manager.trigger_skill_from_slot(slot_idx)

func _on_combat_updated(p_hp, p_max, m_data, t_idx, mult):
	combat_ui.update_ui(p_hp, p_max, m_data, t_idx, mult)

func _on_monster_attacked(m_name, dmg):
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

func _on_monster_ui_selected(idx):
	combat_manager.select_monster(idx)
