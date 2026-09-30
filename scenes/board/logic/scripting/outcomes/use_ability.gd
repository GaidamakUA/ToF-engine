extends BaseOutcome
class_name UseAbilityOutcome

var who: Vector2i
var which: String
var where: Vector2i
var cooldown: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.scripted_use_ability(self.who, self.which, self.where, self.cooldown)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.which = details['which']
    self.where = Vector2i(details['where'][0], details['where'][1])
    if details.has('cooldown'):
        self.cooldown = bool(details['cooldown'])
