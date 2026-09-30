class_name Collector

var brains: Brains = Brains.new()

var model: BoardModel


func _init(new_model: BoardModel) -> void:
    self.model = new_model


func select_best_action() -> Variant:
    var actions: Array[AbstractAction] = self._gather_all_actions()

    if actions.size() > 0:
        actions = self._sort_actions(actions)
        return actions[0]

    return null


func _gather_all_actions() -> Array[AbstractAction]:
    var side: String = self.model._state.get_current_side()
    var team: int = self.model._state.get_player_team(side)
    var ap: int = self.model._state.get_current_ap() - self.model.reserved_ap

    if ap <= 0:
        return []

    var buildings: Array[MapTile] = self.model.map_model.get_player_buildings_tiles(side)
    var units: Array[MapTile] = self.model.map_model.get_player_units_tiles(side)

    var enemy_buildings: Array[MapTile] = self.model.map_model.get_enemy_buildings_tiles(side, team)
    var enemy_units: Array[MapTile] = self.model.map_model.get_enemy_units_tiles(side, team)

    var buildings_actions: Array[AbstractAction] = self._gather_building_actions(buildings, enemy_buildings, enemy_units, buildings, units, ap)

    var units_actions: Array[AbstractAction] = self._gather_unit_actions(units, enemy_buildings, enemy_units, buildings, units, ap)

    return buildings_actions + units_actions


func _gather_building_actions(buildings: Array[MapTile],
                              enemy_buildings: Array[MapTile],
                              enemy_units: Array[MapTile],
                              own_buildings: Array[MapTile],
                              own_units: Array[MapTile],
                              ap: int) -> Array[AbstractAction]:
    var buildings_actions: Array[AbstractAction] = []
    var brain: AbstractBrain

    for building_tile: MapTile in buildings:
        brain = self.brains.get_brain_for_template(building_tile.building.tile.template_name)
        if brain == null:
            continue
        var brain_context: BrainContext = BrainContext.new(building_tile, enemy_buildings, enemy_units, own_buildings, own_units, ap, self.model)
        buildings_actions += brain.get_actions(brain_context)

    return buildings_actions


func _gather_unit_actions(units: Array[MapTile],
                          enemy_buildings: Array[MapTile],
                          enemy_units: Array[MapTile],
                          own_buildings: Array[MapTile],
                          own_units: Array[MapTile],
                          ap: int) -> Array[AbstractAction]:
    var units_actions: Array[AbstractAction] = []
    var brain: AbstractBrain

    for unit_tile: MapTile in units:
        var unit: BaseUnit = unit_tile._get_unit()
        if unit.ai_paused:
            continue

        brain = self.brains.get_brain_for_unit(unit)
        if brain == null:
            continue
        var brain_context: BrainContext = BrainContext.new(unit_tile, enemy_buildings, enemy_units, own_buildings, own_units, ap, self.model)
        units_actions += brain.get_actions(brain_context)

    return units_actions


func _sort_actions(actions: Array[AbstractAction]) -> Array[AbstractAction]:
    actions.sort_custom(_customComparison)

    return actions


func _customComparison(a: AbstractAction, b: AbstractAction) -> bool:
    return a.value > b.value
