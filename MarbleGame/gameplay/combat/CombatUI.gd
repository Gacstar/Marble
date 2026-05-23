extends CanvasLayer

@onready var player_hp_bar = $PlayerSide/ProgressBar
@onready var player_hp_label = $PlayerSide/HPLabel
@onready var card_container = $PlayerSide/CardHand

@onready var enemy_sprite = $EnemySide/EnemySprite
@onready var enemy_hp_bar = $EnemySide/ProgressBar
@onready var enemy_hp_label = $EnemySide/HPLabel
@onready var enemy_name_label = $EnemySide/EnemyName
@onready var item_card_container = $EnemySide/ItemCardContainer

var food_card_widget_scene = preload("res://gameplay/cards/food/FoodCardWidget.tscn")
var item_card_widget_scene = preload("res://gameplay/cards/item/components/ItemCardWidget.tscn")
var food_card_widgets: Array = []
var item_card_widgets: Array = []
var current_hand: Array[CardResource] = []
var current_selected_card_idx: int = 0

signal card_selected_bubbled(idx)
signal enemy_selected_bubbled(idx)

func initialize_cards(cards: Array[CardResource]):
	current_hand = cards
	for child in card_container.get_children():
		child.queue_free()
	food_card_widgets.clear()
	
	for i in range(cards.size()):
		var widget = food_card_widget_scene.instantiate()
		card_container.add_child(widget)
		widget.setup(i, cards[i], i == current_selected_card_idx, 1)
		food_card_widgets.append(widget)
		widget.card_selected.connect(func(idx): card_selected_bubbled.emit(idx))

func update_card_at_index(idx: int, new_card: CardResource):
	if idx >= 0 and idx < current_hand.size():
		current_hand[idx] = new_card

func update_selection(selected_idx: int):
	current_selected_card_idx = selected_idx

func update_ui(player_hp: int, p_max: int, enemy_data: Dictionary, item_cards_data: Array, target_item_idx: int, multiplier: int):
	# 更新玩家 (老奶奶) HP UI
	player_hp_bar.max_value = p_max
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP: %d / %d" % [player_hp, p_max]
	
	# 更新手牌顯示
	for i in range(food_card_widgets.size()):
		if i < current_hand.size():
			food_card_widgets[i].setup(i, current_hand[i], i == current_selected_card_idx, multiplier)
	
	# 更新敵方 (奧客) HP UI 及大頭像
	enemy_hp_bar.max_value = enemy_data.max_hp
	enemy_hp_bar.value = enemy_data.hp
	enemy_hp_label.text = "HP: %d / %d" % [enemy_data.hp, enemy_data.max_hp]
	enemy_name_label.text = enemy_data.name
	enemy_sprite.texture = enemy_data.icon
	
	# 同步敵方道具卡組件數量
	if item_card_widgets.size() != item_cards_data.size():
		_rebuild_item_card_widgets(item_cards_data, target_item_idx)
	else:
		for i in range(item_card_widgets.size()):
			item_card_widgets[i].setup(i, item_cards_data[i], i == target_item_idx)

func _rebuild_item_card_widgets(item_cards_data: Array, target_item_idx: int):
	for child in item_card_container.get_children():
		child.queue_free()
	item_card_widgets.clear()
	
	for i in range(item_cards_data.size()):
		var widget = item_card_widget_scene.instantiate()
		item_card_container.add_child(widget)
		widget.setup(i, item_cards_data[i], i == target_item_idx)
		item_card_widgets.append(widget)
		widget.item_card_clicked.connect(func(idx): enemy_selected_bubbled.emit(idx))

func show_damage_effect(target: String, amount: int):
	if target == "PlayerHeal":
		print("LOG: [HEAL] Player recovered ", amount, " HP!")
	else:
		print("LOG: [DAMAGE] ", target, " took ", amount, " damage!")

