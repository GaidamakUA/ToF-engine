extends ActiveHeroAbility

func _execute(board: Board, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)

    tile.unit.get_map_object().replenish_moves()
    tile.unit.get_map_object().reset_cooldown()
    board.bless_a_tile(tile)

func is_tile_applicable(tile: MapTile, _z_source_tile: MapTile) -> bool:
    return tile.has_friendly_unit(self.source.side) and tile.unit.get_map_object() != self.source
