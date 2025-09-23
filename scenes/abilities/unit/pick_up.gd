extends ActiveUnitAbility

func _execute(board: Board, position: Vector2i) -> void:
	var tile := board.map.model.get_tile(position)
	tile.unit.tile.sfx_effect("move")
	
	self.source.passenger = tile.unit.tile
	tile.unit.release()
	board.map.detach_unit(self.source.passenger)

	board.smoke_a_tile(tile)
	self.source.use_all_moves()

func _is_visible(_board: Board) -> bool:
	if self.source == null:
		return false

	if self.source.passenger != null:
		return false

	return true

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
	var applicable_types := ["infantry"]
	if self.source.level == 3:
		applicable_types.append("mobile_infantry")
	if tile.has_friendly_unit(self.source.side):
		return tile.unit.tile.unit_class in applicable_types
	return false
