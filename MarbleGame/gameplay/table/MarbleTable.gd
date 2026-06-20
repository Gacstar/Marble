extends Node2D

signal score_achieved(points) # 保持舊信號可能會有用，但主軸轉到下方
signal slot_hit(index)

@onready var pegs_container = $Pegs
@onready var slots_container = $Slots
@onready var spawn_point = $BallSpawnPoint

var ball_scene = preload("res://gameplay/table/components/Ball.tscn")
var total_balls = 9
var remaining_balls = 9
var score = 0
var current_ball = null
var slot_zones: Array = []

func _ready():
	print("LOG: MarbleTable Ready.")
	randomize()
	
	# 核心改動：按順序抓取槽位，方便對應索引
	slot_zones = slots_container.get_children().filter(func(node): return node.is_in_group("ScoreZone"))
	for i in range(slot_zones.size()):
		var zone = slot_zones[i]
		zone.body_entered.connect(_on_score_zone_entered.bind(i))

	await get_tree().create_timer(0.5).timeout
	spawn_ball()

func spawn_ball():
	if remaining_balls > 0:
		current_ball = ball_scene.instantiate()
		current_ball.position = spawn_point.position
		add_child(current_ball)

func _on_score_zone_entered(body, slot_idx):
	if body is RigidBody2D and "scored" in body:
		if body.scored: return
		body.scored = true
		
		print("LOG: Ball Hit Slot Index: ", slot_idx)
		slot_hit.emit(slot_idx)
		
		await get_tree().create_timer(0.5).timeout
		spawn_ball()

func update_slot_indicators(card: CardResource):
	var slot_map = card.slot_map
	for i in range(slot_zones.size()):
		if i < slot_map.size():
			var color = card.get_skill_color(i)
			slot_zones[i].set_indicator_color(color)


func clear_slot_marbles(slot_index: int):
	if slot_index < 0 or slot_index >= slot_zones.size():
		return
		
	var zone = slot_zones[slot_index]
	var bodies = zone.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D and "scored" in body:
			print("LOG: Clearing ultimate ball from slot: ", slot_index)
			body.queue_free()
