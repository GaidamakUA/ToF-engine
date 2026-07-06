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
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is TurnEndedEvent)
	assert_true(result.events[1] is TurnStartedEvent)
	assert_eq((result.events[1] as TurnStartedEvent).player_id, 1)
