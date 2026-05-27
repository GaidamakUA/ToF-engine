extends Node3D
class_name PathMarkers

@export var map: NodePath
var map_obj: Map

var marker_template: PackedScene = preload("res://scenes/ui/markers/path_marker.tscn")

var created_markers: Dictionary[String, Node3D] = {}

var rotations: Dictionary[String, int] = {
    "n" : 0,
    "s" : 180,
    "w" : 90,
    "e" : 270,
}

func _ready() -> void:
    self.map_obj = self.get_node(self.map) as Map

func reset() -> void:
    self.destroy_markers()

func destroy_markers() -> void:
    for key: String in self.created_markers.keys():
        var marker: Node3D
        marker = self.created_markers[key]
        marker.hide()
        marker.queue_free()
    self.created_markers.clear()


func draw_path(path: Array[String]) -> void:
    self.reset()

    for i: int in range(path.size()):
        if i < path.size() - 1:
            self.place_marker(path[i])

    self.rotate_markers(path)


func place_marker(tile_key: String) -> void:
    var tile: MapTile = self.map_obj.model.tiles[tile_key]
    var new_marker: Node3D = self.marker_template.instantiate() as Node3D
    self.add_child(new_marker)
    var placement: Vector3 = self.map_obj.map_to_local(tile.position)
    new_marker.set_position(placement)

    self.created_markers[tile_key] = new_marker

func rotate_markers(path: Array[String]) -> void:
    for i: int in range(path.size()):
        if i < path.size() - 1:
            if i > 0:
                self.rotate_marker(self.created_markers[path[i]], path[i], path[i-1])
            elif i == 0:
                self.rotate_marker(self.created_markers[path[i]], path[i+1], path[i])

func convert_path_to_directions(path: Array[String]) -> Array[String]:
    var directions: Array[String] = []
    for i: int in range(path.size()):
        if i > 0:
            directions.append(self.get_rotation_to_tile(path[i], path[i-1]))
        elif i == 0:
            directions.append(self.get_rotation_to_tile(path[i+1], path[i]))

    directions.reverse()
    return directions

func get_rotation_to_tile(source_key: String, destination_key: String) -> String:
    var source_tile: MapTile = self.map_obj.model.tiles[source_key]
    var destination_tile: MapTile = self.map_obj.model.tiles[destination_key]
    return source_tile.get_direction_to_neighbour(destination_tile)

func rotate_marker(marker: Node3D, source_key: String, destination_key: String) -> void:
    var direction: String = self.get_rotation_to_tile(source_key, destination_key)

    marker.set_rotation(Vector3(0, deg_to_rad(self.rotations[direction]), 0))

func get_final_field_unit_direction(path: Array[String]) -> String:
    return self.get_rotation_to_tile(path[1], path[0])
