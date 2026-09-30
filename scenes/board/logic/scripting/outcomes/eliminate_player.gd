extends BaseOutcome
class_name EliminatePlayerOutcome

var winner: Variant = null
var side: Variant = null
var force_kill: bool = false

func _execute(metadata: Dictionary[String, Variant]) -> void:
    if side != null:
        self.model.eliminate_player(String(self.side))
        return

    var old_side: String = String(metadata['old_side'])
    var bunkers: Array[MapTile] = self.model.map_model.get_player_bunkers(old_side)

    if bunkers.size() > 0 and not self.force_kill:
        return

    if self.winner == null:
        self.winner = metadata['new_side']
    self.model.eliminate_player(old_side, String(self.winner))

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('winner'):
        self.winner = details['winner']
    if details.has('side'):
        self.side = details['side']
    if details.has('force'):
        self.force_kill = bool(details['force'])
