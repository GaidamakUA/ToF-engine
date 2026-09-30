extends BaseTrigger
class_name DeployTrigger

var amount: int
var player_id: Variant = null
var player_side: Variant = null
var unit_type: Variant = null

func _init() -> void:
    self.observed_event_type = UnitSpawnedDomainEvent

func _observe(_event: BoardDomainEvent) -> void:
    var event := _event as UnitSpawnedDomainEvent
    var units: Array[BaseUnit]
    var side: String

    if self.player_id != null:
        side = self.model._state.get_player_side_by_id(int(self.player_id))
    if self.player_side != null:
        side = String(self.player_side)

    if event.side == side:
        units = self.model.map_model.get_player_units(side)

        if self._count_units(units) >= self.amount:
            self.execute_outcome(event)

func _get_outcome_metadata(_event: BoardDomainEvent) -> Dictionary[String, Variant]:
    var event := _event as UnitSpawnedDomainEvent
    var unit: BaseUnit = self.model.find_unit_by_id(event.unit_id)
    return {
        'amount' : self.amount,
        'player_id' : self.model._state.get_player_id_by_side(event.side),
        'side' : event.side,
        'unit' : unit,
        'source' : unit,
        'type' : event.template_key
    }

func ingest_details(details: Dictionary[String, Variant]) -> void:
    self.amount = int(details['amount'])
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
    if details.has('type'):
        self.unit_type = details['type']

func _count_units(units: Array[BaseUnit]) -> int:
    if self.unit_type == null:
        return units.size()

    var counted: int = 0
    for unit: BaseUnit in units:
        if unit.template_name == self.unit_type:
            counted += 1
    return counted
