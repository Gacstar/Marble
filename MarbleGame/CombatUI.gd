extends CanvasLayer

@onready var player_hp_bar = $PlayerSide/ProgressBar
@onready var player_hp_label = $PlayerSide/HPLabel
@onready var monster_container = $MonsterSide/MonsterContainer
@onready var card_container = $PlayerSide/CardHand

var card_widget_scene = preload("res://CardWidget.tscn")
var monster_widget_scene = preload("res://MonsterWidget.tscn")
var card_widgets: Array = []
var monster_widgets: Array = []
var current_hand: Array[CardResource] = []
var current_selected_card_idx: int = 0

signal card_selected_bubbled(idx)
signal monster_selected_bubbled(idx)

func initialize_cards(cards: Array[CardResource]):
	current_hand = cards
	for child in card_container.get_children():
		child.queue_free()
	card_widgets.clear()
	
	for i in range(cards.size()):
		var widget = card_widget_scene.instantiate()
		card_container.add_child(widget)
		widget.setup(i, cards[i], i == current_selected_card_idx, 1)
		card_widgets.append(widget)
		widget.card_selected.connect(func(idx): card_selected_bubbled.emit(idx))

func update_card_at_index(idx: int, new_card: CardResource):
	if idx >= 0 and idx < current_hand.size():
		current_hand[idx] = new_card
		# 這裡不直接 setup，交由下一次 update_ui 統一刷新

func update_selection(selected_idx: int):
	current_selected_card_idx = selected_idx
	# 交由下一次 update_ui 統一刷新

func update_ui(player_hp: int, p_max: int, monsters_data: Array, target_idx: int, multiplier: int):
	# 更新玩家 UI
	player_hp_bar.max_value = p_max
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP: %d / %d" % [player_hp, p_max]
	
	# 更新手牌顯示 (處理變色與加倍文字)
	for i in range(card_widgets.size()):
		if i < current_hand.size():
			card_widgets[i].setup(i, current_hand[i], i == current_selected_card_idx, multiplier)
	
	# 同步怪物組件數量
	if monster_widgets.size() != monsters_data.size():
		_rebuild_monster_widgets(monsters_data, target_idx)
	else:
		for i in range(monster_widgets.size()):
			monster_widgets[i].setup(i, monsters_data[i], i == target_idx)

func _rebuild_monster_widgets(monsters_data, target_idx):
	for child in monster_container.get_children():
		child.queue_free()
	monster_widgets.clear()
	
	for i in range(monsters_data.size()):
		var widget = monster_widget_scene.instantiate()
		monster_container.add_child(widget)
		widget.setup(i, monsters_data[i], i == target_idx)
		monster_widgets.append(widget)
		widget.monster_clicked.connect(func(idx): monster_selected_bubbled.emit(idx))

func show_damage_effect(target: String, amount: int):
	if target == "PlayerHeal":
		print("LOG: [HEAL] Player recovered ", amount, " HP!")
	else:
		print("LOG: [DAMAGE] ", target, " took ", amount, " damage!")
