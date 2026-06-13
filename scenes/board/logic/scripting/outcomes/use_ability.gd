extends BaseOutcome
class_name UseAbilityOutcome

var who: Vector2i
var which: String
var where: Vector2i
var cooldown: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var unit_tile: MapTile = self.board.map.model.get_tile(self.who)
    var unit: BaseUnit = unit_tile.unit.tile
    var ability: Ability = unit.get_ability_by_id(self.which)

    self.board.selected_tile = unit_tile
    ability._execute(self.board, unit, unit_tile, self.where)
    self.board.unselect_tile()

    if self.cooldown:
        unit.activate_ability_cooldown(ability, self.board)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.which = details['which']
    self.where = Vector2i(details['where'][0], details['where'][1])
    if details.has('cooldown'):
        self.cooldown = bool(details['cooldown'])
