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

func show_interaction_markers_for_tile(tile: MapTile, ap_limit: int) -> void:
	self.reset()
	if not tile.unit.is_present() || ap_limit < 1:
		return

	var unit: BaseUnit = tile.unit.tile as BaseUnit
	var neighbour: MapTile
	for key: String in tile.neighbours.keys():
		neighbour = tile.get_neighbour(key)

		if self.should_place_attack_marker(neighbour, unit):
			self.mark_tile_for_attack(neighbour)

		if self.should_place_catpure_marker(neighbour, unit):
			self.mark_tile_for_capture(neighbour)

func should_place_catpure_marker(tile: MapTile, unit: BaseUnit) -> bool:
	if not tile.has_enemy_building(unit.side, unit.team):
		return false

	if unit.move < 1:
		return false

	if not unit.can_capture:
		return false

	return true

func mark_tile_for_capture(tile: MapTile) -> void:
	self.place_marker(self.capture_marker_template.instantiate() as Node3D, tile)


func should_place_attack_marker(tile: MapTile, unit: BaseUnit) -> bool:
	if not tile.has_enemy_unit(unit.side, unit.team):
		return false

	if unit.move < 1 || not unit.has_attacks():
		return false

	if not unit.can_attack(tile.unit.tile):
		return false

	return true


func mark_tile_for_attack(tile: MapTile) -> void:
	self.place_marker(self.attack_marker_template.instantiate() as Node3D, tile)


func place_marker(new_marker: Node3D, tile: MapTile) -> void:
	self.add_child(new_marker)
	var placement: Vector3 = self.map_obj.map_to_local(tile.position)
	new_marker.set_position(placement)

	self.created_markers[str(tile.position.x) + "_" + str(tile.position.y)] = new_marker
