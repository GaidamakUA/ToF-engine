extends GutTest


func test_legacy_movement_marker_colours_and_priority() -> void:
	var markers := autofree(MovementMarkers.new()) as MovementMarkers
	var unit := autofree(BaseUnit.new()) as BaseUnit
	unit.side = "blue"
	unit.team = 0
	unit.can_capture = true
	unit.move = 2
	unit.attacks = 1

	var neutral_tile := MapTile.new(0, 0)
	_add_enemy_building_neighbour(neutral_tile)
	assert_same(_colour_marker(markers, neutral_tile, unit, 2, 3), markers.colour_materials["neutral"])

	var ap_limited_tile := MapTile.new(1, 0)
	_add_enemy_building_neighbour(ap_limited_tile)
	assert_same(_colour_marker(markers, ap_limited_tile, unit, 1, 1), markers.colour_materials["green"])

	var attack_tile := MapTile.new(2, 0)
	_add_enemy_unit_neighbour(attack_tile)
	assert_same(_colour_marker(markers, attack_tile, unit, 1, 3), markers.colour_materials["red"])

	var capture_tile := MapTile.new(3, 0)
	_add_enemy_building_neighbour(capture_tile)
	assert_same(_colour_marker(markers, capture_tile, unit, 1, 3), markers.colour_materials["blue"])

	var default_tile := MapTile.new(4, 0)
	assert_same(_colour_marker(markers, default_tile, unit, 1, 3), markers.colour_materials["green"])


func _colour_marker(
	markers: MovementMarkers,
	tile: MapTile,
	unit: BaseUnit,
	cost: int,
	ap_limit: int
) -> Material:
	var marker := markers.marker_template.instantiate() as MovementMarker
	markers.add_child(marker)
	markers.created_markers[markers._get_key(tile)] = marker
	markers.mark_tile_cost(tile, cost)
	markers.colour_marker(tile, unit, ap_limit)
	return (marker.get_node("offset/mesh1") as MeshInstance3D).get_surface_override_material(0)


func _add_enemy_unit_neighbour(tile: MapTile) -> void:
	var neighbour := MapTile.new(tile.position.x, tile.position.y + 1)
	var enemy := autofree(BaseUnit.new()) as BaseUnit
	enemy.side = "red"
	enemy.team = 1
	neighbour.unit.set_tile(enemy)
	tile.add_neighbour(tile.SOUTH, neighbour)


func _add_enemy_building_neighbour(tile: MapTile) -> void:
	var neighbour := MapTile.new(tile.position.x, tile.position.y + 1)
	var enemy := autofree(BaseBuilding.new()) as BaseBuilding
	enemy.side = "red"
	enemy.team = 1
	neighbour.building.set_tile(enemy)
	tile.add_neighbour(tile.SOUTH, neighbour)
