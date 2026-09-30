class_name AbilityMarkers
extends Node3D

@export var map: NodePath
var map_obj: Map

var marker_template: PackedScene = preload("res://scenes/ui/markers/movement_marker.tscn")
var colour_materials: Dictionary[String, Material] = {
    "blue" : preload("res://assets/materials/arne32_blue.tres"),
    "red" : preload("res://assets/materials/arne32_red.tres"),
    "green" : preload("res://assets/materials/arne32_green.tres"),
    "yellow" : preload("res://assets/materials/arne32_yellow.tres"),
    "black" : preload("res://assets/materials/arne32_black.tres"),
    "neutral" : preload("res://assets/materials/arne32_neutral.tres"),
}

var created_markers: Dictionary[String, MovementMarker] = {}

func _ready() -> void:
    self.map_obj = self.get_node(self.map) as Map

func reset() -> void:
    self.destroy_markers()

func destroy_markers() -> void:
    for key: String in self.created_markers.keys():
        var marker: MovementMarker = self.created_markers[key]
        marker.hide()
        marker.queue_free()
    self.created_markers.clear()


func show_legal_targets(positions: Array[Vector2i], colour: String = "green") -> void:
    self.reset()
    for map_position: Vector2i in positions:
        self.place_marker(map_position, colour)

func place_marker(marker_position: Vector2i, colour: String = "green") -> void:
    var new_marker: MovementMarker = self.marker_template.instantiate() as MovementMarker
    self.add_child(new_marker)
    var placement: Vector3 = self.map_obj.map_to_local(marker_position)
    new_marker.set_position(placement)

    self.created_markers[str(marker_position.x) + "_" + str(marker_position.y)] = new_marker
    new_marker.set_material(self.colour_materials[colour])
