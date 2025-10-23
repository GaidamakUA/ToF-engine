extends BaseTrigger

func _init() -> void:
    self.observed_event_type = AbilityUsedEvent

func _observe(_event: BaseEvent) -> void:
    var event := _event as AbilityUsedEvent
    if not event.consumed:
        event.consumed = true
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event := _event as AbilityUsedEvent
    return {
        'ability' : event.ability,
        'target' : event.target
    }
