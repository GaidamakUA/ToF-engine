extends AbstractUnitBrain
class_name TankBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = entity_tile.unit.tile

    if not unit.has_moves():
        return []

    if not unit.has_active_ability():
        return []

    var actions: Array[AbstractAction] = []
    var action: AbstractAction
    var target_tile: MapTile
    var path: Array[String]
    var interaction_tiles: Array[MapTile]
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap

    for ability: ActiveUnitAbility in unit.active_abilities:
        if ability.is_visible() and ability.get_cost() <= ap and not ability.is_on_cooldown():
            var targets_in_range: Array[MapTile] = []

            for tile: MapTile in board.ability_markers.get_all_tiles_in_ability_range(ability, entity_tile):
                if ability.is_tile_applicable(tile, entity_tile):
                    targets_in_range.append(tile)

            for target: MapTile in targets_in_range:
                var ability_action: UseAbilityAction = self._ability_action(ability, target)
                ability.active_source_tile = entity_tile
                ability_action.delay = 0.5
                ability_action.value = target.unit.tile.unit_value + 50
                actions.append(ability_action)


            for enemy_unit_tile: String in self.pathfinder.enemy_units:
                target_tile = self.pathfinder.enemy_units[enemy_unit_tile]

                if targets_in_range.has(target_tile):
                    continue

                if not unit.can_attack(target_tile.unit.tile):
                    continue

                path = self.pathfinder.get_path_to_tile(target_tile)

                if path.size() - 1 > unit_range:
                    if self._can_approach(entity_tile, path, unit_range - 1):
                        action = self._approach_action(entity_tile, path, unit_range - 1)
                        action.value = target_tile.unit.tile.get_value() - 20
                        actions.append(action)
                else:
                    interaction_tiles = self._get_interaction_tiles(target_tile, entity_tile)

                    for interaction_tile: MapTile in interaction_tiles:
                        path = self.pathfinder.get_path_to_tile(interaction_tile)

                        if path.size() - 1 > unit_range - 1:
                            if self._can_approach(entity_tile, path, unit_range - 1):
                                action = self._approach_action(entity_tile, path, unit_range - 1)
                                action.value = target_tile.unit.tile.get_value() - 20
                                actions.append(action)
                        else:
                            if self._can_approach(entity_tile, path, path.size() - 1):
                                action = self._approach_action(entity_tile, path, path.size() - 1)
                                action.value = target_tile.unit.tile.get_value() - path.size()
                                actions.append(action)

    return actions
