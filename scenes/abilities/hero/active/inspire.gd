extends ActiveHeroAbility

func _execute(board: Board, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)

    tile.unit.tile.replenish_moves()
    tile.unit.tile.reset_cooldown()
    board.bless_a_tile(tile)

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_friendly_unit(source.side) and tile.unit.tile != source
