extends BaseOutcome
class_name BanUnitOutcome

var ability_id: int
var where: Vector2i
var ban: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.where)
    var building: BaseBuilding = tile.building.tile as BaseBuilding
    assert(building != null)

    for ability: Ability in building.abilities:
        if ability.index == self.ability_id:
            ability.disabled = self.ban

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.ability_id = int(details['ability_id'])
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.ban = bool(details['ban'])
