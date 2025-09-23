extends ActiveUnitAbility

func _execute(board: Board, position: Vector2i):
	var tile = board.map.model.get_tile(position)
	tile.unit.set_tile(self.source.passenger)
	board.map.anchor_unit(self.source.passenger, position)
	tile.unit.tile.sfx_effect("move")
	
	self.source.passenger.remove_moves()
	self.source.passenger = null

	board.smoke_a_tile(tile)

func _is_visible(_board=null):
	if self.source == null:
		return false

	if self.source.passenger == null:
		return false

	return true

func is_tile_applicable(tile, _source_tile):
	return tile.can_acommodate_unit()
