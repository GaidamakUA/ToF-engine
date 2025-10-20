extends BaseTrigger

func _init():
    self.observed_event_type = AbilityUsedEvent

func _observe(event):
    if not event.consumed:
        event.consumed = true
        self.execute_outcome(event)

func _get_outcome_metadata(event: BaseEvent) -> Dictionary[String, Variant]:
    return {
        'ability' : event.ability,
        'target' : event.target
    }
