class_name UnitMovedDomainEvent
extends BoardDomainEvent


var unit_id: int
var finish: Vector2i
var path: Array[Vector2i]
var directions: Array[String]


func _init(
	new_unit_id: int,
	new_finish: Vector2i,
	new_path: Array[Vector2i],
	new_directions: Array[String] = []
) -> void:
	self.unit_id = new_unit_id
	self.finish = new_finish
	self.path = new_path.duplicate()
	self.directions = new_directions.duplicate()
