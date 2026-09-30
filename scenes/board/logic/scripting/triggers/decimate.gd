extends BaseTrigger
class_name DecimateTrigger

var player_id: Variant = null
var player_side: Variant = null

func _init() -> void:
    self.observed_event_type = UnitDestroyedDomainEvent

func _observe(_event: BoardDomainEvent) -> void:
    var event := _event as UnitDestroyedDomainEvent
    var side: String

    if self.player_id != null:
        side = self.model._state.get_player_side_by_id(int(self.player_id))
    if self.player_side != null:
        side = String(self.player_side)

    if event.unit_side == side:
        var units: Array[BaseUnit] = self.model.map_model.get_player_units(side)

        if units.size() == 0:
            self.execute_outcome(event)

func _get_outcome_metadata(_event: BoardDomainEvent) -> Dictionary[String, Variant]:
    var event := _event as UnitDestroyedDomainEvent
    return {
        'player_id' : self.model._state.get_player_id_by_side(event.unit_side),
        'side' : event.unit_side,
        'attacker' : self.model.find_unit_by_id(event.attacker_id)
    }

func ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
