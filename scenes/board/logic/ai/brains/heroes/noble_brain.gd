extends HeroBrain
class_name NobleBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, _board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)
    var ability: ActiveHeroAbility = unit.active_abilities[0]

    if not unit.has_moves():
        return []
    if ability.ap_cost > ap or ability.is_on_cooldown():
        return []

    var path: Array[String]
    var actions: Array[AbstractAction] = []
    var action: MoveAction
    var action_value: int
    var tiles_visited: Array[MapTile] = []
    var target_tile: MapTile
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap


    for friendly_unit_tile: String in self.pathfinder.own_units:
        target_tile = self.pathfinder.own_units[friendly_unit_tile]
        var target_unit: BaseUnit = self._get_unit(target_tile)

        if target_unit == unit:
            continue

        for neighbour: MapTile in target_tile.neighbours.values():
            if tiles_visited.has(neighbour):
                continue
            tiles_visited.append(neighbour)
            if not neighbour.can_acommodate_unit(unit):
                continue
            path = self.pathfinder.get_path_to_tile(neighbour)
            if path.size() - 1 < unit_range:
                action_value = _calculate_support_value(unit, neighbour)
                if action_value >= 50:
                    action = self._move_action(entity_tile, path, unit_range - 1)
                    action.value = action_value
                    actions.append(action)

    action_value = _calculate_support_value(unit, entity_tile)
    if action_value >= 50:
        var ability_action: UseAbilityAction = self._ability_action(ability, entity_tile)
        ability.active_source_tile = entity_tile
        ability_action.delay = 0.5
        ability_action.value = action_value
        actions.append(ability_action)

    return actions

func _calculate_support_value(source: BaseUnit, target_tile: MapTile) -> int:
    var final_value: int = 0

    for tile: MapTile in target_tile.neighbours.values():
        if tile.has_friendly_unit(source.side) and tile.neighbours_enemy_unit(source.side, source.team):
            var unit: BaseUnit = self._get_unit(tile)
            if unit != source:
                final_value += unit.get_value()
                if unit.attacks > 0:
                    final_value += 20

    return final_value
