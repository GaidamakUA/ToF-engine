extends BaseOutcome
class_name RevivePlayerOutcome

var side: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.revive_player(self.side)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.side = String(details['side'])
