extends GutTest


class FakeBoardModel:
	extends BoardModel

	var tiles: Dictionary[Vector2i, MapTile] = {}
	var selectable_tiles: Array[MapTile] = []
	var movable_tiles: Array[MapTile] = []
	var interactable_tiles: Array[MapTile] = []
	var ability_marker_tiles: Array[MapTile] = []
	var current_player_ai: bool = false
	var last_unit_move_values: Array[Variant] = []
	var executed_ability_targets: Array[MapTile] = []
	var moved_units: Array[Array] = []
	var handled_interactions: Array[MapTile] = []

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

	func set_last_unit_move(value: Variant) -> void:
		self.last_unit_move_values.append(value)

	func execute_active_ability(tile: MapTile) -> void:
		self.executed_ability_targets.append(tile)

	func can_move_to_tile(tile: MapTile) -> bool:
		return self.movable_tiles.has(tile)

	func selected_unit_can_interact_with(tile: MapTile) -> bool:
		return self.interactable_tiles.has(tile)

	func move_unit(source_tile: MapTile, destination_tile: MapTile) -> void:
		self.moved_units.append([source_tile, destination_tile])

	func handle_interaction(tile: MapTile) -> void:
		self.handled_interactions.append(tile)


class FakeBoardView:
	extends BoardView

	var show_contextual_select_args: Array[bool] = []
	var unselect_count: int = 0
	var cancel_ability_count: int = 0
	var hover_count: int = 0
	var feedback_count: int = 0

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


func _make_controller_with_hosts(model: FakeBoardModel, view: FakeBoardView) -> BoardController:
	var controller := BoardController.new(model)
	controller.attach_view(view)
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
	var tile := MapTile.new(1, 2)
	model.add_tile(tile)
	model.selectable_tiles.append(tile)
	var controller := _make_controller_with_hosts(model, view)

	controller.press_tile(tile.position)

	assert_same(controller.selected_tile, tile)
	assert_eq(view.show_contextual_select_args, [false])
	assert_eq(view.hover_count, 1)
	assert_eq(view.feedback_count, 1)


func test_press_selected_tile_opens_unit_abilities() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var tile := MapTile.new(1, 2)
	model.add_tile(tile)
	model.selectable_tiles.append(tile)
	var controller := _make_controller_with_hosts(model, view)
	controller.select_tile(tile)

	controller.press_tile(tile.position)

	assert_same(controller.selected_tile, tile)
	assert_eq(view.show_contextual_select_args, [true])


func test_press_reachable_tile_routes_move_and_selects_destination() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var source_tile := MapTile.new(1, 2)
	var destination_tile := MapTile.new(2, 2)
	model.add_tile(destination_tile)
	model.movable_tiles.append(destination_tile)
	var controller := _make_controller_with_hosts(model, view)
	controller.select_tile(source_tile)

	controller.press_tile(destination_tile.position)

	assert_eq(model.last_unit_move_values, [null])
	assert_eq(model.moved_units, [[source_tile, destination_tile]])
	assert_same(controller.selected_tile, destination_tile)
	assert_eq(view.show_contextual_select_args, [false])
	assert_eq(view.feedback_count, 1)


func test_press_interactable_tile_routes_interaction() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var source_tile := MapTile.new(1, 2)
	var target_tile := MapTile.new(1, 3)
	model.add_tile(target_tile)
	model.interactable_tiles.append(target_tile)
	var controller := _make_controller_with_hosts(model, view)
	controller.select_tile(source_tile)

	controller.press_tile(target_tile.position)

	assert_eq(model.last_unit_move_values, [null])
	assert_eq(model.handled_interactions, [target_tile])
	assert_same(controller.selected_tile, source_tile)


func test_press_invalid_ability_target_clears_selection() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var target_tile := MapTile.new(1, 3)
	model.add_tile(target_tile)
	var controller := _make_controller_with_hosts(model, view)
	controller.start_ability_targeting(MapTile.new(1, 2), Ability.new())

	controller.press_tile(target_tile.position)

	assert_eq(view.unselect_count, 1)
	assert_true(model.executed_ability_targets.is_empty())


func test_cancel_routes_to_ability_cancel_when_targeting() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var controller := _make_controller_with_hosts(model, view)
	controller.start_ability_targeting(MapTile.new(1, 2), Ability.new())

	controller.cancel()

	assert_eq(view.cancel_ability_count, 1)
	assert_eq(view.unselect_count, 0)


func test_cancel_routes_to_tile_unselect_without_active_ability() -> void:
	var model := FakeBoardModel.new()
	var view := FakeBoardView.new()
	var controller := _make_controller_with_hosts(model, view)

	controller.cancel()

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
