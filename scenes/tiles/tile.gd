extends MapObject

class_name BaseTile

@export var unit_can_stand: bool = false
@export var unit_can_fly: bool = false
@export var is_invisible: bool = false
@export var can_share_space: bool = false

@export var unit_vertical_offset: int = 0

@export var next_damage_stage_template: String = ""
@export var base_stage_template: String = ""

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
