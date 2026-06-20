class_name SkillDelayCD
extends BaseSkillEffect

func apply_effect(combat_manager: Node, value: int) -> void:
	if combat_manager.target_item_idx >= 0 and combat_manager.target_item_idx < combat_manager.item_cards.size():
		var target_item = combat_manager.item_cards[combat_manager.target_item_idx]
		target_item.lock_turns += value
		print("LOG: [DELAY_CD EFFECT] Target %s is frozen for %d turns" % [target_item.item_name, value])
