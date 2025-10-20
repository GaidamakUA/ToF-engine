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

var event_templates: Dictionary[Type, Resource] = {
    Type.BUILDING_CAPTURED : preload("res://scenes/board/logic/events/building_captured.gd"),
    Type.UNIT_SPAWNED : preload("res://scenes/board/logic/events/unit_spawned.gd"),
    Type.UNIT_MOVED : preload("res://scenes/board/logic/events/unit_moved.gd"),
    Type.UNIT_ATTACKED : preload("res://scenes/board/logic/events/unit_attacked.gd"),
    Type.UNIT_DESTROYED : preload("res://scenes/board/logic/events/unit_destroyed.gd"),
    Type.TURN_STARTED : preload("res://scenes/board/logic/events/turn_started.gd"),
    Type.ABILITY_USED : preload("res://scenes/board/logic/events/ability_used.gd")
}

var observers: Dictionary[Type, Array] = {}

func get_new_event(type: Type) -> BaseEvent:
    var new_event: BaseEvent = self.event_templates[type].new(type)
    return new_event

func register_observer(event_type: Type, observer_object, observer_method) -> void:
    if not self.observers.has(event_type):
        self.observers[event_type] = []

    self.observers[event_type].append({
        'observer_object' : observer_object,
        'observer_method' : observer_method
    })

func emit_event(event_object: BaseEvent) -> void:
    if self.observers.has(event_object.type):
        for observer in self.observers[event_object.type]:
            if observer['observer_object'].suspended:
                continue
            observer['observer_object'].call(observer['observer_method'], event_object)


func emit_building_captured(building, old_side: String, new_side: String) -> void:
    var event := self.get_new_event(Type.BUILDING_CAPTURED)
    event.building = building
    event.old_side = old_side
    event.new_side = new_side
    self.emit_event(event)

func emit_unit_attacked(attacker, defender) -> void:
    var event := self.get_new_event(Type.UNIT_ATTACKED)
    event.unit = defender
    event.attacker = attacker
    self.emit_event(event)

func emit_unit_destroyed(attacker, defender_id: int, defender_type, defender_side: String) -> void:
    var event := self.get_new_event(Type.UNIT_DESTROYED)
    event.unit_id = defender_id
    event.unit_side = defender_side
    event.unit_type = defender_type
    event.attacker = attacker
    self.emit_event(event)

func emit_unit_spawned(source, unit) -> void:
    var event := self.get_new_event(Type.UNIT_SPAWNED)
    event.source = source
    event.unit = unit
    self.emit_event(event)

func emit_ability_used(ability, target) -> void:
    var event := self.get_new_event(Type.ABILITY_USED)
    event.ability = ability
    event.target = target
    self.emit_event(event)

func emit_turn_started(turn_no: int, player_id: int) -> void:
    var event := self.get_new_event(Type.TURN_STARTED)
    event.turn_no = turn_no
    event.player_id = player_id
    self.emit_event(event)

func emit_unit_moved(unit, start, finish) -> void:
    var event := self.get_new_event(Type.UNIT_MOVED)
    event.unit = unit
    event.start = start
    event.finish = finish
    self.emit_event(event)
