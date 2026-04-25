extends PanelContainer

signal monster_clicked(index)

@onready var name_label = $Margin/VBox/MonsterName
@onready var icon_rect = $Margin/VBox/Icon
@onready var hp_bar = $Margin/VBox/HPBar
@onready var hp_label = $Margin/VBox/HPLabel
@onready var cd_label = $Margin/VBox/CDLabel
@onready var selection_frame = $SelectionFrame
@onready var dead_overlay = $DeadOverlay

var monster_index: int = 0
var is_dead: bool = false

func setup(idx: int, data: Dictionary, is_selected: bool):
	monster_index = idx
	name_label.text = data.name
	icon_rect.texture = data.icon
	
	hp_bar.max_value = data.max_hp
	hp_bar.value = data.hp
	hp_label.text = "HP: %d / %d" % [data.hp, data.max_hp]
	cd_label.text = "CD: %d" % data.cd
	
	background_logic(data, is_selected)

func background_logic(data, selected):
	selection_frame.visible = selected and data.hp > 0
	dead_overlay.visible = data.hp <= 0
	is_dead = (data.hp <= 0)
	
	if is_dead:
		modulate = Color(0.6, 0.6, 0.6)
		selection_frame.visible = false
	else:
		modulate = Color(1, 1, 1)

func set_selected(selected: bool):
	if not is_dead:
		selection_frame.visible = selected

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not is_dead:
			monster_clicked.emit(monster_index)
