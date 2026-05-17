extends BaseUnit


func has_active_ability() -> bool:
	return self.active_abilities.size() > 0
	

func can_attack(unit: BaseUnit) -> bool:
	if unit != null:
		if self.modifiers.has("attack_air"):
			return true

		return not unit.can_fly
	return false
