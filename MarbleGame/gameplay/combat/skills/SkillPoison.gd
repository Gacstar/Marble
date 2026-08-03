class_name SkillPoison
extends BaseSkillEffect

func apply_effect(combat_manager: Node, value: int) -> void:
	# 中毒效果會受到蓄力倍率 (next_damage_multiplier) 影響
	var final_value = value * combat_manager.next_damage_multiplier
	
	# 施加中毒給敵方
	combat_manager.enemy_poison_turns = 3
	combat_manager.enemy_poison_value = final_value
	
	# 重設蓄力倍率
	combat_manager.next_damage_multiplier = 1
	print("LOG: [POISON EFFECT] Applied poison to enemy. Value: %d, turns: 3" % final_value)
