extends BaseOutcome
class_name BanUnitOutcome

var ability_id: int
var where: Vector2i
var ban: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_building_ability_disabled(self.where, self.ability_id, self.ban)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.ability_id = int(details['ability_id'])
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.ban = bool(details['ban'])
