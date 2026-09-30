extends BaseOutcome
class_name TetherOutcome

var who: Vector2i
var length: int

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_unit_tether(self.who, self.length)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.length = int(details['length'])
