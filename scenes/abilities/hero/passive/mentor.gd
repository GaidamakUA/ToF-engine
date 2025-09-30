extends PassiveAbility

const INFANTRY_TEMPLATES: Array[String] = [
    "blue_infantry",
    "blue_m_inf",
    "red_infantry",
    "red_m_inf",
    "green_infantry",
    "green_m_inf",
    "yellow_infantry",
    "yellow_m_inf",
]

func get_initial_level(initial_level: int, template_name: String) -> int:
    if template_name in self.INFANTRY_TEMPLATES:
        return 1

    return initial_level
