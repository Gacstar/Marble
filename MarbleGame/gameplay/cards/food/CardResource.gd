extends Resource
class_name CardResource

@export var animal_name: String = "Animal"
@export var animal_icon: Texture2D
@export var skill_a_value: int = 5
@export var skill_b_value: int = 15
@export var skill_b_is_heal: bool = false
@export var skill_b_is_delay_cd: bool = false
@export var skill_b_is_damage_buff: bool = false
# 改為存儲 0 (A) 或 1 (B)，長度為 8 的數組
@export var slot_map: Array[int] = [0, 0, 0, 0, 1, 1, 1, 1]

# 由 CardDataLoader 從 skills.csv 填入，供 FoodCardWidget 顯示用
var skill_a_display: String = "攻擊"
var skill_a_color: Color = Color(0.6, 0.6, 0.6)
var skill_b_display: String = "攻擊"
var skill_b_color: Color = Color(1.0, 0.9, 0.2)

func get_skill_value(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slot_map.size():
		return 0
	return skill_a_value if slot_map[slot_index] == 0 else skill_b_value

func get_skill_type(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slot_map.size():
		return 0
	return slot_map[slot_index]
