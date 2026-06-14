extends BaseTile
class_name BaseGround

@onready var mouse_collision: Area3D = $mouse_collision
var tile_position := Vector2i(0, 0)
var map: Map = null

func bind_ground_for_mouse(map: Map, tile_position: Vector2i) -> void:
    self.map = map
    self.tile_position = tile_position

func _on_mouse_collision_mouse_entered() -> void:
    if self.map != null:
        self.map.set_mouse_box_position(self.tile_position)
