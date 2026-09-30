extends SpawnUnit
class_name SpawnHero

func _is_visible(model: BoardModel, source: Variant = null) -> bool:
    if source == null:
        return false

    if model == null:
        return false

    if model._state.has_side_a_hero(source.side):
        return false

    return true
