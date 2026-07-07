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

func _execute_model(model: BoardModel, _source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var destination_tile: MapTile = model.get_tile_at(position)
    var unit: BaseUnit = origin_tile.unit.tile

    destination_tile.unit.set_tile(unit)
    origin_tile.unit.release()
    model.reset_unit_position(destination_tile, unit)

    self._append_tile_effect(result, "smoke", origin_tile)
    self._append_tile_effect(result, "smoke", destination_tile)
    result.add_event(model.events.emit_unit_moved(unit, origin_tile, destination_tile))
    result.metadata["select_tile_position"] = position
    return result

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
