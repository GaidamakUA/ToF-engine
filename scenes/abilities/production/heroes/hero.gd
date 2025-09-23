extends SpawnUnit

func _is_visible(board: Board) -> bool:
	if self.source == null:
		return false

	if board == null:
		return false

	if board.state.has_side_a_hero(self.source.side):
		return false

	return true
