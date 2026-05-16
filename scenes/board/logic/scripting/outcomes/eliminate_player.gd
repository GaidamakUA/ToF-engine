extends BaseOutcome
class_name EliminatePlayerOutcome

var winner: Variant = null
var side: Variant = null
var force_kill: bool = false

func _execute(metadata: Dictionary[String, Variant]) -> void:
    if side != null:
        self.board.state.eliminate_player(String(self.side))
        return

    var old_side: String = String(metadata['old_side'])
    var bunkers: Array[MapTile] = self.board.map.model.get_player_bunkers(old_side)

    if bunkers.size() > 0 and not self.force_kill:
        return

    self.board.state.eliminate_player(old_side)

    if self.board.state.count_alive_players() == 1 or self.board.state.count_alive_teams() == 1:
        if self.winner == null:
            self.winner = metadata['new_side']

        self.board.end_game(self.winner)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('winner'):
        self.winner = details['winner']
    if details.has('side'):
        self.side = details['side']
    if details.has('force'):
        self.force_kill = bool(details['force'])
