extends BaseOutcome
class_name LevelUpOutcome

var who: Vector2i

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.level_up_unit(self.who)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
