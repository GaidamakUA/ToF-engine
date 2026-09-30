extends BaseOutcome
class_name AttackOutcome

var who: Vector2i
var whom: Vector2i
var damage: int = 0

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.scripted_attack(self.who, self.whom, self.damage)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.whom = Vector2i(details['whom'][0], details['whom'][1])
    if details.has('damage'):
        self.damage = int(details['damage'])
