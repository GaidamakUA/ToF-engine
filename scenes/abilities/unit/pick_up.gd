extends ActiveUnitAbility

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    var target_unit: BaseUnit = tile._get_unit()
    target_unit.sfx_effect("move")
    
    source.passenger = target_unit
    tile.unit.release()
    board.map.detach_unit(source.passenger)

    board.smoke_a_tile(tile)
    source.use_all_moves()

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)
    var target_unit: BaseUnit = tile._get_unit()

    source.passenger = target_unit
    tile.unit.release()
    model.detach_unit(source.passenger)
    source.use_all_moves()

    self._append_tile_effect(result, "smoke", tile)
    return result

func _is_visible(_board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    if source.passenger != null:
        return false

    return true

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    var applicable_types := ["infantry"]
    if source.level == 3:
        applicable_types.append("mobile_infantry")
    if tile.has_friendly_unit(source.side):
        return tile._get_unit().unit_class in applicable_types
    return false
