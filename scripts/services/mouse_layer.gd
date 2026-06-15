extends Node
class_name MouseLayerService

var initialized: bool = false
var mouse_layer: Node3D = Node3D.new()
var ground_points: Dictionary[Vector2i, BaseGround] = {}
var dummy_ground_template: PackedScene = preload("res://scenes/tiles/ground/mouse_listener_tile.tscn")

func initialize(size: int, tile_size: int) -> void:
    if self.initialized:
        return

    self.initialized = true
    for x: int in range(size):
        for y: int in range(size):
            var key: Vector2i = Vector2i(x, y)
            self.ground_points[key] = self.dummy_ground_template.instantiate() as BaseGround
            self.mouse_layer.add_child(self.ground_points[key])
            self.ground_points[key].set_position(Vector3(x * tile_size, 0, y * tile_size))


func detach() -> void:
    var parent: Node = self.mouse_layer.get_parent()
    if parent != null:
        parent.remove_child(self.mouse_layer)

func destroy() -> void:
    self.mouse_layer.free()
