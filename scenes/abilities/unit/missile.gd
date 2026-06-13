extends ActiveUnitAbility

const TWEEN_TIME := 0.5

@export var damage: int = 10
@export var min_level: int = 0
@export var max_level: int = 3

func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)

    if tile.unit.is_present():
        tile.unit.tile.receive_damage(self.damage)
    source.sfx_effect("attack")

    board.smoke_a_tile(origin_tile)
    board.lob_projectile(origin_tile, tile, self.TWEEN_TIME)
    await board.get_tree().create_timer(self.TWEEN_TIME).timeout
    
    source.sfx_effect("hit")
    if tile.unit.is_present():
        var target_unit: BaseUnit = tile._get_unit()
        if not target_unit.is_alive():
            var unit_id: int = target_unit.get_instance_id()
            var unit_type: String = target_unit.template_name
            var unit_side: String = target_unit.side
            board.events.emit_unit_destroyed(source, unit_id, unit_type, unit_side)
            board.destroy_unit_on_tile(tile)

    board.explode_a_tile(tile)
    source.activate_all_cooldowns(board)
    board.refresh_tile_selection()

func _is_visible(_board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    return source.level >= self.min_level and source.level <= self.max_level

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team) and not tile.is_neighbour(origin_tile)
