extends PanelContainer

signal card_selected(idx)

@onready var icon_rect = $Margin/HBox/Icon
@onready var name_label = $Margin/HBox/InfoVBox/AnimalName
@onready var skill_a_label = $Margin/HBox/InfoVBox/SkillALayout/SkillA
@onready var skill_b_label = $Margin/HBox/InfoVBox/SkillBLayout/SkillB
@onready var light_a = $Margin/HBox/InfoVBox/SkillALayout/LightA
@onready var light_b = $Margin/HBox/InfoVBox/SkillBLayout/LightB
@onready var colormap_container = $Margin/HBox/InfoVBox/ColorMap

var card_index: int = 0
var is_selected: bool = false

func setup(idx: int, resource: CardResource, selected: bool, multiplier: int = 1):
	card_index = idx
	icon_rect.texture = resource.animal_icon
	name_label.text = resource.animal_name
	
	background_logic(resource, selected, multiplier)

func background_logic(resource, selected, multiplier):
	# 處理選取效果
	if selected:
		modulate = Color(1.2, 1.2, 1.2)
		self.set("theme_override_styles/panel", preload("res://core/selected_style.tres"))
	else:
		modulate = Color(1, 1, 1)
		self.set("theme_override_styles/panel", null)
	
	# 技能 A 呈現
	var val_a = resource.skill_a_value * multiplier
	skill_a_label.text = "[%s] %d" % [resource.skill_a_display, val_a]
	if multiplier > 1:
		skill_a_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		skill_a_label.remove_theme_color_override("font_color")
	light_a.color = resource.skill_a_color_a
	
	# 技能 B 呈現
	light_b.color = resource.skill_b_color_b
	if resource.skill_b_effect is SkillHeal:
		skill_b_label.text = "[%s] HP+%d" % [resource.skill_b_display, resource.skill_b_value]
	elif resource.skill_b_effect is SkillDelayCD:
		skill_b_label.text = "[%s] CD+%d" % [resource.skill_b_display, resource.skill_b_value]
	elif resource.skill_b_effect is SkillDamageBuff:
		skill_b_label.text = "[%s] 下次 x2" % resource.skill_b_display
	else:
		var val_b = resource.skill_b_value * multiplier
		skill_b_label.text = "[%s] %d" % [resource.skill_b_display, val_b]
		if multiplier > 1:
			skill_b_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		else:
			skill_b_label.remove_theme_color_override("font_color")
	
	# 色塊圖更新
	_update_colormap(resource)

func _update_colormap(resource: CardResource):
	for child in colormap_container.get_children():
		child.queue_free()
	for idx in range(resource.slot_map.size()):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(8, 8)
		rect.color = resource.get_skill_color(idx)
		colormap_container.add_child(rect)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_selected.emit(card_index)
