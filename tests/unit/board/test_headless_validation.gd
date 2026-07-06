extends GutTest


func test_headless_fixture_can_move_unit_and_emit_event() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var destination: MapTile = scenario.get_tile(Vector2i(1, 0))

	var result := scenario.model.move_unit_along_path(source, destination, 1, ["0_0", "1_0"])

	assert_false(source.unit.is_present())
	assert_true(destination.unit.is_present())
	assert_eq(destination.unit.tile.side, "blue")
	assert_eq(destination.unit.tile.move, 3)
	assert_eq(scenario.model.get_current_ap(), 3)
	assert_eq(result.command_name, "move_unit")
	assert_eq(result.events.size(), 1)
	assert_eq(scenario.moved_events.size(), 1)
	assert_eq(scenario.moved_events[0].start, source)
	assert_eq(scenario.moved_events[0].finish, destination)

	scenario.cleanup()


func test_headless_fixture_can_switch_turns() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")

	assert_eq(scenario.model.get_current_side(), "blue")
	assert_false(scenario.model.is_current_player_ai())

	scenario.model.end_turn()

	assert_eq(scenario.model.get_current_side(), "red")
	assert_true(scenario.model.is_current_player_ai())

	scenario.cleanup()


func test_headless_fixture_restore_starts_from_original_state() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	scenario.model.move_unit_along_path(
		scenario.get_tile(Vector2i(0, 0)),
		scenario.get_tile(Vector2i(1, 0)),
		1,
		["0_0", "1_0"]
	)
	scenario.cleanup()

	var restored := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")

	assert_true(restored.get_tile(Vector2i(0, 0)).unit.is_present())
	assert_false(restored.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(restored.get_tile(Vector2i(0, 0)).unit.tile.move, 4)
	assert_eq(restored.model.get_current_ap(), 4)

	restored.cleanup()


func test_ai_move_action_runs_without_board_scene() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var destination: MapTile = scenario.get_tile(Vector2i(1, 0))
	var action := MoveAction.new(source, destination, ["0_0", "1_0"])

	await action.perform(scenario.model)

	assert_false(source.unit.is_present())
	assert_true(destination.unit.is_present())
	assert_eq(scenario.model.get_current_ap(), 3)
	assert_eq(scenario.moved_events.size(), 1)

	await wait_process_frames(1)
	scenario.cleanup()


func test_capture_action_runs_without_board_scene() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var interaction: MapTile = scenario.get_tile(Vector2i(1, 0))
	var target: MapTile = scenario.get_tile(Vector2i(2, 0))
	var action := CaptureAction.new(source, interaction, target, ["0_0", "1_0"])

	await action.perform(scenario.model)

	assert_false(source.unit.is_present())
	assert_true(interaction.unit.is_present())
	assert_eq(target.building.tile.side, "blue")
	assert_eq(target.building.tile.team, 0)
	assert_eq(scenario.model.get_current_ap(), 2)
	assert_eq(scenario.moved_events.size(), 1)
	assert_eq(scenario.captured_events.size(), 1)
	assert_eq(scenario.captured_events[0].old_side, "red")
	assert_eq(scenario.captured_events[0].new_side, "blue")

	scenario.cleanup()


func test_headless_host_dispatches_reserve_ap_and_ability_commands() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var origin: MapTile = scenario.get_tile(Vector2i(0, 0))
	var target: MapTile = scenario.get_tile(Vector2i(2, 0))
	var ability := Ability.new()

	scenario.model.reserve_ap(2)
	scenario.model.use_ability(origin, ability, target)

	assert_eq(scenario.reserved_ap, [2])
	assert_eq(scenario.used_abilities.size(), 1)
	assert_eq(scenario.used_abilities[0].origin, origin)
	assert_eq(scenario.used_abilities[0].ability, ability)
	assert_eq(scenario.used_abilities[0].target, target)

	scenario.cleanup()
