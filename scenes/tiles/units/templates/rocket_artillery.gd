extends BaseUnit

func has_active_ability() -> bool:
    return self.active_abilities.size() > 0

func can_attack(_unit: BaseUnit) -> bool:
    return false
