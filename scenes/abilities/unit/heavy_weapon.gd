extends ActiveUnitAbility

const TWEEN_TIME := 0.1

@export var damage: int = 8

func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    if tile.unit.is_present():
        tile.unit.tile.receive_damage(self.damage)
    source.sfx_effect("ab_attack")

    board.shoot_projectile(origin_tile, tile, self.TWEEN_TIME)
    await board.get_tree().create_timer(self.TWEEN_TIME).timeout
    
    source.sfx_effect("ab_hit")
    if tile.unit.is_present():
        var target_unit: BaseUnit = tile._get_unit()
        if not target_unit.is_alive():
            board.destroy_unit_on_tile(tile, false, source)

    board.explode_a_tile(tile)
    board.refresh_tile_selection()

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)
    if tile.unit.is_present():
        tile.unit.tile.receive_damage(self.damage)
        var target_unit: BaseUnit = tile._get_unit()
        if not target_unit.is_alive():
            result.merge_from(model.destroy_unit_on_tile(tile, source))
    self._append_projectile_effect(result, "shoot_projectile", origin_tile, tile, self.TWEEN_TIME)
    self._append_tile_effect(result, "explode", tile)
    result.metadata["refresh_selection"] = true
    result.delay = self.TWEEN_TIME
    return result

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team)
