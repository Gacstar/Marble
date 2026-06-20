class_name SkillDamageBuff
extends BaseSkillEffect

func apply_effect(combat_manager: Node, value: int) -> void:
	# 依照原本的 logic，damage_buff 會讓 next_damage_multiplier 設為 2，數值 (value) 在此效果中無特殊用途（可保留作為將來加倍數用）
	combat_manager.next_damage_multiplier = 2
	print("LOG: [DAMAGE_BUFF EFFECT] Next damage doubled!")
