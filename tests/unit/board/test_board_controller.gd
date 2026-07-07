extends GutTest


class FakeBoardModel:
	extends BoardModel

	var tiles: Dictionary[Vector2i, MapTile] = {}
	var selectable_tiles: Array[MapTile] = []
	var movable_tiles: Array[MapTile] = []
	var ability_marker_tiles: Array[MapTile] = []
	var current_player_ai: bool = false
	var moved_units: Array[Array] = []
	var attack_calls: Array[Array] = []
	var capture_calls: Array[Array] = []
	var ability_calls: Array[Array] = []
	var next_ability_result: CommandResult = CommandResult.new("use_ability")

	func add_tile(tile: MapTile) -> void:
		self.tiles[tile.position] = tile

	func get_tile_at(tile_position: Vector2i) -> MapTile:
		return self.tiles.get(tile_position)

	func is_tile_selectable_for_current_player(tile: MapTile) -> bool:
		return self.selectable_tiles.has(tile)

	func has_active_ability_target_marker(tile: MapTile) -> bool:
		return self.ability_marker_tiles.has(tile)

	func is_current_player_ai() -> bool:
		return self.current_player_ai

	func can_move_to_tile_from_source(_source_tile: MapTile, tile: MapTile, _move_cost: int) -> bool:
		return self.movable_tiles.has(tile)

	func move_unit(source_tile: MapTile, destination_tile: MapTile) -> CommandResult:
		self.moved_units.append([source_tile, destination_tile])
		return CommandResult.new("move_unit")

	func can_current_player_afford(_amount: int) -> bool:
		return true

	func attack_unit(source_tile: MapTile, target_tile: MapTile) -> CommandResult:
		self.attack_calls.append([source_tile, target_tile])
		return CommandResult.new("attack_unit")

	func capture_building(source_tile: MapTile, target_tile: MapTile) -> CommandResult:
		self.capture_calls.append([source_tile, target_tile])
		return CommandResult.new("capture_building")

	func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> CommandResult:
		self.ability_calls.append([origin_tile, ability, target_tile])
		return self.next_ability_result


class FakeBoardHost:
	var last_unit_move_values: Array[Variant] = []
	var presented_ability_results: Array[CommandResult] = []
	var selected_positions: Array[Vector2i] = []
	var interactable_tiles: Array[MapTile] = []
	var presented_attack_results: Array[CommandResult] = []
	var presented_capture_results: Array[CommandResult] = []

	func _set_last_unit_move(value: Variant) -> void:
		self.last_unit_move_values.append(value)

	func _present_ability_result(result: CommandResult) -> void:
		self.presented_ability_results.append(result)

	func _present_attack_result(result: CommandResult) -> void:
		self.presented_attack_results.append(result)

	func _present_capture_result(result: CommandResult) -> void:
		self.presented_capture_results.append(result)

	func select_tile(tile_position: Vector2i) -> void:
		self.selected_positions.append(tile_position)


class FakeBoardView:
	extends BoardView

	var show_contextual_select_args: Array[bool] = []
	var movable_tiles: Array[MapTile] = []
	var moved_units: Array[Array] = []
	var move_result: bool = false
	var unselect_count: int = 0
	var cancel_ability_count: int = 0
	var hover_count: int = 0
	var feedback_count: int = 0

	func can_move_to_tile(tile: MapTile) -> bool:
		return self.movable_tiles.has(tile)

	func move_unit_from_marker_path(source_tile: MapTile, destination_tile: MapTile) -> bool:
		self.moved_units.append([source_tile, destination_tile])
		return self.move_result

	func unselect_tile() -> void:
		self.unselect_count += 1

	func cancel_ability() -> void:
		self.cancel_ability_count += 1

	func show_contextual_select(open_unit_abilities: bool = false) -> void:
		self.show_contextual_select_args.append(open_unit_abilities)

	func hover_tile() -> void:
		self.hover_count += 1

	func play_tile_selected_feedback() -> void:
		self.feedback_count += 1


func _make_controller_with_hosts(model: FakeBoardModel, view: FakeBoardView, board: FakeBoardHost = null) -> BoardController:
	var controller := BoardController.new(model)
	controller.attach_view(view)
	if board != null:
		controller.attach_board(board)
	return controller


func test_new_controller_starts_with_empty_interaction_state() -> void:
	var model := BoardModel.new()
	var controller := BoardController.new(model)

	assert_same(controller.model, model)
	assert_null(controller.selected_tile)
	assert_null(controller.active_ability)
	assert_null(controller.active_ability_origin_tile)


func test_clear_selection_keeps_active_ability_targeting_state() -> void:
	var controller := BoardController.new(BoardModel.new())
	var selected_tile := MapTile.new(1, 2)
	var origin_tile := MapTile.new(3, 4)
	var ability := Ability.new()

	controller.select_tile(selected_tile)
	controller.start_ability_targeting(origin_tile, ability)

	controller.clear_selection()

	assert_null(controller.selected_tile)
	assert_same(controller.active_ability, ability)
	assert_same(controller.active_ability_origin_tile, origin_tile)


func test_cancel_ability_clears_targeting_state() -> void:
	var controller := BoardController.new(BoardModel.new())
	var origin_tile := MapTile.new(3, 4)
	var ability := Ability.new()

	controller.start_ability_targeting(origin_tile, ability)

	controller.cancel_ability()

	assert_null(controller.active_ability)
	assert_null(controller.active_ability_origin_tile)


func test_board_interaction_state_delegates_to_controller() -> void:
	var board := Board.new()
	var selected_tile := MapTile.new(1, 2)
	var origin_tile := MapTile.new(3, 4)
	var ability := Ability.new()

	board.selected_tile = selected_tile
	board.active_ability = ability
	board.active_ability_origin_tile = origin_tile

	assert_not_null(board.controller)
	assert_same(board.selected_tile, selected_tile)
	assert_same(board.controller.selected_tile, selected_tile)
	assert_same(board.active_ability, ability)
	assert_same(board.controller.active_ability, ability)
	assert_same(board.active_ability_origin_tile, origin_tile)
	assert_same(board.controller.active_ability_origin_tile, origin_tile)
	board.free()


func test_press_tile_selects_current_player_tile() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var tile := MapTile.new(1, 2)
	model.add_tile(tile)
	model.selectable_tiles.append(tile)
	var controller := _make_controller_with_hosts(model, view, board)

	controller.press_tile(tile.position)

	assert_same(controller.selected_tile, tile)
	assert_eq(view.show_contextual_select_args, [false])
	assert_eq(view.hover_count, 1)
	assert_eq(view.feedback_count, 1)


func test_press_selected_tile_opens_unit_abilities() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var tile := MapTile.new(1, 2)
	model.add_tile(tile)
	model.selectable_tiles.append(tile)
	var controller := _make_controller_with_hosts(model, view, board)
	controller.select_tile(tile)

	controller.press_tile(tile.position)

	assert_same(controller.selected_tile, tile)
	assert_eq(view.show_contextual_select_args, [true])


func test_press_reachable_tile_routes_move_and_selects_destination() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var source_tile := MapTile.new(1, 2)
	var destination_tile := MapTile.new(2, 2)
	model.add_tile(destination_tile)
	model.movable_tiles.append(destination_tile)
	var controller := _make_controller_with_hosts(model, view, board)
	controller.select_tile(source_tile)

	controller.press_tile(destination_tile.position)

	assert_eq(board.last_unit_move_values, [null])
	assert_eq(model.moved_units, [[source_tile, destination_tile]])
	assert_same(controller.selected_tile, destination_tile)
	assert_eq(view.show_contextual_select_args, [false])
	assert_eq(view.feedback_count, 1)


func test_press_marker_move_failure_keeps_selection_and_skips_destination_context() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var source_tile := MapTile.new(1, 2)
	var destination_tile := MapTile.new(2, 2)
	model.add_tile(destination_tile)
	view.movable_tiles.append(destination_tile)
	view.move_result = false
	var controller := _make_controller_with_hosts(model, view, board)
	controller.select_tile(source_tile)

	controller.press_tile(destination_tile.position)

	assert_eq(board.last_unit_move_values, [null])
	assert_eq(view.moved_units, [[source_tile, destination_tile]])
	assert_true(model.moved_units.is_empty())
	assert_same(controller.selected_tile, source_tile)
	assert_true(view.show_contextual_select_args.is_empty())
	assert_eq(view.feedback_count, 1)


func test_press_interactable_tile_routes_interaction() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var source_tile := MapTile.new(1, 2)
	var target_tile := MapTile.new(1, 3)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.move = 1
	attacker.max_move = 1
	defender.side = "red"
	defender.team = 1
	source_tile.unit.set_tile(attacker)
	target_tile.unit.set_tile(defender)
	source_tile.add_neighbour(MapTile.NORTH, target_tile)
	model.add_tile(target_tile)
	var controller := _make_controller_with_hosts(model, view, board)
	controller.select_tile(source_tile)

	controller.press_tile(target_tile.position)

	assert_eq(board.last_unit_move_values, [null])
	assert_eq(model.attack_calls, [[source_tile, target_tile]])
	assert_eq(board.presented_attack_results.size(), 1)
	assert_eq(board.presented_attack_results[0].command_name, "attack_unit")
	assert_same(controller.selected_tile, source_tile)

	source_tile.unit.release()
	target_tile.unit.release()
	attacker.free()
	defender.free()


func test_press_invalid_ability_target_clears_selection() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var target_tile := MapTile.new(1, 3)
	model.add_tile(target_tile)
	var controller := _make_controller_with_hosts(model, view, board)
	controller.start_ability_targeting(MapTile.new(1, 2), Ability.new())

	controller.press_tile(target_tile.position)

	assert_eq(view.unselect_count, 1)
	assert_true(model.ability_calls.is_empty())


func test_press_valid_ability_target_executes_model_command_and_presentation() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var board := FakeBoardHost.new()
	var origin_tile := MapTile.new(1, 2)
	var target_tile := MapTile.new(1, 3)
	var ability := Ability.new()
	var result := CommandResult.new("use_ability")
	result.metadata["select_tile_position"] = Vector2i(2, 4)
	model.next_ability_result = result
	model.add_tile(target_tile)
	model.ability_marker_tiles.append(target_tile)
	var controller := _make_controller_with_hosts(model, view, board)
	controller.start_ability_targeting(origin_tile, ability)

	controller.press_tile(target_tile.position)

	assert_eq(model.ability_calls, [[origin_tile, ability, target_tile]])
	assert_eq(board.presented_ability_results, [result])
	assert_eq(view.cancel_ability_count, 1)
	assert_eq(board.selected_positions, [Vector2i(2, 4)])
	assert_null(controller.active_ability)
	assert_null(controller.active_ability_origin_tile)


func test_cancel_interaction_routes_to_ability_cancel_when_targeting() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var controller := _make_controller_with_hosts(model, view)
	controller.start_ability_targeting(MapTile.new(1, 2), Ability.new())

	controller.cancel_interaction()

	assert_null(controller.active_ability)
	assert_null(controller.active_ability_origin_tile)
	assert_eq(view.cancel_ability_count, 1)
	assert_eq(view.unselect_count, 0)


func test_cancel_interaction_routes_to_tile_unselect_without_active_ability() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var controller := _make_controller_with_hosts(model, view)
	var selected_tile := MapTile.new(1, 2)
	controller.select_tile(selected_tile)

	controller.cancel_interaction()

	assert_null(controller.selected_tile)
	assert_eq(view.cancel_ability_count, 0)
	assert_eq(view.unselect_count, 1)


func test_press_tile_can_run_with_null_view() -> void:
	var model := FakeBoardModel.new()
	var tile := MapTile.new(1, 2)
	model.add_tile(tile)
	model.selectable_tiles.append(tile)
	var controller := BoardController.new(model)

	controller.press_tile(tile.position)

	assert_same(controller.selected_tile, tile)
