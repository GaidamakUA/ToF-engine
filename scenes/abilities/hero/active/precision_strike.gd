extends ActiveHeroAbility

var precision_strike_executor_template: PackedScene = preload("res://scenes/abilities/hero/active/precision_strike_executor.tscn")


func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var executor: PrecisionStrikeExecutor = self.precision_strike_executor_template.instantiate()

    executor.set_up(board, position, source)
    board.ability_markers.add_child(executor)
    executor.set_position(board.map.map_to_local(position))

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)

    self._bomb_tile_model(model, result, source, tile)
    for neighbour: MapTile in tile.neighbours.values():
        self._bomb_tile_model(model, result, source, neighbour)

    result.metadata["refresh_selection"] = true
    return result


func _bomb_tile_model(model: BoardModel, result: CommandResult, source: BaseUnit, tile: MapTile) -> void:
    if tile.unit.is_present():
        tile.unit.tile.receive_direct_damage(PrecisionStrikeExecutor.DAMAGE)
        if not tile.unit.tile.is_alive():
            result.merge_from(model.destroy_unit_on_tile(tile, source))
            if model.collateral != null:
                model.collateral.apply_destroyed_unit_collateral(tile)
            self._append_destroyed_tile(result, tile)
    self._append_tile_effect(result, "explode", tile)

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    if tile.unit.is_present():
        return tile.unit.tile != source
    return true
