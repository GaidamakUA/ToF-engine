extends BaseUnit

func can_attack(unit: BaseUnit) -> bool:
    if unit != null:
        if self.modifiers.has("attack_air"):
            return true

        return not unit.can_fly
    return false
