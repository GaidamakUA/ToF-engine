extends SpawnUnit
class_name SpawnHero

func _is_visible(board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    if board == null:
        return false

    if board.state.has_side_a_hero(source.side):
        return false

    return true
