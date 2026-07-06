extends GutTest


class FakeBoardHost:
	var unselect_count: int = 0
	var cancel_ability_count: int = 0
	var show_contextual_select_args: Array[bool] = []
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


func test_board_view_delegates_controller_presentation_callbacks() -> void:
	var board := FakeBoardHost.new()
	var view := BoardView.new(board)

	view.unselect_tile()
	view.cancel_ability()
	view.show_contextual_select(true)
	view.hover_tile()
	view.play_tile_selected_feedback()

	assert_eq(board.unselect_count, 1)
	assert_eq(board.cancel_ability_count, 1)
	assert_eq(board.show_contextual_select_args, [true])
	assert_eq(board.hover_count, 1)
	assert_eq(board.feedback_count, 1)
