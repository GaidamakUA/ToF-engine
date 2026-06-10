extends BaseOutcome
class_name UseAbilityOutcome

var who: Vector2i
var which: String
var where: Vector2i
var cooldown: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var unit_tile: MapTile = self.board.map.model.get_tile(self.who)
    var ability: Ability = unit_tile.unit.get_map_object().get_node(self.which)

    self.board.selected_tile = unit_tile
    ability.active_source_tile = unit_tile
    ability._execute(self.board, self.where)
    self.board.unselect_tile()

    if self.cooldown:
        ability.activate_cooldown(self.board)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.which = details['which']
    self.where = Vector2i(details['where'][0], details['where'][1])
    if details.has('cooldown'):
        self.cooldown = bool(details['cooldown'])
