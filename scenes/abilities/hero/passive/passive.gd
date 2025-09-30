extends HeroAbility
class_name PassiveAbility

func _init() -> void:
    self.TYPE = "hero_passive"

func get_modified_cost(cost: int, _template_name: String) -> int:
    return cost

func get_modified_cooldown(cd_value: int) -> int:
    return cd_value

func get_modified_ap_gain(value: int, _template_name: String) -> int:
    return value

func get_initial_level(initial_level: int, _template_name: String) -> int:
    return initial_level

func get_passive_modifiers(_template_name: String) -> Dictionary:
    return {}

func can_intimidate_crew() -> bool:
    return false
