extends Resource
class_name UnitResource

@export var mesh: ArrayMesh = null
@export var mesh_transform: Transform3D = Transform3D.IDENTITY
@export var healthbar_offset: Vector2 = Vector2(0, 300)
@export var explosion_transform: Transform3D = Transform3D.IDENTITY
@export var dust_visible: bool = true

@export var unit_name: String = ""
@export var side: String = "neutral"
@export var material_type: String = "normal"

@export var max_hp: int = 10
@export var max_move: int = 4
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
@export var perform_extra_lookup: bool = false

@export var passive_ability: Resource = null
@export var active_abilities: Array[Resource] = []
@export var active_abilities_require_level: bool = true

@export var main_tile_view_cam_modifier: int = 0
@export var side_tile_view_cam_modifier: int = 0
@export var tile_view_height_cam_modifier: float = 0.0

@export var audio_streams: Dictionary[String, AudioStream] = {}
