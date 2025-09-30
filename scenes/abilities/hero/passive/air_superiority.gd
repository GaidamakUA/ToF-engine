extends PassiveAbility

const AIR_TEMPLATES: Array[String] = [
    "blue_heli",
    "blue_scout",
    "red_heli",
    "red_scout",
    "green_heli",
    "green_scout",
    "yellow_heli",
    "yellow_scout",
]

func get_modified_cost(cost: int, template_name: String) -> int:
    if template_name in self.AIR_TEMPLATES:
        return cost - 10

    return cost
