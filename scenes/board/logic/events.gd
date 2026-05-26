class_name Events

var observers: Array[Observer] = []

func register_observer(observer_object: Observer) -> void:
	self.observers.append(observer_object)

func emit_event(event_object: BaseEvent) -> void:
	for observer: Observer in self.observers:
		if observer.suspended:
			continue
		if not is_instance_of(event_object, observer.observed_event_type):
			continue
		observer.observe(event_object)


func emit_building_captured(building: BaseBuilding, old_side: String, new_side: String) -> void:
	var event := BuildingCapturedEvent.new()
	event.building = building
	event.old_side = old_side
	event.new_side = new_side
	self.emit_event(event)

func emit_unit_attacked(attacker: BaseUnit, defender: BaseUnit) -> void:
	var event := UnitAttackedEvent.new()
	event.unit = defender
	event.attacker = attacker
	self.emit_event(event)

func emit_unit_destroyed(attacker: BaseUnit, defender_id: int, defender_type: String, defender_side: String) -> void:
	var event := UnitDestroyedEvent.new()
	event.unit_id = defender_id
	event.unit_side = defender_side
	event.unit_type = defender_type
	event.attacker = attacker
	self.emit_event(event)

func emit_unit_spawned(source: MapObject, unit: BaseUnit) -> void:
	var event := UnitSpawnedEvent.new()
	event.source = source
	event.unit = unit
	self.emit_event(event)

func emit_ability_used(ability: Ability, target: Vector2i) -> void:
	var event := AbilityUsedEvent.new()
	event.ability = ability
	event.target = target
	self.emit_event(event)

func emit_turn_started(turn_no: int, player_id: int) -> void:
	var event := TurnStartedEvent.new()
	event.turn_no = turn_no
	event.player_id = player_id
	self.emit_event(event)

func emit_unit_moved(unit: BaseUnit, start: MapTile, finish: MapTile) -> void:
	var event := UnitMovedEvent.new()
	event.unit = unit
	event.start = start
	event.finish = finish
	self.emit_event(event)
