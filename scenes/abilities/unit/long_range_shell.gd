extends ActiveUnitAbility

const TWEEN_TIME := 0.1

@export var damage: int = 10

func _execute(board: Board, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    if tile.unit.is_present():
        tile.unit.get_map_object().receive_damage(self.damage)
    self.source.sfx_effect("attack")

    board.shoot_projectile(self.active_source_tile, tile, self.TWEEN_TIME)
    await self.get_tree().create_timer(self.TWEEN_TIME).timeout
    
    if tile.unit.is_present():
        var target_unit: BaseUnit = tile._get_unit()
        target_unit.sfx_effect("damage")
        if not target_unit.is_alive():
            var unit_id: int = target_unit.get_instance_id()
            var unit_type: String = target_unit.template_name
            var unit_side: String = target_unit.side
            board.events.emit_unit_destroyed(self.source, unit_id, unit_type, unit_side)
            board.destroy_unit_on_tile(tile)

    board.explode_a_tile(tile)
    board.refresh_tile_selection()

func is_tile_applicable(tile: MapTile, source_tile: MapTile) -> bool:
    return tile.has_enemy_unit(self.source.side, self.source.team) and self.source.can_attack(tile._get_unit()) and (tile.position.x == source_tile.position.x or tile.position.y == source_tile.position.y)
