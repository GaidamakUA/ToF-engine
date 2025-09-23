extends ActiveUnitAbility

const TWEEN_TIME := 0.1

@export var damage: int = 8

func _execute(board: Board, position: Vector2i) -> void:
	var tile := board.map.model.get_tile(position)
	if tile.unit.is_present():
		tile.unit.tile.receive_damage(self.damage)
	self.source.sfx_effect("ab_attack")

	board.shoot_projectile(self.active_source_tile, tile, self.TWEEN_TIME)
	await self.get_tree().create_timer(self.TWEEN_TIME).timeout
	
	self.source.sfx_effect("ab_hit")
	if tile.unit.is_present():
		if not tile.unit.tile.is_alive():
			var unit_id: int = tile.unit.tile.get_instance_id()
			var unit_type: String = tile.unit.tile.template_name
			var unit_side: String = tile.unit.tile.side
			board.events.emit_unit_destroyed(self.source, unit_id, unit_type, unit_side)
			board.destroy_unit_on_tile(tile)

	board.explode_a_tile(tile)
	board.refresh_tile_selection()

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
	return tile.has_enemy_unit(self.source.side, self.source.team)
