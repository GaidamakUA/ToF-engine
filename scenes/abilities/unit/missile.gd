extends ActiveUnitAbility

@export var damage: int = 10
@export var min_level: int = 0
@export var max_level: int = 3

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    if not model.damage_unit(position, self.damage, false, source.model_id):
        return []
    for ability: Ability in source.active_abilities:
        var state: AbilityState = source.get_ability_state(ability)
        state.cd_turns_left = model.abilities.get_modified_cooldown(ability.get_cooldown(source), source)
    return [position]

func _is_visible(_model: BoardModel, source: Variant = null) -> bool:
    if source == null:
        return false

    return source.level >= self.min_level and source.level <= self.max_level

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team) and not tile.is_neighbour(origin_tile)
