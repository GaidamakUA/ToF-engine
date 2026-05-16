class_name Abilities
var board: Board

func _init(_board: Board) -> void:
    self.board = _board

func execute_ability(ability: Ability, context_object: MapTile) -> void:
    ability.execute(self.board, context_object.position)

func get_modified_cost(cost: int, template_name: String, source: Variant) -> int:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(source)
    var modified_cost := cost

    for ability: PassiveAbility in passive_abilities:
        modified_cost = ability.get_modified_cost(modified_cost, template_name)

    if modified_cost < 0:
        modified_cost = 1

    return modified_cost

func get_modified_cooldown(cd_value: int, source: Variant) -> int:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(source)
    var modified_cd := cd_value

    for ability: PassiveAbility in passive_abilities:
        modified_cd = ability.get_modified_cooldown(modified_cd)

    return modified_cd


func get_modified_ap_gain(value: int, source: Variant) -> int:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(source)
    var modified_value := value

    for ability: PassiveAbility in passive_abilities:
        modified_value = ability.get_modified_ap_gain(modified_value, source.template_name)

    return modified_value

func get_initial_level(template_name: String, source: Variant) -> int:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(source)
    var initial_level := 0

    for ability: PassiveAbility in passive_abilities:
        initial_level = ability.get_initial_level(initial_level, template_name)

    return initial_level

func apply_passive_modifiers(unit: BaseUnit) -> void:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(unit)
    var modifiers: Dictionary = {}

    for ability: PassiveAbility in passive_abilities:
        modifiers = ability.get_passive_modifiers(unit.template_name)
        for modifier_name: String in modifiers:
            unit.apply_modifier(modifier_name, modifiers[modifier_name])

func can_intimidate_crew(source: Variant) -> bool:
    var passive_abilities: Array[PassiveAbility] = self._get_passives_for_source(source)

    for ability: PassiveAbility in passive_abilities:
        if ability.can_intimidate_crew():
            return true

    return false

func _get_passives_for_source(source: Variant) -> Array[PassiveAbility]:
    if source.side == "neutral":
        return []

    var abilities: Array[PassiveAbility] = []
    var heroes: Array[HeroUnit] = self.board.state.get_heroes_for_side(source.side)

    for hero: HeroUnit in heroes:
        if hero.has_passive_ability():
            abilities.append(hero.passive_ability)

    return abilities
