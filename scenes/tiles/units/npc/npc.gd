extends BaseUnit

func can_attack(_unit: BaseUnit) -> bool:
    return false

func set_side_material(material: Resource) -> void:
    if material == null:
        return

    super.set_side_material(material)
    $"mesh_anchor/standard".set_surface_override_material(0, material)

func disable_shadow() -> void:
    super.disable_shadow()

    var standard_mesh: MeshInstance3D = $"mesh_anchor/standard" as MeshInstance3D
    assert(standard_mesh != null)
    standard_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func reset_position_for_tile_view() -> void:
    super.reset_position_for_tile_view()
    $"mesh_anchor/standard".hide()
