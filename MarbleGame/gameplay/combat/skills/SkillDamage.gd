class_name SkillDamage
extends BaseSkillEffect

func apply_effect(combat_manager: Node, value: int) -> void:
	var damage = value * combat_manager.next_damage_multiplier
	combat_manager.active_enemy.hp -= damage
	if combat_manager.active_enemy.hp <= 0:
		combat_manager.active_enemy.hp = 0
		combat_manager.enemy_defeated.emit(combat_manager.active_enemy.name)
	
	# 重設加成倍率
	combat_manager.next_damage_multiplier = 1
	print("LOG: [DAMAGE EFFECT] Dealt %d damage" % damage)
