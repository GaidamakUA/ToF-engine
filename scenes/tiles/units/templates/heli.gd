extends BaseUnit
class_name Heli

var passenger: BaseUnit = null

func disable_shadow() -> void:
    super.disable_shadow()

    for child: Node in $"mesh_anchor/mesh/rotor".get_children():
        var child_mesh: MeshInstance3D = child as MeshInstance3D
        if child_mesh != null:
            child_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        if child is Node3D:
            for subchild: Node in child.get_children():
                var subchild_mesh: MeshInstance3D = subchild as MeshInstance3D
                if subchild_mesh != null:
                    subchild_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func get_dict() -> Dictionary[String, Variant]:
    var new_dict: Dictionary[String, Variant] = super.get_dict()

    if self.passenger != null:
        new_dict["passenger"] = self.passenger.get_dict()

    return new_dict
