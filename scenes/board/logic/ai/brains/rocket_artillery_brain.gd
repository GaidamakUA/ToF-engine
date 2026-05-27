extends AbstractUnitBrain
class_name RocketArtilleryBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)

    if not unit.has_moves():
        return []

    var approach_target_tile: MapTile
    var path: Array[String]
    var actions: Array[AbstractAction] = []
    var action: AbstractAction
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap

    var closest_enemy: int = 999

    for enemy_unit_tile: String in self.pathfinder.enemy_units:
        approach_target_tile = self.pathfinder.enemy_units[enemy_unit_tile]

        path = self.pathfinder.get_path_to_tile(approach_target_tile)

        if path.size() < closest_enemy:
            closest_enemy = path.size()

    if closest_enemy > 4:
        for enemy_unit_tile: String in self.pathfinder.enemy_units:
            approach_target_tile = self.pathfinder.enemy_units[enemy_unit_tile]
            path = self.pathfinder.get_path_to_tile(approach_target_tile)
            if path.size() - 1 > unit_range + 2:
                if self._can_approach(entity_tile, path, unit_range - 1):
                    var approach_target_unit: BaseUnit = self._get_unit(approach_target_tile)
                    action = self._approach_action(entity_tile, path, unit_range - 1)
                    action.value = approach_target_unit.unit_value - 20
                    actions.append(action)

    for ability: ActiveUnitAbility in unit.active_abilities:
        if ability.is_visible() and ability.get_cost() <= ap and not ability.is_on_cooldown():
            var targets_in_range: Array[MapTile] = []

            for tile: MapTile in board.ability_markers.get_all_tiles_in_ability_range(ability, entity_tile):
                if ability.is_tile_applicable(tile, entity_tile):
                    targets_in_range.append(tile)

            for target_tile: MapTile in targets_in_range:
                var target_unit: BaseUnit = self._get_unit(target_tile)
                var ability_action: UseAbilityAction = self._ability_action(ability, target_tile)
                ability.active_source_tile = entity_tile
                ability_action.delay = 0.5
                ability_action.value = target_unit.unit_value
                actions.append(ability_action)

    return actions
