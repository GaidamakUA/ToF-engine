extends MapObject

class_name BaseTile

@export var unit_can_stand: bool = false
@export var unit_can_fly: bool = false
@export var is_invisible: bool = false
@export var can_share_space: bool = false

@export var unit_vertical_offset: int = 0

@export var next_damage_stage_template: String = ""
@export var base_stage_template: String = ""

@export var shadow_override: bool = false

func reset_position_for_tile_view() -> void:
    var mesh_position: Vector3 = $"mesh".get_position()
    mesh_position.y = 0

    $"mesh".set_position(mesh_position)

func is_damageable() -> bool:
    return not self.next_damage_stage_template == ""

func is_restoreable() -> bool:
    return not self.base_stage_template == ""

func hide_mesh() -> void:
    $"mesh".hide()

func disable_shadow() -> void:
    self._set_shadow(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

func enable_shadow() -> void:
    self._set_shadow(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

func _set_shadow(shadow_value: GeometryInstance3D.ShadowCastingSetting) -> void:
    var mesh: GeometryInstance3D = $"mesh" as GeometryInstance3D
    assert(mesh != null)
    mesh.cast_shadow = shadow_value

    var reflection: GeometryInstance3D = self.get_node_or_null("reflection") as GeometryInstance3D
    if reflection != null:
        reflection.cast_shadow = shadow_value

    for child: Node in $"mesh".get_children():
        var child_mesh: MeshInstance3D = child as MeshInstance3D
        if child_mesh != null:
            child_mesh.cast_shadow = shadow_value

    for child: Node in self.get_children():
        if child is Node3D:
            for next_child: Node in child.get_children():
                var next_child_mesh: MeshInstance3D = next_child as MeshInstance3D
                if next_child_mesh != null:
                    next_child_mesh.cast_shadow = shadow_value
                    return
