class_name BoardView


var board: Variant = null


func _init(board_host: Variant = null) -> void:
	self.board = board_host


func unselect_tile() -> void:
	if self.board == null:
		return
	self.board.clear_selection_view()


func cancel_ability() -> void:
	if self.board == null:
		return
	self.board.clear_ability_view()


func show_contextual_select(open_unit_abilities: bool = false) -> void:
	if self.board == null:
		return
	self.board.place_selection_marker()
	self.board.reset_unit_markers()

	if self.board.selected_tile.unit.is_present():
		self.board.show_unit_movement_markers()
		self.board.show_unit_interaction_markers()
	self.board._show_contextual_select_radial(open_unit_abilities)


func show_ability_markers(ability: Ability, tile: MapTile) -> void:
	if self.board == null:
		return
	self.board.ability_markers.show_ability_markers_for_tile(ability, tile)


func hover_tile() -> void:
	if self.board == null:
		return
	self.board.hover_tile()


func play_tile_selected_feedback() -> void:
	if self.board == null:
		return
	self.board.play_tile_selected_feedback()
