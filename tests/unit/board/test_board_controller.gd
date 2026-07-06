extends GutTest


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
