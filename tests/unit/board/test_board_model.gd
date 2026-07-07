extends GutTest

const SceneTreeActionPacerScript: Script = preload("res://scenes/board/logic/commands/scene_tree_action_pacer.gd")


class FakeMovementLegalityBoard:
	var called: bool = false

	func can_move_to_tile(_tile: MapTile) -> bool:
		self.called = true
		return true


class FakeMovementPresentationBoard:
	var last_unit_move_values: Array[Variant] = []
	var animated_results: Array[CommandResult] = []

	func set_last_unit_move(value: Variant) -> void:
		self.last_unit_move_values.append(value)

	func _animate_unit_move_result(result: CommandResult) -> void:
		self.animated_results.append(result)


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


func _add_walkable_ground(tile: MapTile) -> BaseTile:
	var ground := BaseTile.new()
	tile.ground.set_tile(ground)
	return ground


func test_add_player_initializes_state_ap_and_team() -> void:
	var model := _make_model_with_players()

	assert_eq(model.get_current_side(), "blue")
	assert_eq(model.get_current_ap(), 3)
	assert_eq(model.get_player_team("blue"), 0)
	assert_eq(model.get_player_team("red"), 1)


func test_use_and_add_current_player_ap_delegate_to_state() -> void:
	var model := _make_model_with_players()

	var use_result := model.use_current_player_ap(5)
	assert_eq(model.get_current_ap(), 0)
	assert_true(model.state.has_player_moved)
	assert_eq(use_result.events.size(), 1)
	assert_true(use_result.events[0] is ApChangedEvent)

	var add_result := model.add_current_player_ap(4)
	assert_eq(model.get_current_ap(), 4)
	assert_eq(add_result.events.size(), 1)
	assert_true(add_result.events[0] is ApChangedEvent)


func test_end_turn_switches_to_next_player() -> void:
	var model := _make_model_with_players()

	var result := model.end_turn()

	assert_eq(model.state.current_player, 1)
	assert_eq(model.get_current_side(), "red")
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is TurnEndedEvent)
	assert_true(result.events[1] is TurnStartedEvent)


func test_can_move_to_tile_from_source_uses_movement_commands_without_board() -> void:
	var model := _make_model_with_players()
	var source := MapTile.new(0, 0)
	var destination := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	var ground := BaseTile.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 3
	unit.max_move = 3
	source.unit.set_tile(unit)
	destination.ground.set_tile(ground)

	assert_true(model.can_move_to_tile_from_source(source, destination, 2))
	assert_false(model.can_move_to_tile_from_source(source, destination, 4))

	source.unit.release()
	destination.ground.release()
	unit.free()
	ground.free()


func test_can_move_to_tile_does_not_delegate_to_board() -> void:
	var model := _make_model_with_players()
	var board := FakeMovementLegalityBoard.new()
	model.board = board

	assert_false(model.can_move_to_tile(MapTile.new(1, 0)))
	assert_false(board.called)


func test_move_unit_along_path_returns_result_without_board_presentation_side_effects() -> void:
	var model := _make_model_with_players()
	var board := FakeMovementPresentationBoard.new()
	var source := MapTile.new(0, 0)
	var destination := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	var ground := BaseTile.new()
	var movement_path: Array[String] = ["0_0", "1_0"]
	unit.side = "blue"
	unit.team = 0
	unit.move = 3
	unit.max_move = 3
	source.unit.set_tile(unit)
	destination.ground.set_tile(ground)
	model.board = board

	var result := model.move_unit_along_path(source, destination, 1, movement_path)

	assert_eq(result.command_name, "move_unit")
	assert_true(board.last_unit_move_values.is_empty())
	assert_true(board.animated_results.is_empty())

	destination.unit.release()
	destination.ground.release()
	unit.free()
	ground.free()


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
	assert_not_null(model.combat_commands)
	assert_same(model.abilities.state, model.state)
	assert_not_null(model.observers)
	assert_same(model.ai.board, board)
	assert_same(model.collateral.model, model)
	assert_same(model.action_pacer.get_script(), SceneTreeActionPacerScript)
	board.map.free()
	board.free()


func test_headless_model_keeps_no_op_action_pacer_by_default() -> void:
	var model := BoardModel.new()

	assert_true(model.action_pacer is NoOpActionPacer)


func test_spawn_unit_instantiates_resource_template_without_board() -> void:
	var model := _make_model_with_players()
	model.set_map_model(MapModel.new())
	var target := model.get_tile_at(Vector2i(2, 3))
	var ground := _add_walkable_ground(target)

	var unit := model.spawn_unit(target.position, "blue_tank", 90, "blue")

	assert_not_null(unit)
	assert_same(target.unit.tile, unit)
	assert_eq(unit.template_name, "blue_tank")
	assert_eq(unit.side, "blue")
	assert_eq(unit.current_rotation, 90)
	assert_eq(unit.max_move, 6)
	assert_eq(unit.move, 6)
	assert_false(model.state.has_side_a_hero("blue"))

	target.unit.release()
	ground.free()
	unit.free()


func test_spawn_unit_registers_hero_without_board() -> void:
	var model := _make_model_with_players()
	model.set_map_model(MapModel.new())
	var target := model.get_tile_at(Vector2i(4, 5))
	var ground := _add_walkable_ground(target)

	var hero := model.spawn_unit(target.position, "hero_prince", 0, "blue")

	assert_true(hero is HeroUnit)
	assert_same(target.unit.tile, hero)
	assert_true(model.state.has_side_a_hero("blue"))
	assert_eq(model.state.get_heroes_for_side("blue"), [hero])

	target.unit.release()
	ground.free()
	hero.free()
