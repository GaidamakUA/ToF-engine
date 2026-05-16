extends SpawnHero

func _execute(board: Board, position: Vector2i) -> void:
    super._execute(board, position)

    var units: Array[BaseUnit] = board.map.model.get_player_units(board.state.get_current_side())
    for unit: BaseUnit in units:
        board.abilities.apply_passive_modifiers(unit)
