extends ActiveUnitAbility

func _execute(board: Board, position: Vector2i) -> void:
    var tile: MapTile = board.map.model.get_tile(position)
    self.source.replenish_moves()
    board.bless_a_tile(tile)
