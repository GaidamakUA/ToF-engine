extends ActiveAbility

func _execute(board: Board, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)

    tile.unit.tile.replenish_moves()
    tile.unit.tile.reset_cooldown()
    board.bless_a_tile(tile)

func is_tile_applicable(tile: MapTile, _z_source_tile: MapTile) -> bool:
    return tile.has_friendly_unit(self.source.side) and tile.unit.tile != self.source
