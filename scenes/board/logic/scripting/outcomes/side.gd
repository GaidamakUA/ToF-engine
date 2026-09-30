extends BaseOutcome
class_name SideOutcome

var who: Vector2i
var side: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_unit_side(self.who, self.side)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.side = String(details['side'])
