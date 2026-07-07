extends RefCounted
class_name AbilityState

var disabled: bool = false
var cd_turns_left: int = 0

func is_on_cooldown() -> bool:
    return self.cd_turns_left > 0

func reset_cooldown() -> void:
    self.cd_turns_left = 0

func activate_cooldown(ability: Ability, board: Board, source: Variant) -> void:
    self.cd_turns_left = board.abilities.get_modified_cooldown(ability.get_cooldown(source), source)

func activate_cooldown_model(ability: Ability, abilities: Abilities, source: Variant) -> void:
    if abilities == null:
        self.cd_turns_left = ability.get_cooldown(source)
        return
    self.cd_turns_left = abilities.get_modified_cooldown(ability.get_cooldown(source), source)

func tick_cooldown() -> void:
    if self.cd_turns_left > 0:
        self.cd_turns_left -= 1
