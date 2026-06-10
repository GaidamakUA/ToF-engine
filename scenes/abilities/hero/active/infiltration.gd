extends ActiveHeroAbility

func _execute(board: Board, position: Vector2i) -> void:
    var source_tile: MapTile = board.selected_tile
    var destination_tile: MapTile = board.map.model.get_tile(position)

    destination_tile.unit.set_map_object(source_tile.unit.get_map_object())
    source_tile.unit.release()

    board.reset_unit_position(destination_tile, destination_tile.unit.get_map_object())
    board.smoke_a_tile(source_tile)
    board.smoke_a_tile(destination_tile)

    board.cancel_ability()
    board.select_tile(position)

    board.events.emit_unit_moved(destination_tile.unit.get_map_object(), source_tile, destination_tile)

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
    return tile.can_acommodate_unit()
