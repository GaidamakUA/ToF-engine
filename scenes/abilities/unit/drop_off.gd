extends ActiveUnitAbility

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    tile.unit.set_tile(source.passenger)
    board.map.anchor_unit(source.passenger, position)
    tile._get_unit().sfx_effect("move")
    
    source.passenger.remove_moves()
    source.passenger = null

    board.smoke_a_tile(tile)

func _is_visible(_board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    if source.passenger == null:
        return false

    return true

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
