extends BaseTrigger
class_name ResourcesTrigger

var amount: int = 0
var player_id: Variant = null
var player_side: Variant = null

func _init() -> void:
    self.observed_event_type = TurnStartedEvent

func _observe(_event: BaseEvent) -> void:
    var event: TurnStartedEvent = _event as TurnStartedEvent
    if self.player_side != null:
        self.player_id = self.board.state.get_player_id_by_side(String(self.player_side))

    if self.player_id == event.player_id and self.amount <= self.board.state.get_player_ap(int(self.player_id)):
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event: TurnStartedEvent = _event as TurnStartedEvent
    return {
        'turn_no' : event.turn_no,
        'player_id' : event.player_id
    }

func ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('amount'):
        self.amount = int(details['amount'])
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
