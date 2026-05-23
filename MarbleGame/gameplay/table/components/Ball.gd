extends RigidBody2D

# 標記這顆彈珠是否已經被計分過
var scored = false

func _ready():
	var sprite = get_node_or_null("Sprite2D")
	var col = get_node_or_null("CollisionShape2D")
	if sprite and col and col.shape is CircleShape2D:
		var target_diameter = col.shape.radius * 2.0
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0.0:
			var scale_factor = target_diameter / tex_size.x
			sprite.scale = Vector2(scale_factor, scale_factor)
