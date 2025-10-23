extends BaseOutcome

var who: Vector2i
var length: int

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile = self.board.map.model.get_tile2(self.who[0], self.who[1])

    if not tile.unit.is_present():
        return

    tile.unit.tile.tether_point.x = self.who.x
    tile.unit.tile.tether_point.y = self.who.y
    tile.unit.tile.tether_length = self.length

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.length = details['length']
