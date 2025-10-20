extends Observer
class_name HeroSpawnObserver

func _init(_board: Board) -> void:
    super(_board)
    self.observed_event_type = UnitSpawnedEvent

func _observe(event: BaseEvent) -> void:
    if event.unit.unit_class != "hero":
        return

    self.board.state.auto_set_hero(event.unit)
