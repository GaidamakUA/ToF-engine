extends BaseOutcome
class_name PauseAiOutcome

var who: Vector2i
var pause: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.who)

    if not tile.unit.is_present():
        return

    if self.pause:
        tile.unit.tile.ai_paused = true
        tile.unit.tile.remove_moves()
    else:
        tile.unit.tile.ai_paused = false
        tile.unit.tile.replenish_moves()

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.pause = bool(details['pause'])
