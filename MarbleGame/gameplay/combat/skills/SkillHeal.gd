class_name SkillHeal
extends BaseSkillEffect

func apply_effect(combat_manager: Node, value: int) -> void:
	combat_manager.player_hp += value
	if combat_manager.player_hp > combat_manager.player_max_hp:
		combat_manager.player_hp = combat_manager.player_max_hp
	combat_manager.player_healed.emit(value)
	print("LOG: [HEAL EFFECT] Healed %d HP" % value)
