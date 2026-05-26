class_name AbilityMarkers
extends Node3D

@export var map: NodePath
var map_obj: Map

var marker_template: PackedScene = preload("res://scenes/ui/markers/movement_marker.tscn")
var range_template: PackedScene = preload("res://scenes/ui/markers/range_marker.tscn")
var colour_materials: Dictionary[String, Material] = {
	"blue" : preload("res://assets/materials/arne32_blue.tres"),
	"red" : preload("res://assets/materials/arne32_red.tres"),
	"green" : preload("res://assets/materials/arne32_green.tres"),
	"yellow" : preload("res://assets/materials/arne32_yellow.tres"),
	"black" : preload("res://assets/materials/arne32_black.tres"),
	"neutral" : preload("res://assets/materials/arne32_neutral.tres"),
}

var created_markers: Dictionary[String, MovementMarker] = {}
var extra_markers: Array[Node3D] = []
var tiles_in_range: Dictionary[String, MapTile] = {}
var explored_tiles_distance: Dictionary[String, int] = {}

func _ready() -> void:
	self.map_obj = self.get_node(self.map) as Map

func reset() -> void:
	self.tiles_in_range.clear()
	self.destroy_markers()

func destroy_markers() -> void:
	for key: String in self.created_markers.keys():
		var marker: MovementMarker = self.created_markers[key]
		marker.hide()
		marker.queue_free()
	self.created_markers.clear()
	for extra_marker: Node3D in self.extra_markers:
		extra_marker.hide()
		extra_marker.queue_free()
	self.extra_markers.clear()

func show_ability_markers_for_tile(ability: Ability, tile: MapTile) -> void:
	self.destroy_markers()
	if ability.TYPE == "production":
		self.show_production_markers_for_tile(tile)
	if ability.TYPE == "hero_active" or ability.TYPE == "active":
		self.show_active_markers_for_tile(tile, ability)

func show_production_markers_for_tile(tile: MapTile) -> void:
	var neighbour: MapTile
	for direction: String in tile.neighbours.keys():
		neighbour = tile.neighbours[direction]
		if neighbour.can_acommodate_unit():
			self.place_marker(neighbour.position)

func get_all_tiles_in_ability_range(ability: Ability, tile: MapTile) -> Array[MapTile]:
	self.tiles_in_range.clear()
	self.explored_tiles_distance.clear()
	self.tiles_in_range[self._get_key(tile)] = tile
	self.explored_tiles_distance[self._get_key(tile)] = 0

	self.expand_from_tile(tile, ability.ability_range, 0)

	var tiles: Array[MapTile] = []
	tiles.assign(self.tiles_in_range.values())
	return tiles

func show_active_markers_for_tile(source_tile: MapTile, ability: Ability) -> void:
	self.get_all_tiles_in_ability_range(ability, source_tile)
	self._draw_ability_range(source_tile, ability.draw_range, ability.in_line)

	if ability is ActiveUnitAbility:
		self._show_active_unit_markers(source_tile, ability)
	elif ability is ActiveHeroAbility:
		self._show_active_hero_markers(source_tile, ability)

func _show_active_unit_markers(source_tile: MapTile, ability: ActiveUnitAbility) -> void:
	for tile: MapTile in self.tiles_in_range.values():
		if ability.is_tile_applicable(tile, source_tile):
			self.place_marker(tile.position, ability.marker_colour)

func _show_active_hero_markers(source_tile: MapTile, ability: ActiveHeroAbility) -> void:
	for tile: MapTile in self.tiles_in_range.values():
		if ability.is_tile_applicable(tile, source_tile):
			self.place_marker(tile.position, ability.marker_colour)

func expand_from_tile(tile: MapTile, depth: int, distance: int) -> void:
	if depth < 1:
		return

	var key: String
	var neighbour_distance: Variant = null


	for neighbour: MapTile in tile.neighbours.values():
		key = self._get_key(neighbour)
		if self.explored_tiles_distance.has(key):
			neighbour_distance = self.explored_tiles_distance[key]

		if not self.tiles_in_range.has(key) or (neighbour_distance != null and int(neighbour_distance) > distance + 1):
			self.tiles_in_range[key] = neighbour
			self.explored_tiles_distance[key] = distance + 1
			self.expand_from_tile(neighbour, depth - 1, distance + 1)

func marker_exists(marker_position: Vector2i) -> bool:
	return self.created_markers.has(str(marker_position.x) + "_" + str(marker_position.y))

func place_marker(marker_position: Vector2i, colour: String = "green") -> void:
	var new_marker: MovementMarker = self.marker_template.instantiate() as MovementMarker
	self.add_child(new_marker)
	var placement: Vector3 = self.map_obj.map_to_local(marker_position)
	new_marker.set_position(placement)

	self.created_markers[str(marker_position.x) + "_" + str(marker_position.y)] = new_marker
	new_marker.set_material(self.colour_materials[colour])

func _get_key(tile: MapTile) -> String:
	return str(tile.position.x) + "_" + str(tile.position.y)

func _draw_ability_range(source_tile: MapTile, ability_range: int, in_line: bool) -> void:
	if ability_range < 1:
		return

	for x_index: int in range(-ability_range, ability_range + 1):
		for y_index: int in range(-ability_range, ability_range + 1):
			var x: int = source_tile.position.x + x_index
			var y: int = source_tile.position.y + y_index

			if x < 0 or x >= self.map_obj.model.SIZE or y < 0 or y >= self.map_obj.model.SIZE:
				continue

			if not in_line and abs(x_index) + abs(y_index) == ability_range:
				if x_index <= 0:
					self._place_extra_marker(Vector2i(x, y), 90)
				if x_index >= 0:
					self._place_extra_marker(Vector2i(x, y), 270)
				if y_index <= 0:
					self._place_extra_marker(Vector2i(x, y), 0)
				if y_index >= 0:
					self._place_extra_marker(Vector2i(x, y), 180)

			if in_line and (x_index == 0 or y_index == 0) and (x_index + y_index != 0):
				if x_index == 0:
					self._place_extra_marker(Vector2i(x, y), 90)
					self._place_extra_marker(Vector2i(x, y), 270)

				if y_index == 0:
					self._place_extra_marker(Vector2i(x, y), 0)
					self._place_extra_marker(Vector2i(x, y), 180)

				if y_index == -ability_range:
					self._place_extra_marker(Vector2i(x, y), 0)
				if y_index == ability_range:
					self._place_extra_marker(Vector2i(x, y), 180)
				if x_index == -ability_range:
					self._place_extra_marker(Vector2i(x, y), 90)
				if x_index == ability_range:
					self._place_extra_marker(Vector2i(x, y), 270)

func _place_extra_marker(marker_position: Vector2i, marker_rotation: int) -> void:
	var new_marker: Node3D = self.range_template.instantiate() as Node3D
	self.add_child(new_marker)
	var placement: Vector3 = self.map_obj.map_to_local(marker_position)
	new_marker.set_position(placement)
	new_marker.set_rotation(Vector3(0, deg_to_rad(marker_rotation), 0))

	self.extra_markers.append(new_marker)
