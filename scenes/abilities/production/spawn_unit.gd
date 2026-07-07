extends Ability
class_name SpawnUnit

@export var template_name: String = ""

func _init() -> void:
    self.TYPE = "production"

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var new_unit: BaseUnit = board.map.builder.place_unit(position, self.template_name, 0, board.state.get_current_side())
    var cost: int = self.ap_cost
    cost = board.abilities.get_modified_cost(cost, self.template_name, source)
    board.board_model.use_current_player_ap(cost)
    board._update_ap_spent_presentation()

    new_unit.replenish_moves()
    new_unit.team = board.state.get_player_team(board.state.get_current_side())
    board.abilities.apply_passive_modifiers(new_unit)
    new_unit.sfx_effect("spawn")

    if board.abilities.get_initial_level(self.template_name, source) > 0:
        new_unit.level_up()

    if not board.state.is_current_player_ai():
        board.active_ability = null
        board.select_tile(position)

    board.events.emit_unit_spawned(source, new_unit)

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var cost: int = self.ap_cost
    if model.abilities != null:
        cost = model.abilities.get_modified_cost(cost, self.template_name, source)

    var new_unit: BaseUnit = model.spawn_unit(position, self.template_name, 0, model.get_current_side(), source)
    if new_unit == null:
        result.command_name = "use_ability_failed"
        return result

    result.merge_from(model.use_current_player_ap(cost))

    new_unit.replenish_moves()
    new_unit.team = model.get_current_team()
    if model.abilities != null:
        model.abilities.apply_passive_modifiers(new_unit)
        if model.abilities.get_initial_level(self.template_name, source) > 0:
            new_unit.level_up()

    result.add_event(model.events.emit_unit_spawned(source, new_unit))
    result.metadata["select_tile_position"] = position
    return result
