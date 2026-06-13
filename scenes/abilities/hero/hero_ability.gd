extends Ability
class_name HeroAbility

func _init() -> void:
    self.TYPE = "hero"


func get_cooldown(source: Variant = null) -> int:
    var modified_cooldown := self.cooldown
    if source != null and source.level == 3:
        modified_cooldown = max(modified_cooldown - 1, 1)

    return modified_cooldown
