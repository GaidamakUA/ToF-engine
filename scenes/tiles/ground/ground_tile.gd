extends BaseTile
class_name GroundTile

const DEFAULT_MATERIAL: Material = preload("res://assets/materials/arne32.tres")
const REFLECTION_MATERIAL: Material = preload("res://assets/materials/arne32_reflective.tres")

func configure(resource: GroundTileResource) -> void:
    assert(resource != null)

    self.unit_can_stand = resource.unit_can_stand
    self.unit_can_fly = resource.unit_can_fly
    self.is_invisible = resource.is_invisible
    self.can_share_space = resource.can_share_space
    self.unit_vertical_offset = resource.unit_vertical_offset
    self.next_damage_stage_template = resource.next_damage_stage_template
    self.base_stage_template = resource.base_stage_template
    self.shadow_override = resource.shadow_override
    self.main_tile_view_cam_modifier = resource.main_tile_view_cam_modifier
    self.side_tile_view_cam_modifier = resource.side_tile_view_cam_modifier
    self.tile_view_height_cam_modifier = resource.tile_view_height_cam_modifier

    var mesh_instance: MeshInstance3D = $"mesh" as MeshInstance3D
    mesh_instance.mesh = resource.mesh
    mesh_instance.set_surface_override_material(0, self.DEFAULT_MATERIAL)

    var reflection: MeshInstance3D = $"reflection" as MeshInstance3D
    reflection.mesh = resource.reflection_mesh
    reflection.visible = resource.reflection_mesh != null
    if resource.reflection_mesh != null:
        reflection.set_surface_override_material(0, self.REFLECTION_MATERIAL)
