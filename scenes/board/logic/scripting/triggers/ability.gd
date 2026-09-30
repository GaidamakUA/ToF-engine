extends BaseTrigger
class_name AbilityTrigger

func _init() -> void:
    self.observed_event_type = AbilityUsedDomainEvent

func _observe(_event: BoardDomainEvent) -> void:
    var event := _event as AbilityUsedDomainEvent
    if not event.consumed:
        event.consumed = true
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BoardDomainEvent) -> Dictionary[String, Variant]:
    var event := _event as AbilityUsedDomainEvent
    var source: MapObject = self.model.find_map_object_by_id(event.source_id)
    return {
        'ability' : self.model._find_ability(source, event.ability_key),
        'target' : event.target
    }
