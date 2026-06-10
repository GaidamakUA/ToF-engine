extends ActiveUnitAbility

const TWEEN_TIME := 0.1

@export var damage: int = 8

func _execute(board: Board, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    if tile.unit.is_present():
        tile.unit.get_map_object().receive_damage(self.damage)
    self.source.sfx_effect("ab_attack")

    board.shoot_projectile(self.active_source_tile, tile, self.TWEEN_TIME)
    await self.get_tree().create_timer(self.TWEEN_TIME).timeout
    
    self.source.sfx_effect("ab_hit")
    if tile.unit.is_present():
        var target_unit: BaseUnit = tile.unit.get_unit()
        if not target_unit.is_alive():
            var unit_id: int = target_unit.get_instance_id()
            var unit_type: String = target_unit.template_name
            var unit_side: String = target_unit.side
            board.events.emit_unit_destroyed(self.source, unit_id, unit_type, unit_side)
            board.destroy_unit_on_tile(tile)

    board.explode_a_tile(tile)
    board.refresh_tile_selection()

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
    return tile.has_enemy_unit(self.source.side, self.source.team)
