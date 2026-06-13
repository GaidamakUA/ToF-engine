extends AbstractUnitBrain
class_name ScoutBrain

func _gather_ability_actions(entity_tile: MapTile, _ap: int, _board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)

    if not unit.has_moves():
        return []

    if not unit.has_active_ability():
        return []

    if unit.attacks > 0 and unit.move > 1:
        return []

    if self.pathfinder.enemy_units.size() < 1:
        return []

    var actions: Array[AbstractAction] = []

    for ability: ActiveUnitAbility in unit.active_abilities:
        if unit.is_ability_visible(ability) and not unit.is_ability_on_cooldown(ability):
            var action: UseAbilityAction = self._ability_action(ability, entity_tile, entity_tile)
            action.delay = 0.5
            action.value = 50
            actions.append(action)

    return actions
