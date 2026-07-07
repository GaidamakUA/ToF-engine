extends ActiveUnitAbility

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile: MapTile = board.map.model.get_tile(position)
    source.replenish_moves()
    board.bless_a_tile(tile)

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile: MapTile = model.get_tile_at(position)
    source.replenish_moves()
    self._append_tile_effect(result, "bless", tile)
    return result
