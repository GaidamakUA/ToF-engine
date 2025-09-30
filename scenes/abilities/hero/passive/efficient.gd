extends PassiveAbility

const FACTORY_TEMPLATES: Array[String] = [
    "blue_tank",
    "blue_rocket",
    "red_tank",
    "red_rocket",
    "green_tank",
    "green_rocket",
    "yellow_tank",
    "yellow_rocket",
]

func get_modified_cost(cost: int, template_name: String) -> int:
    if template_name in self.FACTORY_TEMPLATES:
        return cost - 10

    return cost
