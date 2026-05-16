extends HeroBrain
class_name WarlordBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, _board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = entity_tile.unit.tile
    var ability: ActiveHeroAbility = unit.active_abilities[0]

    if not unit.has_moves():
        return []
    if ability.ap_cost > ap or ability.is_on_cooldown():
        return []

    var actions: Array[AbstractAction] = []
    var target_tile: MapTile
    var action: AbstractAction
    var path: Array[String]
    var interaction_tiles: Array[MapTile]
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap

    for friendly_unit_tile: String in self.pathfinder.own_units:
        target_tile = self.pathfinder.own_units[friendly_unit_tile]

        if not ability.is_tile_applicable(target_tile, entity_tile):
            continue

        if entity_tile.is_neighbour(target_tile):
            var ability_action: UseAbilityAction = self._ability_action(ability, target_tile)
            ability_action.delay = 0.5
            ability.active_source_tile = entity_tile
            ability_action.value = target_tile.unit.tile.unit_value
            if target_tile.unit.tile.level == 0:
                ability_action.value += target_tile.unit.tile.unit_value
            actions.append(ability_action)
            continue

        path = self.pathfinder.get_path_to_tile(target_tile)

        if path.size() - 1 > unit_range:
            if self._can_approach(entity_tile, path, unit_range - 1):
                action = self._approach_action(entity_tile, path, unit_range - 1)
                action.value = target_tile.unit.tile.unit_value - 20
                if target_tile.unit.tile.level == 0:
                    action.value += target_tile.unit.tile.unit_value
                actions.append(action)
        else:
            interaction_tiles = self._get_interaction_tiles(target_tile, entity_tile)

            for interaction_tile: MapTile in interaction_tiles:
                path = self.pathfinder.get_path_to_tile(interaction_tile)

                if path.size() - 1 > unit_range - 1:
                    if self._can_approach(entity_tile, path, unit_range - 1):
                        action = self._approach_action(entity_tile, path, unit_range - 1)
                        action.value = target_tile.unit.tile.unit_value - 10
                        if target_tile.unit.tile.level == 0:
                            action.value += target_tile.unit.tile.unit_value
                        actions.append(action)
                else:
                    if self._can_approach(entity_tile, path, path.size() - 1):
                        action = self._approach_action(entity_tile, path, path.size() - 1)
                        action.value = target_tile.unit.tile.unit_value - path.size()
                        if target_tile.unit.tile.level == 0:
                            action.value += target_tile.unit.tile.unit_value
                        actions.append(action)

    return actions
