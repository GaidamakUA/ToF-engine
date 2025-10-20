extends BaseTrigger

var player_id = null
var player_side = null

func _init():
    self.observed_event_type = [Events.Type.UNIT_DESTROYED]

func _observe(event):
    var units
    var side

    if self.player_id != null:
        side = self.board.state.get_player_side_by_id(self.player_id)
    if self.player_side != null:
        side = self.player_side

    if event.unit_side == side:
        units = self.board.map.model.get_player_units(side)

        if units.size() == 0:
            self.execute_outcome(event)

func _get_outcome_metadata(event: BaseEvent) -> Dictionary[String, Variant]:
    return {
        'player_id' : self.board.state.get_player_id_by_side(event.unit_side),
        'side' : event.unit_side,
        'attacker' : event.attacker
    }

func ingest_details(details):
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
