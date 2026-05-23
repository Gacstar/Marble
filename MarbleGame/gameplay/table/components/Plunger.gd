extends Node2D

@onready var head = $PlungerHead

var is_dragging = false
var drag_start_y = 0.0
var max_drag = 100.0
var default_y = 0.0

func _ready():
	print("LOG: Plunger Script Loaded at ", global_position)
	default_y = head.position.y

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = event.position
				# Check if click is in the bottom-right corner control zone
				if mouse_pos.x > 380 and mouse_pos.y > 550:
					print("LOG: Plunger Drag Start at ", mouse_pos)
					is_dragging = true
					drag_start_y = mouse_pos.y
			elif is_dragging:
				release_plunger()
	
	elif event is InputEventMouseMotion and is_dragging:
		var current_mouse_y = event.position.y
		var offset = max(0, current_mouse_y - drag_start_y)
		head.position.y = default_y + min(offset, max_drag)
		
		# Feedback every few frames while dragging
		if Engine.get_frames_drawn() % 60 == 0:
			print("LOG: Current dragging offset: ", head.position.y - default_y)

func _process(_delta):
	pass # Logic moved to _input for better Viewport compatibility

func release_plunger():
	print("LOG: Plunger Released - Snap back!")
	is_dragging = false
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	# 將回彈時間從 0.02 秒拉長到 0.06 秒左右，降低瞬間頂回去的物理速度
	tween.tween_property(head, "position:y", default_y, 0.1)
