extends BaseTrigger
class_name AssassinationTrigger

var vip_id: Variant = null
var vip: Variant = null
var unit_type: Variant = null

func _init() -> void:
    self.observed_event_type = UnitDestroyedEvent

func _observe(_event: BaseEvent) -> void:
    var event: UnitDestroyedEvent = _event as UnitDestroyedEvent
    if event.unit_id == self.vip_id:
        self.vip = null
        self.execute_outcome(event)
    elif self.vip_id == null and event.unit_type == self.unit_type:
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event: UnitDestroyedEvent = _event as UnitDestroyedEvent
    return {
        'player_id' : self.board.state.get_player_id_by_side(event.unit_side),
        'side' : event.unit_side,
        'attacker' : event.attacker
    }

func set_vip(x: int, y: int) -> void:
    self.vip = self.board.map.model.get_tile2(x, y).unit.get_map_object()
    self.vip_id = self.vip.get_instance_id()

func ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has("vip"):
        self.set_vip(details['vip'][0], details['vip'][1])
    if details.has("type"):
        self.unit_type = details["type"]

func get_save_data() -> Dictionary[String, Variant]:
    var save_data: Dictionary[String, Variant] = super.get_save_data()
    save_data["vip"] = self.board.map.model.get_unit_position(self.vip)
    return save_data

func restore_from_state(state: Dictionary[String, Variant]) -> void:
    super.restore_from_state(state)
    if state["vip"] != null:
        self.set_vip(state["vip"][0], state["vip"][1])
