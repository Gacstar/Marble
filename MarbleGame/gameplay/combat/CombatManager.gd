extends Node

signal combat_updated(player_hp, player_max_hp, active_enemy, item_cards, target_item_idx, next_damage_multiplier)
signal enemy_attacked(enemy_name, damage)
signal enemy_defeated(enemy_name)
signal hand_initialized(hand)
signal card_swapped(hand_idx, new_card)
signal selection_changed(idx)
signal player_healed(amount)
signal clear_slot_requested(slot_idx)
signal enemy_selection_changed(idx)

var player_max_hp = 100
var player_hp = 100

var active_enemy: Dictionary = {}
var item_cards: Array[ItemCardResource] = []
var target_item_idx: int = 0
var next_damage_multiplier: int = 1

var hand_cards: Array[CardResource] = []
var deck_cards: Array[CardResource] = []
@export var hand_size: int = 3
var selected_hand_idx: int = 0
var slot_counts: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]

func _ready():
	_initialize_all_cards()
	reset_combat()

func _initialize_all_cards():
	var all_pool: Array[CardResource] = CardDataLoader.load_all()
	all_pool.shuffle()
	
	hand_cards = all_pool.slice(0, hand_size)
	deck_cards = all_pool.slice(hand_size)
	
	hand_initialized.emit(hand_cards)

func reset_combat():
	player_hp = player_max_hp
	
	# 讀表載入 ID 為 1 的小屁孩敵人與其道具卡
	var enemy_data := EnemyDataLoader.load_enemy(1)
	if not enemy_data.is_empty():
		active_enemy = {
			"name": enemy_data["display_name"],
			"icon": enemy_data["icon"],
			"hp": enemy_data["max_hp"],
			"max_hp": enemy_data["max_hp"]
		}
		item_cards = enemy_data["item_cards"]
	else:
		# 備用降級防呆（萬一 CSV 損毀或載入失敗）
		active_enemy = {
			"name": "Brat (小屁孩)",
			"icon": load("res://assets/textures/Enemy/Enemy_Brat.png"),
			"hp": 300,
			"max_hp": 300
		}
		item_cards = []
	
	target_item_idx = 0
	next_damage_multiplier = 1
	emit_combat_signal()

func select_card(idx: int):
	if idx >= 0 and idx < hand_cards.size():
		selected_hand_idx = idx
		selection_changed.emit(idx)

func select_enemy(idx: int):
	if idx >= 0 and idx < item_cards.size():
		target_item_idx = idx
		enemy_selection_changed.emit(idx)
		emit_combat_signal()

func trigger_skill_from_slot(slot_index: int) -> Dictionary:
	var card = hand_cards[selected_hand_idx]
	
	var receipt = {
		"card": card,
		"old_player_hp": player_hp,
		"old_enemy_hp": active_enemy.hp,
		"damage_dealt": 0,
		"heal_amount": 0,
		"enemy_attacks": [],
		"new_player_hp": player_hp,
		"new_enemy_hp": active_enemy.hp
	}
	
	var value = card.get_skill_value(slot_index)
	
	slot_counts[slot_index] += 1
	var is_ultimate = (slot_counts[slot_index] == 3)
	
	if is_ultimate:
		value *= 2
		clear_slot_requested.emit(slot_index)
		slot_counts[slot_index] = 0
	
	# 動態執行技能效果
	var effect := card.get_skill_effect(slot_index)
	if effect != null:
		effect.apply_effect(self, value)
	else:
		push_error("CombatManager: Card [%s] slot %d has no skill effect" % [card.animal_name, slot_index])
	
	# 根據狀態變化自動填寫收據
	receipt.damage_dealt = receipt.old_enemy_hp - active_enemy.hp
	receipt.heal_amount = player_hp - receipt.old_player_hp
	receipt.new_enemy_hp = active_enemy.hp

	
	_swap_active_card()
	
	# 跑敵人回合 Tick，並收集反擊資訊
	var attacks = enemy_turn_tick()
	receipt.enemy_attacks = attacks
	receipt.new_player_hp = player_hp
	
	emit_combat_signal()
	return receipt

func _swap_active_card():
	var used_card = hand_cards[selected_hand_idx]
	var new_card = deck_cards.pop_front()
	deck_cards.push_back(used_card)
	hand_cards[selected_hand_idx] = new_card
	card_swapped.emit(selected_hand_idx, new_card)

func enemy_turn_tick() -> Array:
	var attacks = []
	if active_enemy.hp <= 0:
		return attacks
		
	for card in item_cards:
		if card.lock_turns > 0:
			card.lock_turns -= 1
			print("LOG: [LOCK_TICK] ", card.item_name, " remaining frozen turns: ", card.lock_turns)
			continue
			
		card.cd -= 1
		if card.cd <= 0:
			var damage = card.skill_value
			player_hp -= damage
			if player_hp < 0: player_hp = 0
			card.cd = card.cd_default
			enemy_attacked.emit(card.item_name, damage)
			attacks.append({
				"item_name": card.item_name,
				"damage": damage
			})
	return attacks

func emit_combat_signal():
	combat_updated.emit(player_hp, player_max_hp, active_enemy, item_cards, target_item_idx, next_damage_multiplier)
