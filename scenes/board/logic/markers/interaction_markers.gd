extends Node3D
class_name InteractionMarkers

@export var map: NodePath
var map_obj: Map

var attack_marker_template: PackedScene = preload("res://scenes/ui/markers/attack_marker.tscn")
var capture_marker_template: PackedScene = preload("res://scenes/ui/markers/capture_marker.tscn")

var created_markers: Dictionary[String, Node3D] = {}

func _ready() -> void:
    self.map_obj = self.get_node(self.map) as Map

func reset() -> void:
    self.destroy_markers()

func destroy_markers() -> void:
    for key: String in self.created_markers.keys():
        var marker: Node3D = self.created_markers[key]
        marker.hide()
        marker.queue_free()
    self.created_markers.clear()

func show_legal_interactions(positions: Array[Vector2i]) -> void:
    self.reset()
    for map_position: Vector2i in positions:
        var tile: MapTile = self.map_obj.model.get_tile(map_position)
        if tile == null:
            continue
        if tile.building.is_present():
            self.mark_tile_for_capture(tile)
        elif tile.unit.is_present():
            self.mark_tile_for_attack(tile)

func mark_tile_for_capture(tile: MapTile) -> void:
    self.place_marker(self.capture_marker_template.instantiate() as Node3D, tile)


func mark_tile_for_attack(tile: MapTile) -> void:
    self.place_marker(self.attack_marker_template.instantiate() as Node3D, tile)


func place_marker(new_marker: Node3D, tile: MapTile) -> void:
    self.add_child(new_marker)
    var placement: Vector3 = self.map_obj.map_to_local(tile.position)
    new_marker.set_position(placement)

    self.created_markers[str(tile.position.x) + "_" + str(tile.position.y)] = new_marker
