extends Node
class_name MouseLayerService

var initialized: bool = false
var mouse_layer: Node3D = Node3D.new()
var tile_hitboxes: Dictionary[String, MapTileHitbox] = {}
var tile_hitbox_template: PackedScene = preload("res://scenes/tiles/ground/map_tile_hitbox.tscn")

func initialize(size: int, tile_size: int) -> void:
    if self.initialized:
        return

    self.initialized = true
    var key: String
    for x: int in range(size):
        for y: int in range(size):
            key = str(x) + "_" + str(y)
            self.tile_hitboxes[key] = self.tile_hitbox_template.instantiate() as MapTileHitbox
            self.mouse_layer.add_child(self.tile_hitboxes[key])
            self.tile_hitboxes[key].prepare()
            self.tile_hitboxes[key].mouse_area.connect("mouse_entered", Callable(self.tile_hitboxes[key].mouse_area, "_on_mouse_area_mouse_entered"))
            self.tile_hitboxes[key].set_position(Vector3(x * tile_size, 0, y * tile_size))


func detach() -> void:
    var parent: Node = self.mouse_layer.get_parent()
    if parent != null:
        parent.remove_child(self.mouse_layer)

func destroy() -> void:
    self.mouse_layer.free()
