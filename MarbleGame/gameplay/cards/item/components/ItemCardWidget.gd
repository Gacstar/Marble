extends PanelContainer

signal item_card_clicked(index)

@onready var name_label = $Margin/VBox/ItemName
@onready var icon_rect = $Margin/VBox/Icon
@onready var cd_label = $Margin/VBox/CDLabel
@onready var desc_label = $Margin/VBox/DescLabel
@onready var selection_frame = $SelectionFrame
@onready var lock_overlay = $LockOverlay
@onready var lock_label = $Margin/VBox/LockLabel

var item_index: int = 0
var is_locked: bool = false
var item_resource: ItemCardResource = null

func setup(idx: int, resource: ItemCardResource, selected: bool):
	item_index = idx
	item_resource = resource
	name_label.text = resource.item_name
	icon_rect.texture = resource.item_icon
	
	cd_label.text = "CD: %d" % resource.cd
	
	# 根據 skill_type 顯示功能描述
	match resource.skill_type:
		"damage":
			desc_label.text = "[傷害] -%d" % resource.skill_value
			desc_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		"debuff":
			desc_label.text = "[減速] CD+%d" % resource.skill_value
			desc_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		"heal":
			desc_label.text = "[回復] +%d" % resource.skill_value
			desc_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		"poison":
			desc_label.text = "[中毒] %d" % resource.skill_value
			desc_label.add_theme_color_override("font_color", Color(0.73, 0.22, 1.0))
		_:
			desc_label.text = "[效果] %d" % resource.skill_value
			desc_label.remove_theme_color_override("font_color")
	
	is_locked = resource.lock_turns > 0
	if is_locked:
		lock_label.visible = true
		lock_label.text = "FROZEN (%d)" % resource.lock_turns
		lock_overlay.visible = true
		modulate = Color(0.6, 0.8, 1.0) # 冰藍色調
		cd_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	else:
		lock_label.visible = false
		lock_overlay.visible = false
		modulate = Color(1, 1, 1)
		cd_label.remove_theme_color_override("font_color")
		
		# 如果 CD 剩餘 1 回合，以紅色警示玩家！
		if resource.cd <= 1:
			cd_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			cd_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2)) # 預設金黃色 CD
			
	selection_frame.visible = selected

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			item_card_clicked.emit(item_index)
