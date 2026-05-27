extends Observer
class_name ExperienceObserver

func _init(_board: Board) -> void:
    super(_board)
    self.observed_event_type = UnitDestroyedEvent

func _observe(event: BaseEvent) -> void:
    var destroyed_event: UnitDestroyedEvent = event as UnitDestroyedEvent
    assert(destroyed_event != null)
    if destroyed_event.attacker != null:
        destroyed_event.attacker.score_kill()
