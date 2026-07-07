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
            board._present_destroyed_unit(tile, false, source)

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
            if model.collateral != null:
                model.collateral.apply_destroyed_unit_collateral(tile)
            self._append_destroyed_tile(result, tile)
    self._append_projectile_effect(result, "shoot_projectile", origin_tile, tile, self.TWEEN_TIME)
    self._append_tile_effect(result, "explode", tile)
    result.metadata["refresh_selection"] = true
    result.delay = self.TWEEN_TIME
    return result

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team) and source.can_attack_unit(tile._get_unit()) and (tile.position.x == origin_tile.position.x or tile.position.y == origin_tile.position.y)
