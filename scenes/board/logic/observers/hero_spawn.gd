extends Observer
class_name HeroSpawnObserver

func _init(_board: Board) -> void:
    super(_board)
    self.observed_event_type = UnitSpawnedEvent

func _observe(event: BaseEvent) -> void:
    var typed_event: UnitSpawnedEvent = event as UnitSpawnedEvent
    if not typed_event.unit is HeroUnit:
        return
    var hero: HeroUnit = typed_event.unit as HeroUnit
    self.board.state.auto_set_hero(hero)
