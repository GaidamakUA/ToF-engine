extends RefCounted
class_name UnitState


var hp: int = 0
var move: int = 0
var attacks: int = 1
var level: int = 0
var experience: int = 0
var kills: int = 0
var team: Variant = null
var ai_paused: bool = false
var modifiers: Dictionary[String, Variant] = {}
var scripting_tags: Dictionary[String, Variant] = {}
var ability_states: Dictionary = {}


func reset_from_stats(stats: Dictionary[String, int]) -> void:
    self.hp = stats["max_hp"]
    self.move = stats["max_move"]
    self.attacks = stats["max_attacks"]


func get_base_stats(unit: Variant) -> Dictionary[String, int]:
    var stats: Dictionary[String, int] = {
        "hp" : self.hp,
        "move" : self.move,
        "attack" : unit.attack,
        "armor" : unit.armor,
        "max_move" : unit.max_move,
        "max_hp" : unit.max_hp,
        "attacks" : self.attacks,
        "max_attacks" : unit.max_attacks,
        "level" : self.level,
        "experience" : self.experience,
        "kills" : self.kills,
    }

    return stats


func get_stats_with_modifiers(unit: Variant) -> Dictionary[String, int]:
    var stats: Dictionary[String, int] = self.get_base_stats(unit)

    for stat_key: String in stats:
        if self.modifiers.has(stat_key):
            stats[stat_key] += int(self.modifiers[stat_key])

    return unit._apply_experience_modifiers(stats)


func get_ability_state(ability: Ability) -> AbilityState:
    if not self.ability_states.has(ability):
        self.ability_states[ability] = AbilityState.new()

    return self.ability_states[ability]


func get_abilities_status(active_abilities: Array) -> Dictionary[String, Array]:
    var status: Dictionary[String, Array] = {}

    for ability: Ability in active_abilities:
        var ability_state: AbilityState = self.get_ability_state(ability)
        status["ability" + str(ability.index)] = [ability_state.disabled, ability_state.cd_turns_left]

    return status


func restore_abilities_status(active_abilities: Array, status: Dictionary[String, Array]) -> void:
    var key: String
    for ability: Ability in active_abilities:
        key = "ability" + str(ability.index)
        if status.has(key):
            var ability_state: AbilityState = self.get_ability_state(ability)
            ability_state.disabled = bool(status[key][0])
            ability_state.cd_turns_left = int(status[key][1])


func add_script_tag(tag: String) -> void:
    self.scripting_tags[tag] = true


func has_script_tag(tag: String) -> bool:
    return self.scripting_tags.has(tag)


func apply_modifier(modifier_name: String, value: Variant) -> void:
    self.modifiers[modifier_name] = value


func clear_modifiers() -> void:
    self.modifiers.clear()


func use_move(value: int) -> void:
    self.move -= value


func restore_move(value: int) -> void:
    self.move += value


func reset_move(stats: Dictionary[String, int]) -> void:
    self.move = stats["max_move"]


func replenish_moves(stats: Dictionary[String, int]) -> void:
    self.reset_move(stats)
    self.attacks = stats["max_attacks"]


func remove_moves() -> void:
    self.attacks = 0
    self.move = 0


func use_attack() -> void:
    self.attacks -= 1


func receive_direct_damage(value: int) -> void:
    self.hp -= value
    if self.hp < 0:
        self.hp = 0


func set_hp(value: int) -> void:
    self.hp = value


func heal(value: int, stats: Dictionary[String, int]) -> void:
    self.hp += value
    if self.hp > stats["max_hp"]:
        self.hp = stats["max_hp"]


func score_kill() -> void:
    self.kills += 1


func gain_exp(exp_per_level: int) -> bool:
    self.experience += 1
    if self.experience == exp_per_level:
        self.experience = 0
        return true
    return false


func level_up() -> void:
    self.level += 1
