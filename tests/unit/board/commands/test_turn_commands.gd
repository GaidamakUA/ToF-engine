extends GutTest


func _make_context() -> BoardCommandContext:
	var state := State.new()
	state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
	state.add_player_ap(0, 1)
	state.add_player(State.PLAYER_AI, "red", true, 1)
	state.add_player_ap(1, 2)
	var map_model := MapModel.new()
	return BoardCommandContext.new(state, map_model, Events.new(), Scripting.new(), Abilities.new(state))


func test_use_current_player_ap_emits_ap_changed_event() -> void:
	var context := _make_context()
	var commands := TurnCommands.new(context)
	var result := commands.use_current_player_ap(1)
	assert_eq(context.state.get_current_ap(), 0)
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is ApChangedEvent)
	assert_eq((result.events[0] as ApChangedEvent).player_id, 0)
	assert_eq((result.events[0] as ApChangedEvent).new_ap, 0)


func test_end_turn_emits_turn_ended_and_turn_started() -> void:
	var context := _make_context()
	var commands := TurnCommands.new(context)
	var result := commands.end_turn()
	assert_eq(context.state.current_player, 1)
	assert_eq(context.state.get_current_side(), "red")
	assert_gte(result.events.size(), 2)
	assert_true(result.events[0] is TurnEndedEvent)
	assert_true(result.events.back() is TurnStartedEvent)
	assert_eq((result.events.back() as TurnStartedEvent).player_id, 1)


func test_end_turn_applies_turn_start_effects_for_the_next_player() -> void:
	var context := _make_context()
	var red_unit_tile := context.map_model.get_tile(Vector2i(1, 0))
	var red_unit := BaseUnit.new()
	red_unit.side = "red"
	red_unit.team = 99
	red_unit.max_move = 4
	red_unit.move = 0
	var red_ability := ActiveUnitAbility.new()
	red_unit.register_ability(red_ability)
	red_unit.get_ability_state(red_ability).cd_turns_left = 2
	red_unit_tile.unit.set_tile(red_unit)

	var red_building_tile := context.map_model.get_tile(Vector2i(2, 0))
	var red_building := BaseBuilding.new()
	red_building.side = "red"
	red_building.team = 99
	red_building.ap_gain = 5
	red_building_tile.building.set_tile(red_building)

	var commands := TurnCommands.new(context)
	var result := commands.end_turn()

	assert_eq(context.state.current_player, 1)
	assert_eq(context.state.get_current_side(), "red")
	assert_eq(context.state.get_current_ap(), 7)
	assert_eq(red_unit.move, 4)
	assert_eq(red_unit.team, 1)
	assert_eq(red_unit.get_ability_cooldown(red_ability), 1)
	assert_eq(red_building.team, 1)
	assert_true(result.events.any(func(event: BaseEvent) -> bool: return event is ApChangedEvent))

	red_unit_tile.unit.release()
	red_building_tile.building.release()
	red_unit.free()
	red_building.free()
