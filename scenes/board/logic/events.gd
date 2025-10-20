class_name Events

enum Type {
    BUILDING_CAPTURED,
    UNIT_SPAWNED,
    UNIT_MOVED,
    UNIT_ATTACKED,
    UNIT_DESTROYED,
    TURN_STARTED,
    ABILITY_USED
}

var observers: Dictionary[Type, Array] = {}

func register_observer(event_type: Type, observer_object: Observer) -> void:
    if not self.observers.has(event_type):
        self.observers[event_type] = []

    self.observers[event_type].append(observer_object)

func emit_event(event_object: BaseEvent) -> void:
    if self.observers.has(event_object.type):
        for observer: Observer in self.observers[event_object.type]:
            if observer.suspended:
                continue
            observer.observe(event_object)


func emit_building_captured(building: BaseBuilding, old_side: String, new_side: String) -> void:
    var event := BuildingCapturedEvent.new(Type.BUILDING_CAPTURED)
    event.building = building
    event.old_side = old_side
    event.new_side = new_side
    self.emit_event(event)

func emit_unit_attacked(attacker: BaseUnit, defender: BaseUnit) -> void:
    var event := UnitAttackedEvent.new(Type.UNIT_ATTACKED)
    event.unit = defender
    event.attacker = attacker
    self.emit_event(event)

func emit_unit_destroyed(attacker: BaseUnit, defender_id: int, defender_type: String, defender_side: String) -> void:
    var event := UnitDestroyedEvent.new(Type.UNIT_DESTROYED)
    event.unit_id = defender_id
    event.unit_side = defender_side
    event.unit_type = defender_type
    event.attacker = attacker
    self.emit_event(event)

func emit_unit_spawned(source: MapObject, unit: BaseUnit) -> void:
    var event := UnitSpawnedEvent.new(Type.UNIT_SPAWNED)
    event.source = source
    event.unit = unit
    self.emit_event(event)

func emit_ability_used(ability: Ability, target: Vector2i) -> void:
    var event := AbilityUsedEvent.new(Type.ABILITY_USED)
    event.ability = ability
    event.target = target
    self.emit_event(event)

func emit_turn_started(turn_no: int, player_id: int) -> void:
    var event := TurnStartedEvent.new(Type.TURN_STARTED)
    event.turn_no = turn_no
    event.player_id = player_id
    self.emit_event(event)

func emit_unit_moved(unit: BaseUnit, start: MapTile, finish: MapTile) -> void:
    var event := UnitMovedEvent.new(Type.UNIT_MOVED)
    event.unit = unit
    event.start = start
    event.finish = finish
    self.emit_event(event)
