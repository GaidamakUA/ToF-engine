extends Node3D
class_name MovementMarkers

@export var map: NodePath
var map_obj: Map

var marker_template: PackedScene = preload("res://scenes/ui/markers/movement_marker.tscn")
const NEUTRAL_MATERIAL: Material = preload("res://assets/materials/arne32_neutral.tres")
const BLUE_MATERIAL: Material = preload("res://assets/materials/arne32_blue.tres")
const RED_MATERIAL: Material = preload("res://assets/materials/arne32_red.tres")
const GREEN_MATERIAL: Material = preload("res://assets/materials/arne32_green.tres")

var explored_tiles: Dictionary[String, int] = {}
var created_markers: Dictionary[String, MovementMarker] = {}
var tile_path: Dictionary[String, Variant] = {}

func _ready() -> void:
    self.map_obj = self.get_node(self.map) as Map

func reset() -> void:
    self.explored_tiles.clear()
    self.tile_path.clear()
    self.destroy_markers()

func destroy_markers() -> void:
    for key: String in self.created_markers.keys():
        var marker: MovementMarker
        marker = self.created_markers[key]
        marker.hide()
        marker.queue_free()
    self.created_markers.clear()

func show_legal_moves_for_tile(tile: MapTile, paths: Dictionary[Vector2i, Array], ap_limit: int) -> void:
    self.reset()
    if tile == null or not tile.unit.is_present():
        return
    self.add_path_root(tile)
    var unit: BaseUnit = tile.unit.tile
    for destination: Vector2i in paths:
        var destination_tile: MapTile = self.map_obj.model.get_tile(destination)
        var path: Array = paths[destination]
        self.mark_tile_cost(destination_tile, path.size() - 1)
        self.place_movement_marker(destination)
        self.colour_marker(destination_tile, unit, ap_limit)
        for index: int in range(1, path.size()):
            var source_key: String = self._get_position_key(path[index - 1])
            var destination_key: String = self._get_position_key(path[index])
            self.tile_path[destination_key] = source_key

func mark_tile_cost(tile: MapTile, cost: int) -> void:
    self.explored_tiles[self._get_key(tile)] = cost

func get_tile_cost(tile: MapTile) -> Variant:
    var key: String = self._get_key(tile)
    if self.explored_tiles.has(key):
        return self.explored_tiles[key]

    return null

func place_movement_marker(marker_position: Vector2i) -> void:
    var new_marker: MovementMarker = self.marker_template.instantiate() as MovementMarker
    self.add_child(new_marker)
    var placement: Vector3 = self.map_obj.map_to_local(marker_position)
    new_marker.set_position(placement)

    self.created_markers[str(marker_position.x) + "_" + str(marker_position.y)] = new_marker

func colour_marker(tile: MapTile, unit: BaseUnit, ap_limit: int) -> void:
    var marker: MovementMarker = self.created_markers[self._get_key(tile)]
    var tile_cost: Variant = self.get_tile_cost(tile)
    var material: Material = self.GREEN_MATERIAL
    if tile_cost == unit.move:
        material = self.NEUTRAL_MATERIAL
    elif tile_cost != ap_limit:
        if tile.neighbours_enemy_unit(unit.side, unit.team) \
            and tile.can_attack_neightbour_enemy_unit(unit) and unit.has_attacks():
            material = self.RED_MATERIAL
        elif unit.can_capture and tile.neighbours_enemy_building(unit.side, unit.team):
            material = self.BLUE_MATERIAL
    marker.set_material(material)

func add_path_root(root_tile: MapTile) -> void:
    self.tile_path[self._get_key(root_tile)] = null

func _get_key(tile: MapTile) -> String:
    return str(tile.position.x) + "_" + str(tile.position.y)


func _get_position_key(map_position: Vector2i) -> String:
    return str(map_position.x) + "_" + str(map_position.y)

func get_path_to_tile(destination_tile: MapTile) -> Array[String]:
    var path: Array[String] = []
    var key: Variant = self._get_key(destination_tile)

    while key != null:
        path.append(String(key))
        key = self.tile_path[String(key)]

    return path
