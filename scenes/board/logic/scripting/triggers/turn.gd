extends BaseTrigger

var turn_no = null
var player_id = null

func _init() -> void:
    self.observed_event_type = TurnStartedEvent

func _observe(_event: BaseEvent) -> void:
    var event := _event as TurnStartedEvent
    if self.turn_no != null and self.turn_no == event.turn_no:
        if self.player_id == null or self.player_id == event.player_id:
            self.execute_outcome(event)
    elif self.turn_no == null and self.player_id != null and self.player_id == event.player_id:
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event := _event as TurnStartedEvent
    return {
        'turn_no' : event.turn_no,
        'player_id' : event.player_id
    }

func ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('turn'):
        self.turn_no = details['turn']
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_id = self.board.state.get_player_id_by_side(details['player_side'])

func get_save_data() -> Dictionary[String, Variant]:
    var save_data := super.get_save_data()
    save_data["turn_no"] = self.turn_no
    return save_data

func restore_from_state(state: Dictionary[String, Variant]) -> void:
    super.restore_from_state(state)
    self.turn_no = state["turn_no"]
