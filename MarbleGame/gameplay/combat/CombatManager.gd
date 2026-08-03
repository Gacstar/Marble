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
var player_poison_turns: int = 0
var player_poison_value: int = 0

var active_enemy: Dictionary = {}
var item_cards: Array[ItemCardResource] = []
var target_item_idx: int = 0
var next_damage_multiplier: int = 1
var enemy_poison_turns: int = 0
var enemy_poison_value: int = 0

var hand_cards: Array[CardResource] = []
var deck_cards: Array[CardResource] = []
@export var hand_size: int = 3
var selected_hand_idx: int = 0
var slot_counts: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
var is_selection_locked: bool = false

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
	player_poison_turns = 0
	player_poison_value = 0
	
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
	enemy_poison_turns = 0
	enemy_poison_value = 0
	is_selection_locked = false
	emit_combat_signal()

func select_card(idx: int):
	if is_selection_locked:
		print("LOG: [SELECTION LOCKED] Cannot swap cards during ball roll")
		return
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
		
		"player_poison_damage": 0,
		"new_player_hp_after_poison": player_hp,
		
		"enemy_poison_damage": 0,
		"new_enemy_hp_after_poison": active_enemy.hp,
		
		"damage_dealt": 0,
		"heal_amount": 0,
		"new_player_hp_after_card": player_hp,
		"new_enemy_hp_after_card": active_enemy.hp,
		
		"enemy_attacks": [],
		"new_player_hp": player_hp,
		"new_enemy_hp": active_enemy.hp
	}
	
	# 1. 玩家回合開始：結算玩家中毒 (上一輪留下的中毒效果)
	if player_poison_turns > 0:
		player_poison_turns -= 1
		var dmg = player_poison_value
		player_hp -= dmg
		if player_hp < 0: player_hp = 0
		receipt.player_poison_damage = dmg
		receipt.new_player_hp_after_poison = player_hp
		if player_poison_turns == 0:
			player_poison_value = 0
	else:
		receipt.new_player_hp_after_poison = player_hp
		
	# 若玩家中毒死亡，立刻中斷後續邏輯
	if player_hp <= 0:
		receipt.new_player_hp = player_hp
		receipt.new_enemy_hp = active_enemy.hp
		emit_combat_signal()
		return receipt
		
	# 2. 結算奧客中毒 (上一輪留下的中毒效果)
	if active_enemy.hp > 0 and enemy_poison_turns > 0:
		enemy_poison_turns -= 1
		var dmg = enemy_poison_value
		active_enemy.hp -= dmg
		if active_enemy.hp <= 0:
			active_enemy.hp = 0
			enemy_defeated.emit(active_enemy.name)
		receipt.enemy_poison_damage = dmg
		receipt.new_enemy_hp_after_poison = active_enemy.hp
		if enemy_poison_turns == 0:
			enemy_poison_value = 0
	else:
		receipt.new_enemy_hp_after_poison = active_enemy.hp
		
	# 若敵方中毒死亡，立刻中斷後續邏輯
	if active_enemy.hp <= 0:
		receipt.new_player_hp = player_hp
		receipt.new_enemy_hp = active_enemy.hp
		emit_combat_signal()
		return receipt
	
	# 3. 執行玩家目前的卡牌技能 (如果是中毒技能臭豆腐，會把 enemy_poison_turns 設為 3)
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
	
	# 記錄玩家卡牌效果執行後的血量變化 (傷害計算基準為奧客中毒扣血後的血量)
	receipt.damage_dealt = receipt.new_enemy_hp_after_poison - active_enemy.hp
	receipt.heal_amount = player_hp - receipt.new_player_hp_after_poison
	receipt.new_player_hp_after_card = player_hp
	receipt.new_enemy_hp_after_card = active_enemy.hp
	
	# 若敵方被卡牌技能擊敗，立刻中斷且不進行敵方攻擊
	if active_enemy.hp <= 0:
		_swap_active_card()
		receipt.new_player_hp = player_hp
		receipt.new_enemy_hp = active_enemy.hp
		emit_combat_signal()
		return receipt
	
	# 4. 換牌
	_swap_active_card()
	
	# 5. 奧客道具卡 CD 扣減與攻擊 Tick (如果丟出衛生紙，會將 player_poison_turns 設為 3)
	var attacks = enemy_turn_tick()
	receipt.enemy_attacks = attacks
	
	# 6. 最終生命值同步
	receipt.new_player_hp = player_hp
	receipt.new_enemy_hp = active_enemy.hp
	
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
			if card.skill_type == "poison":
				# 對玩家施加中毒狀態
				player_poison_turns = 3
				player_poison_value = damage
				enemy_attacked.emit(card.item_name, 0)
				attacks.append({
					"item_name": card.item_name,
					"item_icon": card.item_icon,
					"damage": 0,
					"skill_type": "poison"
				})
			else:
				# 預設為普通傷害
				player_hp -= damage
				if player_hp < 0: player_hp = 0
				enemy_attacked.emit(card.item_name, damage)
				attacks.append({
					"item_name": card.item_name,
					"item_icon": card.item_icon,
					"damage": damage,
					"skill_type": "damage"
				})
			card.cd = card.cd_default
	return attacks

func emit_combat_signal():
	combat_updated.emit(player_hp, player_max_hp, active_enemy, item_cards, target_item_idx, next_damage_multiplier)
