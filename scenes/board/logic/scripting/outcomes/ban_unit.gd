extends BaseOutcome

var ability_id: int
var where: Array
var ban: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile := self.board.map.model.get_tile2(self.where[0], self.where[1])

    for ability: Ability in tile.building.tile.abilities:
        if ability.index == self.ability_id:
            ability.disabled = self.ban

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.ability_id = details['ability_id']
    self.where = details['where']
    self.ban = details['ban']
