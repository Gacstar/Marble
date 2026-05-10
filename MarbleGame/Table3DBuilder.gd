extends Node3D

signal slot_hit(slot_idx)

@export var table_2d_scene: PackedScene = preload("res://MarbleTable.tscn")
@export var peg_3d_scene: PackedScene = preload("res://Peg3D.tscn")
@export var ball_3d_scene: PackedScene = preload("res://Ball3D.tscn")
@export var score_zone_3d_scene: PackedScene = preload("res://ScoreZone3D.tscn")
@export var plunger_3d_scene: PackedScene = preload("res://Plunger3D.tscn")

const PIXELS_PER_UNIT = 100.0
const TABLE_WIDTH = 457.0
const TABLE_HEIGHT = 814.0

var plunger_instance = null

func _ready():
	generate_table()
	print("LOG: MarbleTable3D Ready.")

func generate_table():
	if not table_2d_scene: return
	var table_2d = table_2d_scene.instantiate()
	
	# 1. 生成釘子
	var pegs_container = table_2d.get_node_or_null("Pegs")
	if pegs_container:
		for peg_2d in pegs_container.get_children():
			spawn_peg_3d(peg_2d.position)
	
	# 2. 生成得分區 (Slots)
	var slots_container = table_2d.get_node_or_null("Slots")
	if slots_container:
		var idx = 0
		for slot_2d in slots_container.get_children():
			if slot_2d.name.contains("ScoreZone"):
				spawn_score_zone_3d(slot_2d.position, idx)
				idx += 1
	
	# 3. 生成拉桿 (Plunger)
	var plunger_2d = table_2d.get_node_or_null("Plunger")
	if plunger_2d:
		spawn_plunger_3d(plunger_2d.position)
			
	# 4. 生成邊界牆壁
	_create_wall(Vector3(0, TABLE_HEIGHT/(2.0*PIXELS_PER_UNIT), 0.2), Vector3(TABLE_WIDTH/PIXELS_PER_UNIT, 0.2, 0.5)) # Top
	_create_wall(Vector3(-TABLE_WIDTH/(2.0*PIXELS_PER_UNIT), 0, 0.2), Vector3(0.2, TABLE_HEIGHT/PIXELS_PER_UNIT, 0.5)) # Left
	_create_wall(Vector3(TABLE_WIDTH/(2.0*PIXELS_PER_UNIT), 0, 0.2), Vector3(0.2, TABLE_HEIGHT/PIXELS_PER_UNIT, 0.5)) # Right
	_create_wall(Vector3(0, 0, 0.5), Vector3(TABLE_WIDTH/PIXELS_PER_UNIT, TABLE_HEIGHT/PIXELS_PER_UNIT, 0.1)) # Front Glass (Invisible)
	
	# 內部發射道隔牆 (根據 Plunger 位置)
	_create_wall(Vector3(1.6, -1.0, 0.2), Vector3(0.1, 6.0, 0.5)) 
	
	table_2d.queue_free()

func _create_wall(pos: Vector3, size: Vector3):
	var sb = StaticBody3D.new()
	sb.input_ray_pickable = false # 關鍵：防止牆壁擋住點擊
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	coll.shape = shape
	sb.add_child(coll)
	add_child(sb)
	sb.position = pos

func spawn_peg_3d(pos_2d: Vector2):
	var peg = peg_3d_scene.instantiate()
	add_child(peg)
	var x = (pos_2d.x / PIXELS_PER_UNIT) - (TABLE_WIDTH / (2.0 * PIXELS_PER_UNIT))
	var y = ((TABLE_HEIGHT - pos_2d.y) / PIXELS_PER_UNIT) - (TABLE_HEIGHT / (2.0 * PIXELS_PER_UNIT))
	peg.position = Vector3(x, y, 0.2)

func spawn_score_zone_3d(pos_2d: Vector2, idx: int):
	var zone = score_zone_3d_scene.instantiate()
	add_child(zone)
	zone.slot_index = idx
	zone.ball_entered.connect(_on_ball_entered_slot)
	
	var x = (pos_2d.x / PIXELS_PER_UNIT) - (TABLE_WIDTH / (2.0 * PIXELS_PER_UNIT))
	var y = ((TABLE_HEIGHT - pos_2d.y) / PIXELS_PER_UNIT) - (TABLE_HEIGHT / (2.0 * PIXELS_PER_UNIT))
	zone.position = Vector3(x, y, 0.2)

func spawn_plunger_3d(pos_2d: Vector2):
	plunger_instance = plunger_3d_scene.instantiate()
	add_child(plunger_instance)
	plunger_instance.launched.connect(_on_plunger_launched)
	
	var x = (pos_2d.x / PIXELS_PER_UNIT) - (TABLE_WIDTH / (2.0 * PIXELS_PER_UNIT))
	var y = ((TABLE_HEIGHT - pos_2d.y) / PIXELS_PER_UNIT) - (TABLE_HEIGHT / (2.0 * PIXELS_PER_UNIT))
	plunger_instance.position = Vector3(x, y, 0.2)
	plunger_instance.initial_pos = plunger_instance.position

func _on_plunger_launched(force):
	spawn_ball(force)

func spawn_ball(initial_force: float):
	var ball = ball_3d_scene.instantiate()
	add_child(ball)
	# 在拉桿上方一點生成
	ball.position = plunger_instance.position + Vector3(0, 0.5, 0)
	ball.apply_central_impulse(Vector3(0, initial_force, 0))

func _on_ball_entered_slot(idx):
	slot_hit.emit(idx)

# --- 介面橋接 ---
func clear_slot_marbles(slot_idx):
	pass

func update_slot_indicators(card):
	pass
