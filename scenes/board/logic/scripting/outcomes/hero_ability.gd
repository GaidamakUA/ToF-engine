extends BaseOutcome
class_name HeroAbilityOutcome

var side: String
var suspended: bool

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_hero_abilities_disabled(self.side, self.suspended)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.side = String(details['side'])
    self.suspended = bool(details['suspended'])
