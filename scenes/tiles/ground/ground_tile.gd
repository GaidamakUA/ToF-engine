extends BaseTile
class_name GroundTile

const DEFAULT_MATERIAL: Material = preload("res://assets/materials/arne32.tres")
const REFLECTION_MATERIAL: Material = preload("res://assets/materials/arne32_reflective.tres")
const TOF_DEPTH_OFFSET := Vector3(3.01, 2.46, 3.01)
const DECORATION_PATH: String = "res://resources/decoration/"

var _tof_impostor_path: String = ""
var _tof_shadow_path: String = ""
var _tof_impostor_origin := Vector2.ZERO
var _tof_impostor_allowed: bool = true

func configure(resource: TileResource) -> void:
    assert(resource != null)

    self.unit_can_stand = resource.unit_can_stand
    self.unit_can_fly = resource.unit_can_fly
    self.is_invisible = resource.is_invisible
    self.can_share_space = resource.can_share_space
    self.unit_vertical_offset = resource.unit_vertical_offset
    self.next_damage_stage_template = resource.next_damage_stage_template
    self.base_stage_template = resource.base_stage_template
    self.main_tile_view_cam_modifier = resource.main_tile_view_cam_modifier
    self.side_tile_view_cam_modifier = resource.side_tile_view_cam_modifier
    self.tile_view_height_cam_modifier = resource.tile_view_height_cam_modifier

    var mesh_instance: MeshInstance3D = $"mesh" as MeshInstance3D
    mesh_instance.mesh = resource.mesh
    mesh_instance.lod_bias = 0.0
    mesh_instance.transform = resource.mesh_transform
    mesh_instance.cast_shadow = resource.mesh_cast_shadow
    mesh_instance.material_override = resource.mesh_material_override if resource.mesh_material_override != null else self.DEFAULT_MATERIAL

    var reflection: MeshInstance3D = $"reflection" as MeshInstance3D
    reflection.mesh = resource.reflection_mesh
    reflection.visible = resource.reflection_mesh != null
    if resource.reflection_mesh != null:
        reflection.set_surface_override_material(0, self.REFLECTION_MATERIAL)

    var impostor: Sprite3D = $"impostor" as Sprite3D
    impostor.texture = null
    var shadow: Sprite3D = $"impostor_shadow" as Sprite3D
    shadow.texture = null
    self._tof_impostor_path = resource.tof_impostor_path
    self._tof_impostor_allowed = not resource.unit_can_stand \
        and not resource.resource_path.begins_with(self.DECORATION_PATH)
    self._tof_shadow_path = ""
    if not self._tof_impostor_allowed and not resource.tof_impostor_path.is_empty() \
        and resource.mesh_cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
        self._tof_shadow_path = resource.tof_impostor_path.trim_suffix(".res") + "_shadow.res"
    self._tof_impostor_origin = resource.tof_impostor_origin
    for sprite: Sprite3D in [impostor, shadow]:
        sprite.offset = Vector2(-resource.tof_impostor_origin.x, 0.0)
        sprite.pixel_size = resource.tof_impostor_pixel_size
        sprite.position = Vector3.ZERO
        sprite.sorting_offset = 0.0

func set_visual_mode(camera_mode: String) -> void:
    var impostor: Sprite3D = $"impostor" as Sprite3D
    if self._tof_impostor_allowed and camera_mode == GameCamera.MODE_TOF \
        and impostor.texture == null and not self._tof_impostor_path.is_empty():
        impostor.texture = load(self._tof_impostor_path) as Texture2D
        if impostor.texture != null:
            var frame_height: float = float(impostor.texture.get_height()) / float(impostor.vframes)
            impostor.offset.y = self._tof_impostor_origin.y - frame_height
    var shadow: Sprite3D = $"impostor_shadow" as Sprite3D
    if camera_mode == GameCamera.MODE_TOF \
        and shadow.texture == null and not self._tof_shadow_path.is_empty():
        shadow.texture = load(self._tof_shadow_path) as Texture2D
        if shadow.texture != null:
            var frame_height: float = float(shadow.texture.get_height()) / float(shadow.vframes)
            shadow.offset.y = self._tof_impostor_origin.y - frame_height
    var use_impostor: bool = camera_mode == GameCamera.MODE_TOF and impostor.texture != null
    var use_shadow: bool = camera_mode == GameCamera.MODE_TOF and shadow.texture != null
    impostor.visible = use_impostor
    shadow.visible = use_shadow
    var frame: int = int(float(posmod(self.current_rotation, 360)) / 90.0)
    for sprite: Sprite3D in [impostor, shadow]:
        if sprite.visible:
            sprite.global_position = self.global_position + self.TOF_DEPTH_OFFSET
            sprite.frame = frame

    var mesh_instance: MeshInstance3D = $"mesh" as MeshInstance3D
    mesh_instance.visible = not use_impostor

    var reflection: MeshInstance3D = $"reflection" as MeshInstance3D
    reflection.visible = not use_impostor and reflection.mesh != null
