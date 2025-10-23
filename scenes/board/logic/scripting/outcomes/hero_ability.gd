extends BaseOutcome

var side: String
var suspended: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var heroes := self.board.state.get_heroes_for_side(self.side)

    for hero in heroes:
        if self.suspended:
            hero.disable_abilities()
        else:
            hero.enable_abilities()

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.side = details['side']
    self.suspended = details['suspended']
