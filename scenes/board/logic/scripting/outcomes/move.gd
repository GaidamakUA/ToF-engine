extends BaseOutcome
class_name MoveOutcome

var who: Vector2i
var where: Vector2i
var path: Array[String]

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.relocate_unit(self.who, self.where, self.path)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.path.assign(details['path'])
