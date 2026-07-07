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
            board._present_destroyed_unit(tile, false, source)

    board.explode_a_tile(tile)
    source.activate_all_cooldowns(board)
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

    self._append_tile_effect(result, "smoke", origin_tile)
    self._append_projectile_effect(result, "lob_projectile", origin_tile, tile, self.TWEEN_TIME)
    self._append_tile_effect(result, "explode", tile)
    result.metadata["refresh_selection"] = true
    result.delay = self.TWEEN_TIME

    for active_ability: Ability in source.active_abilities:
        source.get_ability_state(active_ability).activate_cooldown_model(active_ability, model.abilities, source)

    return result

func _is_visible(_board: Board, source: Variant = null) -> bool:
    if source == null:
        return false

    return source.level >= self.min_level and source.level <= self.max_level

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team) and not tile.is_neighbour(origin_tile)
