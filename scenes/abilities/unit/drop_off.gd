extends ActiveUnitAbility

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var tile: MapTile = model._get_tile_at(position)
    if source.passenger == null or tile == null or not tile.can_acommodate_unit():
        return []
    tile.unit.set_tile(source.passenger)
    source.passenger.state.remove_moves()
    source.passenger = null
    return [position]

func _is_visible(_model: BoardModel, source: Variant = null) -> bool:
    if source == null:
        return false

    if source.passenger == null:
        return false

    return true

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
