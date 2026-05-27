extends Node3D
class_name MovementMarker

func set_material(material: Material) -> void:
    $"offset/mesh1".set_surface_override_material(0, material)
    $"offset/mesh2".set_surface_override_material(0, material)
