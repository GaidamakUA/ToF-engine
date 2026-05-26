extends BaseTrigger
class_name AttackedTrigger

var unit: BaseUnit

func _init() -> void:
	self.observed_event_type = UnitAttackedEvent

func _observe(_event: BaseEvent) -> void:
	var event: UnitAttackedEvent = _event as UnitAttackedEvent
	if event.unit == self.unit:
		self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
	var event: UnitAttackedEvent = _event as UnitAttackedEvent
	return {
		'unit' : event.unit,
		'attacker' : event.attacker
	}

func set_vip(x: int, y: int) -> void:
	self.unit = self.board.map.model.get_tile2(x, y).unit.tile

func ingest_details(details: Dictionary[String, Variant]) -> void:
	self.set_vip(details['vip'][0], details['vip'][1])

func get_save_data() -> Dictionary[String, Variant]:
	var save_data: Dictionary[String, Variant] = super.get_save_data()
	save_data["unit"] = self.board.map.model.get_unit_position(self.unit)
	return save_data

func restore_from_state(state: Dictionary[String, Variant]) -> void:
	super.restore_from_state(state)
	if state["unit"] != null:
		self.set_vip(state["unit"][0], state["unit"][1])
