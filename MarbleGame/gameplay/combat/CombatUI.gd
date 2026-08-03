extends CanvasLayer

@onready var player_hp_bar = $PlayerSide/ProgressBar
@onready var player_hp_label = $PlayerSide/HPLabel
@onready var card_container = $PlayerSide/CardHand
@onready var skill_director = $SkillDirector

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

var player_poison_particles: CPUParticles2D = null
var enemy_poison_particles: CPUParticles2D = null

signal card_selected_bubbled(idx)
signal enemy_selected_bubbled(idx)
signal surrender_clicked

func _ready():
	$SurrenderButton.pressed.connect(func(): surrender_clicked.emit())

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

var current_multiplier: int = 1

func update_card_at_index(idx: int, new_card: CardResource):
	if idx >= 0 and idx < current_hand.size():
		current_hand[idx] = new_card

func update_selection(selected_idx: int):
	current_selected_card_idx = selected_idx
	# 立即刷新所有手牌的選取外框狀態
	for i in range(food_card_widgets.size()):
		if i < current_hand.size():
			food_card_widgets[i].setup(i, current_hand[i], i == current_selected_card_idx, current_multiplier)

func update_ui(player_hp: int, p_max: int, enemy_data: Dictionary, item_cards_data: Array, target_item_idx: int, multiplier: int, skip_hp: bool = false):
	current_multiplier = multiplier
	
	var cm = get_parent().combat_manager
	
	# 更新玩家 (老奶奶) HP UI
	if not skip_hp:
		player_hp_bar.max_value = p_max
		player_hp_bar.value = player_hp
		var p_text = "HP: %d / %d" % [player_hp, p_max]
		if cm and cm.player_poison_turns > 0:
			p_text += " (毒:%d)" % cm.player_poison_turns
		player_hp_label.text = p_text
	
	# 更新手牌顯示
	for i in range(food_card_widgets.size()):
		if i < current_hand.size():
			food_card_widgets[i].setup(i, current_hand[i], i == current_selected_card_idx, multiplier)
	
	# 更新敵方 (奧客) HP UI 及大頭像
	if not skip_hp:
		enemy_hp_bar.max_value = enemy_data.max_hp
		enemy_hp_bar.value = enemy_data.hp
		var e_text = "HP: %d / %d" % [enemy_data.hp, enemy_data.max_hp]
		if cm and cm.enemy_poison_turns > 0:
			e_text += " (毒:%d)" % cm.enemy_poison_turns
		enemy_hp_label.text = e_text
	enemy_name_label.text = enemy_data.name
	enemy_sprite.texture = enemy_data.icon
	
	# 同步敵方道具卡組件數量
	if item_card_widgets.size() != item_cards_data.size():
		_rebuild_item_card_widgets(item_cards_data, target_item_idx)
	else:
		for i in range(item_card_widgets.size()):
			item_card_widgets[i].setup(i, item_cards_data[i], i == target_item_idx)
			
	# 更新中毒粒子特效
	if cm:
		_update_poison_particles(true, cm.player_poison_turns)
		_update_poison_particles(false, cm.enemy_poison_turns)

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

func _update_poison_particles(is_player: bool, poison_turns: int):
	var target_sprite = $PlayerSide/GrandmaSprite if is_player else enemy_sprite
	var particles_ref = player_poison_particles if is_player else enemy_poison_particles
	
	if poison_turns > 0:
		# 如果還沒有粒子，就建立一個
		if particles_ref == null or not is_instance_valid(particles_ref):
			var particles = CPUParticles2D.new()
			particles.name = "PoisonParticles"
			particles.amount = 12
			particles.lifetime = 1.2
			particles.preprocess = 0.5 # 讓它一出來就有一些粒子
			particles.speed_scale = 0.8
			
			# 發射形狀：在大頭像底部發射
			particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			particles.emission_rect_extents = Vector2(target_sprite.size.x / 2.0 - 10, 5)
			
			# 運動：向上飄散
			particles.direction = Vector2(0, -1)
			particles.spread = 15.0
			particles.gravity = Vector2(0, -20)
			particles.initial_velocity_min = 20.0
			particles.initial_velocity_max = 40.0
			
			# 顏色漸層 (紫色漸變淡出)
			var gradient = Gradient.new()
			gradient.set_color(0, Color(0.73, 0.22, 1.0, 0.85)) # 亮紫色
			gradient.set_color(1, Color(0.46, 0.12, 0.65, 0.0))  # 漸隱暗紫色
			particles.color_ramp = gradient
			
			# 粒子大小與隨機度
			particles.scale_amount_min = 3.0
			particles.scale_amount_max = 7.0
			
			# 掛載到頭像
			target_sprite.add_child(particles)
			# 擺在頭像偏下方，讓粒子由下往上飄過頭像
			particles.position = Vector2(target_sprite.size.x / 2.0, target_sprite.size.y - 10)
			
			# 儲存引用
			if is_player:
				player_poison_particles = particles
			else:
				enemy_poison_particles = particles
			
			particles.emitting = true
	else:
		# 沒中毒了，清除粒子
		if particles_ref != null and is_instance_valid(particles_ref):
			var temp_p = particles_ref
			temp_p.emitting = false
			
			# 延遲銷毀以自然播完生命週期
			get_tree().create_timer(temp_p.lifetime).timeout.connect(func():
				if is_instance_valid(temp_p):
					temp_p.queue_free()
			)
			
			if is_player:
				player_poison_particles = null
			else:
				enemy_poison_particles = null

func show_damage_effect(target: String, amount: int):
	if target == "PlayerHeal":
		print("LOG: [HEAL] Player recovered ", amount, " HP!")
	else:
		print("LOG: [DAMAGE] ", target, " took ", amount, " damage!")
