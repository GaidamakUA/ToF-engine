extends BaseOutcome
class_name PauseAiOutcome

var who: Vector2i
var pause: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_unit_ai_paused(self.who, self.pause)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.pause = bool(details['pause'])
