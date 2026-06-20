extends Resource
class_name CardResource

@export var animal_name: String = "Animal"
@export var animal_icon: Texture2D
@export var skill_a_value: int = 5
@export var skill_b_value: int = 15

# 改為存儲 0 (A) 或 1 (B)，長度為 8 的數組
@export var slot_map: Array[int] = [0, 0, 0, 0, 1, 1, 1, 1]

# 由 CardDataLoader 從 skills.csv 填入，供 FoodCardWidget 與桌台燈號顯示用
var skill_a_display: String = "攻擊"
var skill_a_color_a: Color = Color(0.6, 0.6, 0.6)
var skill_a_color_b: Color = Color(0.6, 0.6, 0.6)
var skill_a_effect: BaseSkillEffect

var skill_b_display: String = "攻擊"
var skill_b_color_a: Color = Color(1.0, 0.9, 0.2)
var skill_b_color_b: Color = Color(1.0, 0.9, 0.2)
var skill_b_effect: BaseSkillEffect

func get_skill_value(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slot_map.size():
		return 0
	return skill_a_value if slot_map[slot_index] == 0 else skill_b_value

func get_skill_type(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slot_map.size():
		return 0
	return slot_map[slot_index]

## 根據插槽索引獲取對應技能的正確渲染顏色
func get_skill_color(slot_index: int) -> Color:
	var type := get_skill_type(slot_index)
	if type == 0:
		# 技能 A 放在 A 槽，使用 A 色號
		return skill_a_color_a
	else:
		# 技能 B 放在 B 槽，使用 B 色號
		return skill_b_color_b

## 根據插槽索引獲取對應的技能效果物件
func get_skill_effect(slot_index: int) -> BaseSkillEffect:
	var type := get_skill_type(slot_index)
	return skill_a_effect if type == 0 else skill_b_effect

