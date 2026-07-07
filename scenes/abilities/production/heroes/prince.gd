extends SpawnHero

func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    super._execute(board, source, origin_tile, position)

    var units: Array[BaseUnit] = board.map.model.get_player_units(board.state.get_current_side())
    for unit: BaseUnit in units:
        board.abilities.apply_passive_modifiers(unit)

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := super._execute_model(model, source, origin_tile, position)
    var units: Array[BaseUnit] = model.map_model.get_player_units(model.get_current_side())
    for unit: BaseUnit in units:
        if model.abilities != null:
            model.abilities.apply_passive_modifiers(unit)
    return result
