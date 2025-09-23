extends Ability
class_name HeroAbility

func _init() -> void:
	self.TYPE = "hero"


func get_cooldown() -> int:
	var modified_cooldown := self.cooldown
	if self.source != null and self.source.level == 3:
		modified_cooldown = max(modified_cooldown - 1, 1)

	return modified_cooldown
