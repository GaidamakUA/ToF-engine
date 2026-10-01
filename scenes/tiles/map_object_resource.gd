extends Resource
class_name MapObjectResource

@export var mesh: Mesh = null
@export var mesh_transform: Transform3D = Transform3D.IDENTITY
@export var mesh_cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
@export var mesh_material_override: Material = null
@export var reflection_mesh: Mesh = null

@export_file("*.res") var tof_impostor_path: String = ""
@export var tof_impostor_origin: Vector2 = Vector2.ZERO

@export var main_tile_view_cam_modifier: int = 0
@export var side_tile_view_cam_modifier: int = 0
@export var tile_view_height_cam_modifier: float = 0.0
