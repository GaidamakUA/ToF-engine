class_name MapStateSnapshot
extends RefCounted


var tiles: Dictionary[Vector2i, TileStateSnapshot]


func _init(new_tiles: Dictionary[Vector2i, TileStateSnapshot]) -> void:
	self.tiles = new_tiles.duplicate()


func get_tile(position: Vector2i) -> TileStateSnapshot:
	return self.tiles.get(position)
