extends PassiveAbility

const TOWER_TEMPLATES: Array[String] = [
    "modern_tower",
    "steampunk_tower",
    "futuristic_tower",
    "feudal_tower",
]

func get_modified_ap_gain(value: int, template_name: String) -> int:
    if template_name in self.TOWER_TEMPLATES:
        return value + 5

    return value
