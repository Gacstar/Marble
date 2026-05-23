extends Resource
class_name ItemCardResource

@export var item_name: String = "Item"
@export var item_icon: Texture2D
@export var cd_default: int = 3
@export var cd: int = 3
@export var skill_value: int = 10
@export var skill_type: String = "damage" # "damage", "debuff" 等
@export var lock_turns: int = 0
