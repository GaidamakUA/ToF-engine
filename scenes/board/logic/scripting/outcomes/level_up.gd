extends BaseOutcome

var who

func _execute(_metadata):
    var tile = self.board.map.model.get_tile(self.who)
    if tile.unit.is_present():
        tile.unit.tile.level_up()

func _ingest_details(details):
    self.who = Vector2(details['who'][0], details['who'][1])
