extends AbstractBuildingBrain
class_name HqBrain

func _calculate_value(action: SpawnUnit, bonus: int, units_stats: Dictionary[String, int], ap: int) -> int:
    var value: int = super._calculate_value(action, bonus, units_stats, ap)

    value -= 20

    return value
