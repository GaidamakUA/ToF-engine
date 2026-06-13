extends ActiveUnitAbility

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile: MapTile = board.map.model.get_tile(position)
    source.replenish_moves()
    board.bless_a_tile(tile)
