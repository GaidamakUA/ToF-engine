extends HeroBrain
class_name AdmiralBrain

func _gather_ability_actions(entity_tile: MapTile, ap: int, board: Board) -> Array[AbstractAction]:
    var unit: BaseUnit = entity_tile.unit.tile
    var ability: ActiveAbility = unit.active_abilities[0]

    if not unit.has_moves():
        return []
    if ability.ap_cost > ap or ability.is_on_cooldown():
        return []

    var approach_target_tile: MapTile
    var path: Array[String]
    var actions: Array[AbstractAction] = []
    var action: AbstractAction
    var unit_range: int = unit.get_move()

    var approachable_targets: Array[MapTile] = []
    var target_search_range: int = 8

    if unit_range > ap:
        unit_range = ap

    for enemy_unit_tile: String in self.pathfinder.enemy_units:
        approach_target_tile = self.pathfinder.enemy_units[enemy_unit_tile]

        path = self.pathfinder.get_path_to_tile(approach_target_tile)

        if path.size() > 3 and path.size() <= target_search_range:
            approachable_targets.append(approach_target_tile)

    for enemy_unit_tile: MapTile in approachable_targets:
        path = self.pathfinder.get_path_to_tile(enemy_unit_tile)
        if path.size() - 1 > ability.ability_range:
            var steps_needed: int = path.size() - 1 - (ability.ability_range - 1)
            if steps_needed > unit_range - 1:
                steps_needed = unit_range - 1
            if self._can_approach(entity_tile, path, steps_needed):
                action = self._approach_action(entity_tile, path, steps_needed)
                action.value = _calculate_blast_value(unit, enemy_unit_tile)
                if action.value >= 40:
                    actions.append(action)


    var targets_in_range: Array[MapTile] = []

    for tile: MapTile in board.ability_markers.get_all_tiles_in_ability_range(ability, entity_tile):
        if ability.is_tile_applicable(tile, entity_tile):
            targets_in_range.append(tile)

    for target_tile: MapTile in targets_in_range:
        var ability_action: UseAbilityAction = self._ability_action(ability, target_tile)
        ability.active_source_tile = entity_tile
        ability_action.delay = 0.5
        ability_action.value = _calculate_blast_value(unit, target_tile)
        if ability_action.value >= 40:
            actions.append(ability_action)

    return actions

func _calculate_blast_value(source: BaseUnit, target_tile: MapTile) -> int:
    var tiles_in_blast_area: Array[MapTile] = [target_tile]
    var final_value: int = 0

    tiles_in_blast_area += target_tile.neighbours.values()

    for tile: MapTile in tiles_in_blast_area:
        if tile.has_enemy_unit(source.side, source.team):
            final_value += tile.unit.tile.get_value()
            if tile.unit.tile.hp <= 5:
                final_value += 10
        if tile.has_friendly_unit(source.side) or tile.has_allied_unit(source.team):
            final_value -= tile.unit.tile.get_value()
            if tile.unit.tile.hp <= 5:
                final_value -= 10

    return final_value
