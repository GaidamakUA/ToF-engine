extends MapObject
class_name BaseBuilding

@export var side: String = "neutral"
var model_id: int = 0
var team: Variant = null

@export var require_crew: bool = true

@export var ap_gain: int = 5

@export var capture_value: int = 70

@export var uses_metallic_material: bool = false

@export var abilities: Array = []
var ability_states: Dictionary = {}

func configure(resource: BuildingResource) -> void:
    var mesh_instance: MeshInstance3D = $"mesh" as MeshInstance3D
    mesh_instance.mesh = resource.mesh
    mesh_instance.transform = resource.mesh_transform
    mesh_instance.cast_shadow = resource.mesh_cast_shadow
    mesh_instance.material_override = resource.mesh_material_override
    self.side = resource.side
    self.require_crew = resource.require_crew
    self.ap_gain = resource.ap_gain
    self.capture_value = resource.capture_value
    self.uses_metallic_material = resource.uses_metallic_material
    self.abilities.assign(resource.abilities)
    self.main_tile_view_cam_modifier = resource.main_tile_view_cam_modifier
    self.side_tile_view_cam_modifier = resource.side_tile_view_cam_modifier
    self.tile_view_height_cam_modifier = resource.tile_view_height_cam_modifier

    if self.is_node_ready():
        self._setup_abilities()

func _ready() -> void:
    self._setup_abilities()

func _setup_abilities() -> void:
    for ability: Ability in self.abilities:
        self.get_ability_state(ability)

func get_dict() -> Dictionary[String, Variant]:
    var new_dict: Dictionary[String, Variant] = super.get_dict()
    new_dict["id"] = self.model_id
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
    ($"mesh" as MeshInstance3D).material_override = material as Material
    if self._impostor_priority_enabled:
        self._sync_impostor_overlay_materials()

func _get_impostor_priority_meshes() -> Array[MeshInstance3D]:
    return [$"mesh" as MeshInstance3D]

func register_ability(ability: Ability) -> void:
    self.abilities.append(ability)
    self.get_ability_state(ability)

func get_ability_state(ability: Ability) -> AbilityState:
    if not self.ability_states.has(ability):
        self.ability_states[ability] = AbilityState.new()

    return self.ability_states[ability]

func is_ability_visible(ability: Ability, model: BoardModel = null) -> bool:
    return ability.is_visible(self.get_ability_state(ability), model, self)

func is_ability_on_cooldown(ability: Ability) -> bool:
    return self.get_ability_state(ability).is_on_cooldown()

func get_ability_cooldown(ability: Ability) -> int:
    return self.get_ability_state(ability).cd_turns_left

func set_ability_disabled(ability: Ability, disabled: bool) -> void:
    self.get_ability_state(ability).disabled = disabled

func is_ability_disabled(ability: Ability) -> bool:
    return self.get_ability_state(ability).disabled

func _get_abilities_status() -> Dictionary[String, Array]:
    var status: Dictionary[String, Array] = {}

    for ability: Ability in self.abilities:
        var ability_state: AbilityState = self.get_ability_state(ability)
        status["ability" + str(ability.index)] = [ability_state.disabled, ability_state.cd_turns_left]

    return status

func restore_abilities_status(status: Dictionary) -> void:
    var key: String
    for ability: Ability in self.abilities:
        key = "ability" + str(ability.index)
        if status.has(key):
            var value: Variant = status[key]
            var ability_state: AbilityState = self.get_ability_state(ability)
            if value is Array:
                ability_state.disabled = bool(value[0])
                ability_state.cd_turns_left = int(value[1])
            else:
                ability_state.disabled = bool(value)

func disable_dlc_abilities(editor_version: int) -> void:
    for ability: Ability in self.abilities:
        if ability.dlc_version > editor_version:
            self.set_ability_disabled(ability, true)
