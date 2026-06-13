extends ActiveUnitAbility

const TWEEN_TIME := 0.1

@export var damage: int = 10

func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    if tile.unit.is_present():
        tile.unit.tile.receive_damage(self.damage)
    source.sfx_effect("attack")

    board.shoot_projectile(origin_tile, tile, self.TWEEN_TIME)
    await board.get_tree().create_timer(self.TWEEN_TIME).timeout
    
    if tile.unit.is_present():
        var target_unit: BaseUnit = tile._get_unit()
        target_unit.sfx_effect("damage")
        if not target_unit.is_alive():
            var unit_id: int = target_unit.get_instance_id()
            var unit_type: String = target_unit.template_name
            var unit_side: String = target_unit.side
            board.events.emit_unit_destroyed(source, unit_id, unit_type, unit_side)
            board.destroy_unit_on_tile(tile)

    board.explode_a_tile(tile)
    board.refresh_tile_selection()

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team) and source.can_attack(tile._get_unit()) and (tile.position.x == origin_tile.position.x or tile.position.y == origin_tile.position.y)
