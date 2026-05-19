extends BaseOutcome
class_name TetherOutcome

var who: Vector2i
var length: int

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile2(self.who[0], self.who[1])

    if not tile.unit.is_present():
        return

    var unit: BaseUnit = tile.unit.tile as BaseUnit
    assert(unit != null)
    unit.tether_point.x = self.who.x
    unit.tether_point.y = self.who.y
    unit.tether_length = self.length

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.length = int(details['length'])
