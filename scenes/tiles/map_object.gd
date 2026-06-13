extends Node3D

class_name MapObject

@export var template_name: String = ""

@export var main_tile_view_cam_modifier: int = 0
@export var side_tile_view_cam_modifier: int = 0
@export var tile_view_height_cam_modifier: float = 0.0

var current_rotation: int = 0

func get_dict() -> Dictionary[String, Variant]:
    return {
        "tile" : self.template_name,
        "rotation" : self.current_rotation
    }

func reset_position_for_tile_view() -> void:
    return

func disable_shadow() -> void:
    return

func enable_shadow() -> void:
    return
