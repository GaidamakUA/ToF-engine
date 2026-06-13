extends ActiveHeroAbility

func _execute(board: Board, _source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    var destination_tile: MapTile = board.map.model.get_tile(position)

    destination_tile.unit.set_tile(origin_tile.unit.tile)
    origin_tile.unit.release()

    board.reset_unit_position(destination_tile, destination_tile.unit.tile)
    board.smoke_a_tile(origin_tile)
    board.smoke_a_tile(destination_tile)

    board.cancel_ability()
    board.select_tile(position)

    board.events.emit_unit_moved(destination_tile.unit.tile, origin_tile, destination_tile)

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
