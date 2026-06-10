extends BaseOutcome
class_name PauseAiOutcome

var who: Vector2i
var pause: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.who)

    if not tile.unit.is_present():
        return

    var unit: BaseUnit = tile.unit.get_map_object() as BaseUnit
    assert(unit != null)

    if self.pause:
        unit.ai_paused = true
        unit.remove_moves()
    else:
        unit.ai_paused = false
        unit.replenish_moves()

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.pause = bool(details['pause'])
