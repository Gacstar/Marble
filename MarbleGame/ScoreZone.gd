extends Area2D

@onready var indicator = $Indicator

func _ready():
	add_to_group("ScoreZone")

func set_indicator_color(color: Color):
	indicator.color = color
