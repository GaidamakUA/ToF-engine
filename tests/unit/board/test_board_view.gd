extends GutTest


class FakeBoardHost:
	var selected_tile: MapTile = MapTile.new(0, 0)
	var ability_markers := FakeAbilityMarkers.new()
	var ui := FakeUi.new()
	var clear_selection_view_count: int = 0
	var clear_ability_view_count: int = 0
	var place_selection_marker_count: int = 0
	var reset_unit_markers_count: int = 0
	var show_unit_movement_markers_count: int = 0
	var show_unit_interaction_markers_count: int = 0
	var contextual_select_radial_args: Array[bool] = []
	var hover_count: int = 0
	var feedback_count: int = 0

	func clear_selection_view() -> void:
		self.clear_selection_view_count += 1

	func clear_ability_view() -> void:
		self.clear_ability_view_count += 1

	func place_selection_marker() -> void:
		self.place_selection_marker_count += 1

	func reset_unit_markers() -> void:
		self.reset_unit_markers_count += 1

	func show_unit_movement_markers() -> void:
		self.show_unit_movement_markers_count += 1

	func show_unit_interaction_markers() -> void:
		self.show_unit_interaction_markers_count += 1

	func _show_contextual_select_radial(open_unit_abilities: bool) -> void:
		self.contextual_select_radial_args.append(open_unit_abilities)

	func hover_tile() -> void:
		self.hover_count += 1

	func play_tile_selected_feedback() -> void:
		self.feedback_count += 1


class FakeAbilityMarkers:
	var calls: Array[Array] = []

	func show_ability_markers_for_tile(ability: Ability, tile: MapTile) -> void:
		self.calls.append([ability, tile])


class FakeUi:
	var resource_values: Array[int] = []
	var hide_resource_count: int = 0

	func update_resource_value(value: int) -> void:
		self.resource_values.append(value)

	func hide_resource() -> void:
		self.hide_resource_count += 1


func test_board_view_delegates_controller_presentation_callbacks() -> void:
	var board := FakeBoardHost.new()
	var view := BoardView.new(board)

	view.unselect_tile()
	view.cancel_ability()
	view.show_contextual_select(true)
	view.hover_tile()
	view.play_tile_selected_feedback()

	assert_eq(board.clear_selection_view_count, 1)
	assert_eq(board.clear_ability_view_count, 1)
	assert_eq(board.place_selection_marker_count, 1)
	assert_eq(board.reset_unit_markers_count, 1)
	assert_eq(board.show_unit_movement_markers_count, 0)
	assert_eq(board.show_unit_interaction_markers_count, 0)
	assert_eq(board.contextual_select_radial_args, [true])
	assert_eq(board.hover_count, 1)
	assert_eq(board.feedback_count, 1)


func test_board_view_shows_ability_markers() -> void:
	var board := FakeBoardHost.new()
	var view := BoardView.new(board)
	var ability := Ability.new()
	var tile := MapTile.new(1, 2)

	view.show_ability_markers(ability, tile)

	assert_eq(board.ability_markers.calls, [[ability, tile]])


func test_board_view_updates_resource_value() -> void:
	var board := FakeBoardHost.new()
	var view := BoardView.new(board)

	view.update_resource_value(7)

	assert_eq(board.ui.resource_values, [7])


func test_board_view_hides_resource() -> void:
	var board := FakeBoardHost.new()
	var view := BoardView.new(board)

	view.hide_resource()

	assert_eq(board.ui.hide_resource_count, 1)
