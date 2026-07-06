class_name BoardView


var board: Variant = null


func _init(board_host: Variant = null) -> void:
	self.board = board_host


func unselect_tile() -> void:
	if self.board == null:
		return
	self.board.unselect_tile()


func cancel_ability() -> void:
	if self.board == null:
		return
	self.board.cancel_ability()


func show_contextual_select(open_unit_abilities: bool = false) -> void:
	if self.board == null:
		return
	self.board.show_contextual_select(open_unit_abilities)


func hover_tile() -> void:
	if self.board == null:
		return
	self.board.hover_tile()


func play_tile_selected_feedback() -> void:
	if self.board == null:
		return
	self.board.play_tile_selected_feedback()
