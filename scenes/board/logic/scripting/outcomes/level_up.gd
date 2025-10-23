extends BaseOutcome

var who: Vector2i

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile := self.board.map.model.get_tile(self.who)
    if tile.unit.is_present():
        tile.unit.tile.level_up()

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
