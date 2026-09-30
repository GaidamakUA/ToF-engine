extends BaseOutcome
class_name ClaimOutcome

var what: Vector2i
var side: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_building_side(self.what, self.side)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.what = Vector2i(details['what'][0], details['what'][1])
    self.side = String(details['side'])
