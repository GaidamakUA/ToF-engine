extends Resource
class_name GroundTileResource

@export var mesh: Mesh = null
@export var reflection_mesh: Mesh = null

@export var unit_can_stand: bool = false
@export var unit_can_fly: bool = false
@export var is_invisible: bool = false
@export var can_share_space: bool = false
@export var unit_vertical_offset: int = 0
@export var next_damage_stage_template: String = ""
@export var base_stage_template: String = ""
@export var shadow_override: bool = false
@export var main_tile_view_cam_modifier: int = 0
@export var side_tile_view_cam_modifier: int = 0
@export var tile_view_height_cam_modifier: float = 0.0
