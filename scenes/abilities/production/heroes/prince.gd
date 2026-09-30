extends SpawnHero

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var affected: Array[Vector2i] = super._execute_model(model, source, origin_tile, position)
    for unit: BaseUnit in model.map_model.get_player_units(model.get_current_side()):
        model.abilities.apply_passive_modifiers(unit)
    return affected
