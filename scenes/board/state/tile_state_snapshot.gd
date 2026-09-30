class_name TileStateSnapshot
extends RefCounted


var position: Vector2i
var ground: MapObjectStateSnapshot
var frame: MapObjectStateSnapshot
var decoration: MapObjectStateSnapshot
var terrain: MapObjectStateSnapshot
var damage: MapObjectStateSnapshot
var unit: UnitStateSnapshot
var building: BuildingStateSnapshot


func _init(
	new_position: Vector2i,
	new_ground: MapObjectStateSnapshot = null,
	new_frame: MapObjectStateSnapshot = null,
	new_decoration: MapObjectStateSnapshot = null,
	new_terrain: MapObjectStateSnapshot = null,
	new_damage: MapObjectStateSnapshot = null,
	new_unit: UnitStateSnapshot = null,
	new_building: BuildingStateSnapshot = null
) -> void:
	self.position = new_position
	self.ground = new_ground
	self.frame = new_frame
	self.decoration = new_decoration
	self.terrain = new_terrain
	self.damage = new_damage
	self.unit = new_unit
	self.building = new_building
