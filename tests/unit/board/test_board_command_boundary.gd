extends GutTest


func test_headless_scenario_exposes_command_services_without_board_host() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")

	assert_null(scenario.model.board)
	assert_not_null(scenario.model.movement_commands)
	assert_not_null(scenario.model.capture_commands)
	assert_not_null(scenario.model.ability_commands)
	assert_not_null(scenario.model.turn_commands)

	var move_result := scenario.model.move_unit_along_path(
		scenario.get_tile(Vector2i(0, 0)),
		scenario.get_tile(Vector2i(1, 0)),
		1,
		["0_0", "1_0"]
	)

	assert_eq(move_result.command_name, "move_unit")
	assert_false(scenario.get_tile(Vector2i(0, 0)).unit.is_present())

	scenario.cleanup()


func test_board_model_no_longer_exposes_board_dependent_command_methods() -> void:
	var model := BoardModel.new()

	assert_false(model.has_method("wait_for_action_delay"))
	assert_false(model.has_method("execute_active_ability"))
	assert_false(model.has_method("set_last_unit_move"))
	assert_false(model.has_method("can_move_to_tile"))
	assert_false(model.has_method("selected_unit_can_interact_with"))
	assert_false(model.has_method("handle_interaction"))
