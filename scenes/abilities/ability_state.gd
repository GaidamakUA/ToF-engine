extends RefCounted
class_name AbilityState

var disabled: bool = false
var cd_turns_left: int = 0

func is_on_cooldown() -> bool:
    return self.cd_turns_left > 0

func reset_cooldown() -> void:
    self.cd_turns_left = 0

func tick_cooldown() -> void:
    if self.cd_turns_left > 0:
        self.cd_turns_left -= 1
