class_name AbstractUnitBrain
extends AbstractBrain

const EXPLORE_DISTANCE: int = 16
const EXTRA_EXPLORE_DISTANCE: int = 32

var pathfinder: Pathfinder = Pathfinder.new()

var counter_death_penalty: int = 20

func get_actions(context: BrainContext) -> Array[AbstractAction]:
    self.pathfinder.explore(context.entity_tile, self.EXPLORE_DISTANCE)
    var actions: Array[AbstractAction] = _gather_all_actions(context.entity_tile, context.ap, context.board)

    var unit: BaseUnit = self._get_unit(context.entity_tile)
    if actions.size() == 0 and unit.perform_extra_lookup:
        self.pathfinder.explore(context.entity_tile, self.EXTRA_EXPLORE_DISTANCE)
        return _gather_all_actions(context.entity_tile, context.ap, context.board)
    return actions

func _get_unit(tile: MapTile) -> BaseUnit:
    var unit: BaseUnit = tile.unit.get_map_object() as BaseUnit
    assert(unit != null)
    return unit

func _get_building(tile: MapTile) -> BaseBuilding:
    var building: BaseBuilding = tile.building.get_map_object() as BaseBuilding
    assert(building != null)
    return building


func _gather_all_actions(entity_tile: MapTile, ap: int, board: Board) -> Array[AbstractAction]:
    var actions: Array[AbstractAction] = []
    var unit: BaseUnit = self._get_unit(entity_tile)

    actions += self._gather_attack_actions(entity_tile, ap)
    actions += self._gather_ability_actions(entity_tile, ap, board)
    if unit.can_capture:
        actions += self._gather_capture_actions(entity_tile, ap)

    return actions


func _gather_attack_actions(entity_tile: MapTile, ap: int) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)

    if not unit.has_moves() or not unit.has_attacks():
        return []

    var actions: Array[AbstractAction] = []
    var target_tile: MapTile
    var action: AbstractAction
    var path: Array[String]
    var interaction_tiles: Array[MapTile]
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap

    for enemy_unit_tile: String in self.pathfinder.enemy_units:
        target_tile = self.pathfinder.enemy_units[enemy_unit_tile]
        var target_unit: BaseUnit = self._get_unit(target_tile)
        if not unit.can_attack(target_unit):
            continue

        if target_unit.ai_paused:
            continue

        if entity_tile.is_neighbour(target_tile):
            action = self._attack_action(entity_tile, null, target_tile, [])
            action.value += unit_range
            actions.append(action)
            continue

        path = self.pathfinder.get_path_to_tile(target_tile)

        if path.size() - 1 > unit_range:
            if self._can_approach(entity_tile, path, unit_range - 1):
                action = self._approach_action(entity_tile, path, unit_range - 1)
                action.value = target_unit.get_value() - 20
                actions.append(action)
        else:
            interaction_tiles = self._get_interaction_tiles(target_tile, entity_tile)

            for interaction_tile: MapTile in interaction_tiles:
                path = self.pathfinder.get_path_to_tile(interaction_tile)

                if path.size() - 1 > unit_range - 1:
                    if self._can_approach(entity_tile, path, unit_range - 1):
                        action = self._approach_action(entity_tile, path, unit_range - 1)
                        action.value = target_unit.get_value() - 20
                        actions.append(action)
                else:
                    action = self._attack_action(entity_tile, interaction_tile, target_tile, path)
                    if action != null:
                        action.value -= path.size()
                        actions.append(action)

    return actions

func _gather_capture_actions(entity_tile: MapTile, ap: int) -> Array[AbstractAction]:
    var unit: BaseUnit = self._get_unit(entity_tile)

    if not unit.has_moves():
        return []

    var actions: Array[AbstractAction] = []
    var target_tile: MapTile
    var action: AbstractAction
    var path: Array[String]
    var interaction_tiles: Array[MapTile]
    var unit_range: int = unit.get_move()

    if unit_range > ap:
        unit_range = ap

    for enemy_building_tile: String in self.pathfinder.enemy_buildings:
        target_tile = self.pathfinder.enemy_buildings[enemy_building_tile]
        var target_building: BaseBuilding = self._get_building(target_tile)

        if entity_tile.is_neighbour(target_tile):
            action = self._capture_action(entity_tile, null, target_tile, [])
            action.value = target_building.capture_value - (unit.get_value() - 20)
            actions.append(action)
            continue

        path = self.pathfinder.get_path_to_tile(target_tile)

        if path.size() - 1 > unit_range:
            if self._can_approach(entity_tile, path, unit_range - 1):
                action = self._approach_action(entity_tile, path, unit_range - 1)
                action.value = 10
                actions.append(action)
        else:
            interaction_tiles = self._get_interaction_tiles(target_tile, entity_tile)

            for interaction_tile: MapTile in interaction_tiles:
                path = self.pathfinder.get_path_to_tile(interaction_tile)

                if path.size() - 1 > unit_range - 1:
                    if self._can_approach(entity_tile, path, unit_range - 1):
                        action = self._approach_action(entity_tile, path, unit_range - 1)
                        action.value = 10
                        actions.append(action)
                else:
                    action = self._capture_action(entity_tile, interaction_tile, target_tile, path)
                    if action != null:
                        action.value = target_building.capture_value - (unit.get_value() - 20)
                        action.value -= path.size()
                        actions.append(action)

    return actions

func _gather_ability_actions(_entity_tile: MapTile, _ap: int, _board: Board) -> Array[AbstractAction]:
    return []

func _attack_action(entity_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile, path: Array[String]) -> AttackAction:
    var unit: BaseUnit = self._get_unit(entity_tile)
    var target_unit: BaseUnit = self._get_unit(target_tile)

    if self._is_beyond_tether(unit, interaction_tile):
        return null

    var action: AttackAction = AttackAction.new(entity_tile, interaction_tile, target_tile, path.size())

    var value: int = target_unit.get_value()

    if unit.can_kill(target_unit):
        value += 100
    else:
        if target_unit.can_retaliate(unit):
            value -= 10
        if target_unit.can_retaliate(unit) and target_unit.has_enough_power_to_kill(unit):
            value -= self.counter_death_penalty

    action.value = value

    return action

func _capture_action(entity_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile, path: Array[String]) -> CaptureAction:
    if self._is_beyond_tether(self._get_unit(entity_tile), interaction_tile):
        return null

    return CaptureAction.new(entity_tile, interaction_tile, target_tile, path.size())

func _ability_action(ability: Ability, target: MapTile) -> UseAbilityAction:
    return UseAbilityAction.new(ability, target)

func _can_approach(entity_tile: MapTile, path: Array[String], unit_range: int) -> bool:
    if unit_range < 1:
        return false

    var target_tile: MapTile = self.pathfinder.visited_tiles[path[path.size() - unit_range - 1]]
    var unit: BaseUnit = self._get_unit(entity_tile)
    if self._is_beyond_tether(unit, target_tile):
        return false
    if target_tile.can_acommodate_unit(unit):
        return true
    var interation_tiles: Array[MapTile] = self._get_interaction_tiles(target_tile, entity_tile)
    var index: int = interation_tiles.find_custom(func (nearby_tile: MapTile) -> bool:
        var nearby_path: Array[String] = self.pathfinder.get_path_to_tile(nearby_tile)
        return nearby_path.size() - 1 <= unit_range and nearby_tile.can_acommodate_unit(unit)
        )
    return index != -1

func _approach_action(entity_tile: MapTile, path: Array[String], unit_range: int) -> MoveAction:
    var target_tile: MapTile = self.pathfinder.visited_tiles[path[path.size() - unit_range - 1]]
    var unit: BaseUnit = self._get_unit(entity_tile)

    if target_tile.can_acommodate_unit(unit):
        return MoveAction.new(entity_tile, target_tile, unit_range)
    else:
        var nearby_tiles: Array[MapTile] = self._get_interaction_tiles(target_tile, entity_tile)
        var index: int = nearby_tiles.find_custom(func (nt: MapTile) -> bool:
            var np: Array[String] = self.pathfinder.get_path_to_tile(nt)
            return np.size() - 1 <= unit_range and nt.can_acommodate_unit(unit)
            )
        var nearby_tile: MapTile = nearby_tiles[index]
        var nearby_path: Array[String] = self.pathfinder.get_path_to_tile(nearby_tile)
        return MoveAction.new(entity_tile, nearby_tile, nearby_path.size())

func _move_action(entity_tile: MapTile, path: Array[String], unit_range: int) -> MoveAction:
    if unit_range < 1:
        return null

    var target_tile_index: int = path.size() - unit_range - 1
    if target_tile_index < 0:
        target_tile_index = 0
    var target_tile: MapTile = self.pathfinder.visited_tiles[path[target_tile_index]]

    var unit: BaseUnit = self._get_unit(entity_tile)
    if self._is_beyond_tether(unit, target_tile):
        return null

    if target_tile.can_acommodate_unit(unit):
        return MoveAction.new(entity_tile, target_tile, unit_range)

    return null

func _get_interaction_tiles(tile: MapTile, source_tile: MapTile) -> Array[MapTile]:
    var unit: BaseUnit = self._get_unit(source_tile)
    var tiles: Array[MapTile] = tile.neighbours.values().filter(func (n:MapTile) -> bool:
        return n.can_acommodate_unit(unit) and self.pathfinder.is_tile_reachable(n))
    return tiles

func _is_beyond_tether(unit: BaseUnit, target_tile: MapTile) -> bool:
    if unit.tether_length < 1 or target_tile == null:
        return false

    var anchor_distance: int = abs(unit.tether_point.x - target_tile.position.x) + abs(unit.tether_point.y - target_tile.position.y)

    if OS.is_debug_build():
        print(unit.tether_point, " ", target_tile.position, " ", anchor_distance, " ", unit.tether_length)

    return anchor_distance > unit.tether_length
