extends BaseTrigger

var unit = null

func _init():
    self.observed_event_type = [Events.Type.UNIT_ATTACKED]

func _observe(event):
    if event.unit == self.unit:
        self.execute_outcome(event)

func _get_outcome_metadata(event: BaseEvent) -> Dictionary[String, Variant]:
    return {
        'unit' : event.unit,
        'attacker' : event.attacker
    }


func set_vip(x, y):
    self.unit = self.board.map.model.get_tile2(x, y).unit.tile

func ingest_details(details):
    self.set_vip(details['vip'][0], details['vip'][1])

func get_save_data():
    var save_data = super.get_save_data()
    save_data["unit"] = self.board.map.model.get_unit_position(self.unit)
    return save_data

func restore_from_state(state):
    super.restore_from_state(state)
    if state["unit"] != null:
        self.set_vip(state["unit"][0], state["unit"][1])
