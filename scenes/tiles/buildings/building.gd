extends MapObject
class_name BaseBuilding

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

@onready var animations: AnimationPlayer = $"animations"

@export var side: String = "neutral"
var team: Variant = null

@export var require_crew: bool = true

@export var ap_gain: int = 5

@export var capture_value: int = 70

@export var uses_metallic_material: bool = false

@export var abilities: Array = []
var ability_states: Dictionary = {}

func _ready() -> void:
    self._setup_abilities()

func _setup_abilities() -> void:
    for ability: Ability in self.abilities:
        self.get_ability_state(ability)

func get_dict() -> Dictionary[String, Variant]:
    var new_dict: Dictionary[String, Variant] = super.get_dict()
    new_dict["side"] = self.side
    new_dict["abilities"] = self._get_abilities_status()

    return new_dict

func set_side(new_side: String) -> void:
    self.side = new_side

func set_team(new_team: Variant) -> void:
    self.team = new_team

func set_side_materials(_base_material: Resource, _desaturated_material: Resource) -> void:
    self.set_side_material(_base_material)

func set_side_material(material: Resource) -> void:
    $"mesh".set_surface_override_material(0, material)

func register_ability(ability: Ability) -> void:
    self.abilities.append(ability)
    self.get_ability_state(ability)

func get_ability_state(ability: Ability) -> AbilityState:
    if not self.ability_states.has(ability):
        self.ability_states[ability] = AbilityState.new()

    return self.ability_states[ability]

func is_ability_visible(ability: Ability, board: Board = null) -> bool:
    return ability.is_visible(self.get_ability_state(ability), board, self)

func is_ability_on_cooldown(ability: Ability) -> bool:
    return self.get_ability_state(ability).is_on_cooldown()

func get_ability_cooldown(ability: Ability) -> int:
    return self.get_ability_state(ability).cd_turns_left

func set_ability_disabled(ability: Ability, disabled: bool) -> void:
    self.get_ability_state(ability).disabled = disabled

func is_ability_disabled(ability: Ability) -> bool:
    return self.get_ability_state(ability).disabled

func activate_ability_cooldown(ability: Ability, board: Board) -> void:
    self.get_ability_state(ability).activate_cooldown(ability, board, self)

func animate_coin() -> void:
    self.animations.play("ap_gain")

func sfx_effect(sfx_name: String) -> void:
    if not self.audio.sounds_enabled:
        return

    var audio_player: AudioStreamPlayer3D = self.get_node_or_null("audio/" + sfx_name)
    if audio_player != null:
        audio_player.play()

func _get_abilities_status() -> Dictionary[String, bool]:
    var status: Dictionary[String, bool] = {}

    for ability: Ability in self.abilities:
        status["ability" + str(ability.index)] = self.get_ability_state(ability).disabled

    return status

func restore_abilities_status(status: Dictionary) -> void:
    var key: String
    for ability: Ability in self.abilities:
        key = "ability" + str(ability.index)
        if status.has(key):
            self.set_ability_disabled(ability, bool(status[key]))

func disable_dlc_abilities(editor_version: int) -> void:
    for ability: Ability in self.abilities:
        if ability.dlc_version > editor_version:
            self.set_ability_disabled(ability, true)
