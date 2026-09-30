extends HeroBrain
class_name GeneralBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, model: BoardModel) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)
    var ability: ActiveHeroAbility = unit.active_abilities[0]

    if not unit.has_moves():
        return []
    if ability.ap_cost > ap or unit.is_ability_on_cooldown(ability):
        return []

    var actions: Array[AbstractAction] = []

    for position: Vector2i in model.get_legal_ability_targets(entity_tile.position, ability.get_key()):
        var tile: MapTile = model._get_tile_at(position)
        var action: UseAbilityAction = self._ability_action(ability, entity_tile, tile)
        action.delay = 0.5
        action.value = _calculate_drop_value(unit, tile)
        actions.append(action)

    return actions

func _calculate_drop_value(source: BaseUnit, target_tile: MapTile) -> int:
    var final_value: int = 40

    if target_tile.neighbours_enemy_unit(source.side, source.team):
        final_value -= 10
    if target_tile.neighbours_enemy_building(source.side, source.team):
        final_value += 100

    return final_value
