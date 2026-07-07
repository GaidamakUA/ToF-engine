extends ActiveUnitAbility

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    tile.unit.set_tile(source.passenger)
    board.map.anchor_unit(source.passenger, position)
    tile._get_unit().sfx_effect("move")
    
    source.passenger.remove_moves()
    source.passenger = null

    board.smoke_a_tile(tile)

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)
    tile.unit.set_tile(source.passenger)
    model.anchor_unit(source.passenger, position)
    source.passenger.remove_moves()
    source.passenger = null
    self._append_tile_effect(result, "smoke", tile)
    return result

func _is_visible(_board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    if source.passenger == null:
        return false

    return true

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
