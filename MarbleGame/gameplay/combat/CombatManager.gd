extends Node

signal combat_updated(player_hp, player_max_hp, enemies_data, target_idx)
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

var enemies: Array[Dictionary] = []
var target_enemy_idx: int = 0
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
	var all_pool: Array[CardResource] = []
	
	var lion = _create_card("Lion", "lion_icon.jpg", 6, 12, [0, 0, 0, 1, 1, 0, 0, 0])
	var eagle = _create_card("Eagle", "eagle_icon.jpg", 5, 15, [1, 0, 1, 0, 1, 0, 1, 0])
	var wolf = _create_card("Wolf", "wolf_icon.jpg", 8, 30, [0, 1, 1, 1, 1, 1, 1, 0])
	var owl = _create_card("Owl", "owl_icon.jpg", 4, 3, [0, 0, 0, 0, 0, 0, 0, 1])
	var bear = _create_card("Bear", "bear_icon.jpg", 10, 11, [1, 1, 1, 1, 0, 0, 0, 0])
	var tiger = _create_card("Tiger", "tiger_icon.jpg", 7, 14, [0, 1, 0, 1, 0, 1, 0, 1])
	var dragon = _create_card("Dragon", "dragon_icon.jpg", 1, 0, [0, 0, 0, 0, 1, 0, 0, 0])
	var phoenix = _create_card("Phoenix", "phoenix_icon.jpg", 5, 25, [1, 1, 0, 0, 0, 0, 1, 1])
	
	wolf.skill_b_is_heal = true
	owl.skill_b_is_delay_cd = true
	dragon.skill_b_is_damage_buff = true
	
	all_pool = [lion, eagle, wolf, owl, bear, tiger, dragon, phoenix]
	all_pool.shuffle()
	
	hand_cards = all_pool.slice(0, hand_size)
	deck_cards = all_pool.slice(hand_size)
	
	hand_initialized.emit(hand_cards)

func _create_card(n, icon_name, a, b, slots) -> CardResource:
	var c = CardResource.new()
	c.animal_name = n
	c.animal_icon = load("res://assets/" + icon_name)
	c.skill_a_value = a
	c.skill_b_value = b
	c.slot_map.assign(slots as Array[int])
	return c

func reset_combat():
	player_hp = player_max_hp
	enemies = [
		{
			"name": "Heavy Enemy A",
			"icon": load("res://assets/textures/enemy_placeholder.jpg"),
			"hp": 500,
			"max_hp": 500,
			"cd": 4,
			"cd_default": 4,
			"damage_range": Vector2i(20, 30)
		},
		{
			"name": "Fast Enemy B",
			"icon": load("res://assets/textures/enemy_placeholder.jpg"),
			"hp": 150,
			"max_hp": 150,
			"cd": 1,
			"cd_default": 1,
			"damage_range": Vector2i(5, 10)
		}
	]
	target_enemy_idx = 0
	next_damage_multiplier = 1
	emit_combat_signal()

func select_card(idx: int):
	if idx >= 0 and idx < hand_cards.size():
		selected_hand_idx = idx
		selection_changed.emit(idx)

func select_enemy(idx: int):
	if idx >= 0 and idx < enemies.size():
		if enemies[idx].hp > 0:
			target_enemy_idx = idx
			enemy_selection_changed.emit(idx)
			emit_combat_signal()

func trigger_skill_from_slot(slot_index: int):
	var card = hand_cards[selected_hand_idx]
	var value = card.get_skill_value(slot_index)
	var is_skill_b = (card.get_skill_type(slot_index) == 1)
	
	slot_counts[slot_index] += 1
	var is_ultimate = (slot_counts[slot_index] == 5)
	
	if is_ultimate:
		value *= 2
		clear_slot_requested.emit(slot_index)
		slot_counts[slot_index] = 0
	
	var target = enemies[target_enemy_idx]
	
	if is_skill_b and card.skill_b_is_heal:
		player_hp += value
		if player_hp > player_max_hp: player_hp = player_max_hp
		player_healed.emit(value)
	elif is_skill_b and card.skill_b_is_delay_cd:
		target.cd += value
		print("LOG: DELAY CD of ", target.name, " by ", value)
	elif is_skill_b and card.skill_b_is_damage_buff:
		next_damage_multiplier = 2
		print("LOG: NEXT DAMAGE DOUBLED!")
	else:
		# 執行傷害
		var damage = value * next_damage_multiplier
		target.hp -= damage
		if target.hp <= 0:
			target.hp = 0
			enemy_defeated.emit(target.name)
			_auto_select_next_target()
		
		# 傷害觸發後重置倍率
		next_damage_multiplier = 1
	
	_swap_active_card()
	enemy_turn_tick()
	emit_combat_signal()

func _auto_select_next_target():
	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			target_enemy_idx = i
			enemy_selection_changed.emit(i)
			return

func _swap_active_card():
	var used_card = hand_cards[selected_hand_idx]
	var new_card = deck_cards.pop_front()
	deck_cards.push_back(used_card)
	hand_cards[selected_hand_idx] = new_card
	card_swapped.emit(selected_hand_idx, new_card)

func enemy_turn_tick():
	for m in enemies:
		if m.hp <= 0: continue
		
		m.cd -= 1
		if m.cd <= 0:
			var damage = randi_range(m.damage_range.x, m.damage_range.y)
			player_hp -= damage
			if player_hp < 0: player_hp = 0
			m.cd = m.cd_default
			enemy_attacked.emit(m.name, damage)

func emit_combat_signal():
	combat_updated.emit(player_hp, player_max_hp, enemies, target_enemy_idx, next_damage_multiplier)
