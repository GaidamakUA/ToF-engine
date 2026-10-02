extends MapObject
class_name BaseUnit

signal move_finished

const MAX_LEVEL: int = 3
const EXP_PER_LEVEL: int = 2
const ROTOR_MATERIAL: Material = preload("res://assets/materials/arne32.tres")

@onready var animations: AnimationPlayer = $"animations"
@onready var spotlight: SpotLight3D = $"mesh_anchor/activity_light"
@onready var explosion: Variant = $"explosion"
@onready var level_star: Node3D = $"voxel_star"

var enable_healthbar: bool = false
@onready var healthbar_sprite: Sprite3D = $"mesh_anchor/healthbar"
@onready var healthbar: TextureProgressBar = $"mesh_anchor/healthbar/SubViewport/bar"
@onready var healthbar_lv1: Node2D = $"mesh_anchor/healthbar/SubViewport/level1"
@onready var healthbar_lv2: Node2D = $"mesh_anchor/healthbar/SubViewport/level2"
@onready var healthbar_lv3: Node2D = $"mesh_anchor/healthbar/SubViewport/level3"

@onready var energybar: TextureProgressBar = $"mesh_anchor/healthbar/SubViewport/energy"

@export var unit_name: String = ""
@export var side: String = "neutral"
var model_id: int = 0
var state: UnitState = UnitState.new()
var team: Variant:
    get:
        return self.state.team
    set(value):
        self.state.team = value
@export var material_type: String = "normal"

@export var max_hp: int = 10
var hp: int:
    get:
        return self.state.hp
    set(value):
        self.state.hp = value
@export var max_move: int = 4
var move: int:
    get:
        return self.state.move
    set(value):
        self.state.move = value
@export var attack: int = 7
@export var armor: int = 2
@export var can_capture: bool = false
@export var can_fly: bool = false
@export var can_attack_units: bool = true
@export var can_attack_air: bool = true
@export var max_attacks: int = 1
@export var uses_metallic_material: bool = false
@export var unit_value: int = 0
@export var unit_class: String = ""
var attacks: int:
    get:
        return self.state.attacks
    set(value):
        self.state.attacks = value
var level: int:
    get:
        return self.state.level
    set(value):
        self.state.level = value
var experience: int:
    get:
        return self.state.experience
    set(value):
        self.state.experience = value
var kills: int:
    get:
        return self.state.kills
    set(value):
        self.state.kills = value
var passenger: BaseUnit = null

# AI modifiers
var ai_paused: bool:
    get:
        return self.state.ai_paused
    set(value):
        self.state.ai_paused = value
var tether_point := Vector2i(0, 0)
var tether_length: int = 0
@export var perform_extra_lookup: bool = false
# AI modifiers end

var modifiers: Dictionary[String, Variant]:
    get:
        return self.state.modifiers
    set(value):
        self.state.modifiers.clear()
        self.state.modifiers.assign(value)
var scripting_tags: Dictionary[String, Variant]:
    get:
        return self.state.scripting_tags
    set(value):
        self.state.scripting_tags.clear()
        self.state.scripting_tags.assign(value)
@export var passive_ability: Resource = null
@export var active_abilities: Array = []
@export var active_abilities_require_level: bool = true
var ability_states: Dictionary:
    get:
        return self.state.ability_states
    set(value):
        self.state.ability_states.clear()
        self.state.ability_states.assign(value)
var allow_level_up: bool = true

var unit_rotations: Dictionary[String, int] = {
    "s" : 0,
    "n" : 180,
    "e" : 90,
    "w" : 270,
}
var unit_translations: Dictionary[String, Vector3] = {
    "n" : Vector3(0, 0, -8),
    "s" : Vector3(0, 0, 8),
    "e" : Vector3(8, 0, 0),
    "w" : Vector3(-8, 0, 0),
}
var current_path: Array[String] = []
var current_path_index: int = 0


var base_material: Resource = null
var desaturated_material: Resource = null
var _rotor_pivots: Array[Node3D] = []
var _rotor_axes: Array[Vector3] = []

func _ready() -> void:
    self.animations.animation_finished.connect(_on_animation_finished)
    self.healthbar_sprite.texture = $"mesh_anchor/healthbar/SubViewport".get_texture()
    self._setup_abilities()

func _process(delta: float) -> void:
    for index: int in self._rotor_pivots.size():
        self._rotor_pivots[index].rotate_object_local(
            self._rotor_axes[index], UnitResource.ROTOR_SPEED * delta
        )

func configure(resource: UnitResource) -> void:
    var mesh_instance: MeshInstance3D = $"mesh_anchor/mesh" as MeshInstance3D
    mesh_instance.mesh = resource.mesh
    mesh_instance.transform = resource.mesh_transform
    mesh_instance.cast_shadow = resource.mesh_cast_shadow
    mesh_instance.material_override = resource.mesh_material_override
    self._configure_rotors(resource, mesh_instance)
    ($"mesh_anchor/dust" as GPUParticles3D).visible = resource.dust_visible
    ($"mesh_anchor/healthbar" as Sprite3D).offset = resource.healthbar_offset
    ($"explosion" as Node3D).transform = resource.explosion_transform

    self.unit_name = resource.unit_name
    self.side = resource.side
    self.material_type = resource.material_type
    self.max_hp = resource.max_hp
    self.max_move = resource.max_move
    self.attack = resource.attack
    self.armor = resource.armor
    self.can_capture = resource.can_capture
    self.can_fly = resource.can_fly
    self.can_attack_units = resource.can_attack_units
    self.can_attack_air = resource.can_attack_air
    self.max_attacks = resource.max_attacks
    self.uses_metallic_material = resource.uses_metallic_material
    self.unit_value = resource.unit_value
    self.unit_class = resource.unit_class
    self.perform_extra_lookup = resource.perform_extra_lookup
    self.passive_ability = resource.passive_ability
    self.active_abilities.assign(resource.active_abilities)
    self.active_abilities_require_level = resource.active_abilities_require_level
    self.main_tile_view_cam_modifier = resource.main_tile_view_cam_modifier
    self.side_tile_view_cam_modifier = resource.side_tile_view_cam_modifier
    self.tile_view_height_cam_modifier = resource.tile_view_height_cam_modifier

    ($"mesh_anchor/healthbar/SubViewport/bar" as TextureProgressBar).max_value = self.max_hp
    ($"mesh_anchor/healthbar/SubViewport/energy" as TextureProgressBar).max_value = self.max_move

    if self.is_node_ready():
        self._setup_abilities()

func _configure_rotors(resource: UnitResource, parent: Node3D) -> void:
    for pivot: Node3D in self._rotor_pivots:
        pivot.free()
    self._rotor_pivots.clear()
    self._rotor_axes.clear()

    for rotor: RotorResource in resource.rotors:
        assert(rotor.mesh != null)
        assert(not rotor.rotation_axis.is_zero_approx())
        var pivot := Node3D.new()
        pivot.transform = rotor.pivot_transform
        parent.add_child(pivot)

        var rotor_mesh := MeshInstance3D.new()
        rotor_mesh.mesh = rotor.mesh
        rotor_mesh.transform = rotor.mesh_transform
        rotor_mesh.cast_shadow = resource.mesh_cast_shadow
        rotor_mesh.material_override = self.ROTOR_MATERIAL
        pivot.add_child(rotor_mesh)

        self._rotor_pivots.append(pivot)
        self._rotor_axes.append(rotor.rotation_axis.normalized())

    self.set_process(not self._rotor_pivots.is_empty())
    if self._impostor_priority_enabled:
        self._sync_impostor_overlay_materials()

func reset() -> void:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()

    self.state.reset_from_stats(stats)
    self._update_healthbar()
    self._update_energy()
    self._update_level()

func get_dict() -> Dictionary[String, Variant]:
    var new_dict: Dictionary[String, Variant] = super.get_dict()
    new_dict["id"] = self.model_id
    new_dict["side"] = self.side
    new_dict["modifiers"] = self.modifiers
    new_dict["ai_paused"] = self.ai_paused
    new_dict["stats"] = self.get_stats_with_modifiers()
    new_dict["abilities"] = self._get_abilities_status()
    new_dict["team"] = self.team
    if self.passenger != null:
        new_dict["passenger"] = self.passenger.get_dict()
    if self.scripting_tags.size() > 0:
        new_dict["tags"] = self.scripting_tags

    return new_dict

func add_script_tag(tag: String) -> void:
    self.state.add_script_tag(tag)

func has_script_tag(tag: String) -> bool:
    return self.state.has_script_tag(tag)

func set_side(new_side: String) -> void:
    self.side = new_side

func set_side_materials(_base_material: Resource, _desaturated_material: Resource) -> void:
    self.base_material = _base_material
    self.desaturated_material = _desaturated_material
    self.set_side_material(self.base_material)

func set_side_material(material: Resource) -> void:
    if material == null:
        return

    for child: Node in $"mesh_anchor".get_children():
        var mesh_instance: MeshInstance3D = child as MeshInstance3D
        if mesh_instance != null:
            mesh_instance.set_surface_override_material(0, material)
    if self._impostor_priority_enabled:
        self._sync_impostor_overlay_materials()

func _get_impostor_priority_meshes() -> Array[MeshInstance3D]:
    var meshes: Array[MeshInstance3D] = []
    for child: Node in $"mesh_anchor".find_children("*", "MeshInstance3D", true, false):
        var mesh_instance: MeshInstance3D = child as MeshInstance3D
        if mesh_instance != null:
            meshes.append(mesh_instance)
    return meshes


func get_stats() -> Dictionary[String, int]:
    return self.state.get_base_stats(self)

func get_stats_with_modifiers() -> Dictionary[String, int]:
    return self.state.get_stats_with_modifiers(self)

func _apply_experience_modifiers(stats: Dictionary[String, int]) -> Dictionary[String, int]:
    if self.level > 1:
        stats["armor"] += 1
    if self.level > 2:
        stats["max_move"] += 1

    return stats

func get_move() -> int:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    return stats["move"]

func has_moves() -> bool:
    return self.move > 0

func use_move(value: int) -> void:
    self.state.use_move(value)
    if self.move < 1:
        self.remove_highlight()
    self._update_energy()

func restore_move(value: int) -> void:
    self.state.restore_move(value)
    self.restore_highlight()
    self._update_energy()

func reset_move() -> void:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    self.state.reset_move(stats)
    self.restore_highlight()
    self._update_energy()

func replenish_moves() -> void:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    self.state.replenish_moves(stats)
    self.restore_highlight()
    self._update_energy()

func remove_moves() -> void:
    self.state.remove_moves()
    self.remove_highlight()
    self._update_energy()

func can_attack_unit(unit: BaseUnit) -> bool:
    if unit == null:
        return false

    if not self.can_attack_units:
        return false

    if unit.can_fly:
        return self.can_attack_air or self.modifiers.has("attack_air")

    return true

func can_kill(unit: BaseUnit) -> bool:
    if not self.has_attacks() or not self.has_moves() or not self.can_attack_unit(unit):
        return false

    return self.has_enough_power_to_kill(unit)

func can_retaliate(unit: BaseUnit) -> bool:
    if not self.has_moves() or not self.can_attack_unit(unit):
        return false

    return true

func has_enough_power_to_kill(unit: BaseUnit) -> bool:
    return self.get_attack() >= unit.hp + unit.get_armor()

func has_attacks() -> bool:
    return self.attacks > 0

func use_attack() -> void:
    self.state.use_attack()

func rotate_unit_to_direction(direction: String) -> void:
    if not self.unit_rotations.has(direction):
        return

    var unit_rotation: int = self.unit_rotations[direction]
    self.set_rotation(Vector3(0, deg_to_rad(unit_rotation), 0))
    self.current_rotation = unit_rotation

func animate_path(path: Array) -> void:
    self.current_path.clear()
    self.current_path.assign(path)
    self.current_path_index = 0
    self._animate_initial_path_segment()

func _animate_initial_path_segment() -> void:
    var direction: String = self.current_path[self.current_path_index]
    self.move_in_direction(direction)

func _animate_next_path_segment() -> void:
    if self.current_path.size() == 0:
        return

    var direction: String = self.current_path[self.current_path_index]
    _reset_anchor_position()
    self.set_position(self.get_position() + self.unit_translations[direction])
    self.current_path_index += 1
    direction = self.current_path[self.current_path_index]
    self.move_in_direction(direction)

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name == "move":
        _animate_next_path_segment()

func move_in_direction(direction: String) -> void:
    self.rotate_unit_to_direction(direction)
    if self.current_path_index < self.current_path.size() - 1:
        self.animations.play("move")
    else:
        self.move_finished.emit()

func _reset_anchor_position() -> void:
    $"mesh_anchor".set_position(Vector3(0, 0, 0))

func reset_position_for_tile_view() -> void:
    var mesh_position: Vector3 = $"mesh_anchor/mesh".get_position()
    mesh_position.y = 0

    $"mesh_anchor/mesh".set_position(mesh_position)
    self.remove_highlight()

func show_explosion() -> void:
    self.explosion.explode_a_bit()

func set_hp(value: int) -> void:
    self.state.set_hp(value)
    self._update_healthbar()

func is_alive() -> bool:
    return self.hp > 0


func is_damaged() -> bool:
    return hp < max_hp


func get_attack() -> int:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    return stats["attack"]

func get_armor() -> int:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    return stats["armor"]

func remove_highlight() -> void:
    self.set_side_material(self.desaturated_material)
    #$"mesh_anchor/activity_light".hide()

func restore_highlight() -> void:
    if self.ai_paused:
        return
    self.set_side_material(self.base_material)
    #self.spotlight.show()

func register_ability(ability: Ability) -> void:
    if ability.TYPE == "active":
        self.active_abilities.append(ability)
    self.get_ability_state(ability)

func _setup_abilities() -> void:
    for ability: Ability in self.active_abilities:
        self.get_ability_state(ability)

func get_ability_state(ability: Ability) -> AbilityState:
    return self.state.get_ability_state(ability)

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

func has_active_ability() -> bool:
    return self.active_abilities.size() > 0 and (not self.active_abilities_require_level or self.level > 0)

func ability_cd_tick_down() -> void:
    for ability: Ability in self.active_abilities:
        self.get_ability_state(ability).tick_cooldown()

func reset_cooldown() -> void:
    for ability: Ability in self.active_abilities:
        self.get_ability_state(ability).reset_cooldown()

func apply_modifier(modifier_name: String, value: Variant) -> void:
    self.state.apply_modifier(modifier_name, value)

func clear_modifiers() -> void:
    self.state.clear_modifiers()

func animate_level_up() -> void:
    self.animations.play("level_up")
    self._update_level()

func refresh_state_view() -> void:
    self._update_healthbar()
    self._update_energy()
    self._update_level()

func is_max_level() -> bool:
    return self.level >= self.MAX_LEVEL

func heal(value: int) -> void:
    var stats: Dictionary[String, int] = self.get_stats_with_modifiers()
    self.state.heal(value, stats)
    self._update_healthbar()

func get_value() -> int:
    return self.unit_value + self.level * 10


func _get_abilities_status() -> Dictionary[String, Array]:
    return self.state.get_abilities_status(self.active_abilities)

func restore_from_state(state: Dictionary) -> void:
    var stats: Dictionary[String, int]
    stats.assign(state["stats"])

    var abilities_status: Dictionary[String, Array]
    abilities_status.assign(state["abilities"])

    if state.has("tags"):
        self.scripting_tags.assign(state["tags"])
    if state.has("id"):
        self.model_id = int(state["id"])
    self.hp = stats["hp"]
    self.move = stats["move"]
    self.attacks = stats["attacks"]
    self.level = stats["level"]
    self.experience = stats["experience"]
    self.kills = stats["kills"]
    self.team = state["team"]
    self.modifiers.clear()
    self.modifiers.assign(state["modifiers"])

    self._update_healthbar()
    self._update_energy()
    self._update_level()

    if self.move < 1:
        self.remove_highlight()

    self.state.restore_abilities_status(self.active_abilities, abilities_status)

func disable_dlc_abilities(editor_version: int) -> void:
    for ability: Ability in self.active_abilities:
        if ability.dlc_version > editor_version:
            self.set_ability_disabled(ability, true)

func is_hero() -> bool:
    return false

func _update_healthbar() -> void:
    if self.healthbar != null:
        self.healthbar.max_value = self.max_hp
        self.healthbar.value = self.hp

func _update_level() -> void:
    if self.healthbar == null:
        return
    self.healthbar_lv1.hide()
    self.healthbar_lv2.hide()
    self.healthbar_lv3.hide()
    if self.level == 1:
        self.healthbar_lv1.show()
    if self.level == 2:
        self.healthbar_lv2.show()
    if self.level == 3:
        self.healthbar_lv3.show()

func _update_energy() -> void:
    if self.energybar != null:
        self.energybar.value = self.move
        self.energybar.max_value = self.max_move

func enable_health() -> void:
    self.enable_healthbar = true
    self.show_health()
func show_health() -> void:
    if not self.enable_healthbar:
        return
    self.healthbar_sprite.show()
func hide_health() -> void:
    self.healthbar_sprite.hide()
