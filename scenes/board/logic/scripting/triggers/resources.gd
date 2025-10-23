extends BaseTrigger

var amount := 0
var player_id = null
var player_side = null

func _init() -> void:
    self.observed_event_type = TurnStartedEvent

func _observe(_event: BaseEvent) -> void:
    var event := _event as TurnStartedEvent
    if self.player_side != null:
        self.player_id = self.board.state.get_player_id_by_side(self.player_side)

    if self.player_id == event.player_id and self.amount <= self.board.state.get_player_ap(self.player_id):
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event := _event as TurnStartedEvent
    return {
        'turn_no' : event.turn_no,
        'player_id' : event.player_id
    }

func ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('amount'):
        self.amount = details['amount']
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
