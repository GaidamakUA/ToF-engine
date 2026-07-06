extends GutTest


func test_command_result_collects_events_and_delay() -> void:
	var result := CommandResult.new("move_unit")
	var event := UnitMovedEvent.new()

	result.add_event(event)
	result.delay = 0.25

	assert_eq(result.command_name, "move_unit")
	assert_eq(result.events, [event])
	assert_eq(result.delay, 0.25)


func test_no_op_pacer_returns_without_tree_or_board() -> void:
	var pacer := NoOpActionPacer.new()
	var result := CommandResult.new("move_unit")

	await pacer.wait_after(result)

	assert_true(true)


func test_board_model_can_own_map_model_without_board() -> void:
	var model := BoardModel.new()
	var map_model := MapModel.new()
	var tile := MapTile.new(1, 2)
	map_model.tiles["1_2"] = tile

	model.set_map_model(map_model)

	assert_same(model.get_tile_at(Vector2i(1, 2)), tile)
	assert_null(model.board)
	assert_not_null(model.command_context)
	assert_same(model.command_context.state, model.state)
	assert_same(model.command_context.map_model, map_model)
	assert_same(model.command_context.events, model.events)
