extends ActiveHeroAbility

@export var unit_template: String = "blue_infantry"

var deep_strike_executor_template: PackedScene = preload("res://scenes/abilities/hero/active/deep_strike_executor.tscn")

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var executor: DeepStrikeExecutor = self.deep_strike_executor_template.instantiate()

    executor.set_up(board, position, source, self.unit_template)
    board.ability_markers.add_child(executor)
    executor.set_position(board.map.map_to_local(position))

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)
    var new_unit: BaseUnit = model.spawn_unit(position, self.unit_template, 90, source.side, source)
    if new_unit == null:
        result.command_name = "use_ability_failed"
        return result
    new_unit.remove_moves()
    new_unit.team = source.team
    if model.abilities != null:
        model.abilities.apply_passive_modifiers(new_unit)
    result.add_event(model.events.emit_unit_spawned(source, new_unit))
    result.add_event(model.events.emit_unit_moved(new_unit, tile, tile))
    result.metadata["select_tile_position"] = position
    return result

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
