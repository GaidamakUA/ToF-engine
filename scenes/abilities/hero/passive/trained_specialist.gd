extends PassiveAbility

func get_modified_cooldown(cd_value: int) -> int:
    if cd_value > 1:
        return cd_value - 1

    return cd_value
