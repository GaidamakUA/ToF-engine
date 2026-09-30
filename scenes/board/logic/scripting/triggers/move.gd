extends BaseTrigger
class_name MoveTrigger

var fields: Array[Dictionary] = []
var player_id: Variant = null
var player_side: Variant = null
var unit_tag: Variant = null
var exclude_tags: Array[String] = []

func _init() -> void:
    self.observed_event_type = UnitMovedDomainEvent

func _observe(_event: BoardDomainEvent) -> void:
    var event := _event as UnitMovedDomainEvent
    var unit: BaseUnit = self.model.find_unit_by_id(event.unit_id)
    if self._is_watched_position(event.finish):
        if self.is_excluded_vip(unit):
            return

        if self.player_id != null:
            if self.player_id == self.model._state.get_player_id_by_side(unit.side):
                self.execute_outcome(event)
        elif self.player_side != null:
            if self.player_side == unit.side:
                self.execute_outcome(event)
        elif self.unit_tag != null:
            if unit.has_script_tag(self.unit_tag):
                self.execute_outcome(event)
        else:
            self.execute_outcome(event)


func execute_outcome(event: BoardDomainEvent) -> void:
    super.execute_outcome(event)
    self.model.clear_undo()

func _get_outcome_metadata(_event: BoardDomainEvent) -> Dictionary[String, Variant]:
    var event := _event as UnitMovedDomainEvent
    var unit: BaseUnit = self.model.find_unit_by_id(event.unit_id)
    return {
        'field' : self.model.map_model.get_tile(event.finish),
        'player_id' : self.model._state.get_player_id_by_side(unit.side),
        'side' : unit.side,
        'unit' : unit
    }

func set_vip(x: int, y: int) -> void:
    self.unit_tag = "move_" + str(x) + "_" + str(y)
    self.model.map_model.get_tile2(x, y).unit.tile.add_script_tag(self.unit_tag)

func exclude_vip(x: int, y: int) -> void:
    var new_tag: String = "exclude_move_" + str(x) + "_" + str(y)
    self.exclude_tags.append(new_tag)
    self.model.map_model.get_tile2(x, y).unit.tile.add_script_tag(new_tag)

func is_excluded_vip(unit: BaseUnit) -> bool:
    if self.exclude_tags.size() < 1:
        return false

    for excluded_tag: String in self.exclude_tags:
        if unit.has_script_tag(excluded_tag):
            return true

    return false

func ingest_details(details: Dictionary[String, Variant]) -> void:
    self.fields.assign(details['fields'])
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
    if details.has('unit'):
        self.set_vip(details['unit'][0], details['unit'][1])
    if details.has('unit_tag'):
        self.unit_tag = details['unit_tag']
    if details.has('excluded'):
        for unit: Array in details['excluded']:
            self.exclude_vip(unit[0], unit[1])

func _is_watched_position(position: Vector2i) -> bool:
    for rectangle: Dictionary in self.fields:
        if position.x >= rectangle["x1"] and position.x <= rectangle["x2"] and position.y >= rectangle["y1"] and position.y <= rectangle["y2"]:
            return true
    return false
