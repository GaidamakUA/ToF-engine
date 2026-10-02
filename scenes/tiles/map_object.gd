extends Node3D

class_name MapObject

const IMPOSTOR_RENDER_PRIORITY: int = 1

@export var template_name: String = ""

@export var main_tile_view_cam_modifier: int = 0
@export var side_tile_view_cam_modifier: int = 0
@export var tile_view_height_cam_modifier: float = 0.0

var current_rotation: int = 0
var _impostor_priority_enabled: bool = false

func set_impostor_priority(enabled: bool) -> void:
    self._impostor_priority_enabled = enabled
    self._sync_impostor_overlay_materials()

func _get_impostor_priority_meshes() -> Array[MeshInstance3D]:
    return []

func _sync_impostor_overlay_materials() -> void:
    for source: MeshInstance3D in self._get_impostor_priority_meshes():
        source.material_overlay = null
        if not self._impostor_priority_enabled or source.mesh == null \
            or source.mesh.get_surface_count() == 0:
            continue
        source.material_overlay = self._make_impostor_overlay_material(
            source.get_active_material(0)
        )

func _make_impostor_overlay_material(material: Material) -> Material:
    if material == null:
        return null
    var overlay: BaseMaterial3D = material.duplicate() as BaseMaterial3D
    if overlay == null:
        return null
    overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    overlay.no_depth_test = true
    overlay.render_priority = self.IMPOSTOR_RENDER_PRIORITY
    return overlay

func get_dict() -> Dictionary[String, Variant]:
    return {
        "tile" : self.template_name,
        "rotation" : self.current_rotation
    }

func reset_position_for_tile_view() -> void:
    return
