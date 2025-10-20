extends Observer
class_name ExperienceObserver

func _init(_board: Board) -> void:
    super(_board)
    self.observed_event_type = UnitDestroyedEvent

func _observe(event: BaseEvent) -> void:
    if event.attacker != null:
        event.attacker.score_kill()
