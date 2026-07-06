extends GutTest


func test_new_model_owns_headless_gameplay_collaborators() -> void:
	var model := BoardModel.new()

	assert_not_null(model.state)
	assert_not_null(model.events)
	assert_not_null(model.scripting)
	assert_not_null(model.radial_abilities)
	assert_not_null(model.action_pacer)
	assert_null(model.map_model)
	assert_null(model.abilities)
	assert_null(model.observers)
	assert_null(model.ai)
	assert_null(model.collateral)


func _make_model_with_players() -> BoardModel:
	var model := BoardModel.new()
	model.add_player({
		"type": State.PLAYER_HUMAN,
		"side": "blue",
		"alive": true,
		"team": 0,
		"ap": 3,
	})
	model.add_player({
		"type": State.PLAYER_AI,
		"side": "red",
		"alive": true,
		"team": 1,
		"ap": 2,
	})
	return model


func test_add_player_initializes_state_ap_and_team() -> void:
	var model := _make_model_with_players()

	assert_eq(model.get_current_side(), "blue")
	assert_eq(model.get_current_ap(), 3)
	assert_eq(model.get_player_team("blue"), 0)
	assert_eq(model.get_player_team("red"), 1)


func test_use_and_add_current_player_ap_delegate_to_state() -> void:
	var model := _make_model_with_players()

	model.use_current_player_ap(5)
	assert_eq(model.get_current_ap(), 0)
	assert_true(model.state.has_player_moved)

	model.add_current_player_ap(4)
	assert_eq(model.get_current_ap(), 4)


func test_end_turn_switches_to_next_player() -> void:
	var model := _make_model_with_players()

	model.end_turn()

	assert_eq(model.state.current_player, 1)
	assert_eq(model.get_current_side(), "red")


func test_attach_board_creates_board_dependent_collaborators() -> void:
	var board := Board.new()
	board.map = Map.new()
	var model := BoardModel.new()
	board.events = model.events

	model.attach_board(board)

	assert_same(model.board, board)
	assert_same(model.map_model, board.map.model)
	assert_not_null(model.command_context)
	assert_same(model.command_context.state, model.state)
	assert_same(model.command_context.map_model, board.map.model)
	assert_same(model.command_context.events, model.events)
	assert_same(model.command_context.abilities, model.abilities)
	assert_same(model.command_context.collateral, model.collateral)
	assert_same(model.abilities.state, model.state)
	assert_not_null(model.observers)
	assert_same(model.ai.board, board)
	assert_same(model.collateral.model, model)
	board.map.free()
	board.free()
